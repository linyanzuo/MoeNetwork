//
//  Request.swift
//
//  Copyright (c) 2014 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// 该类型能在需要时检查`URLRequest`并使其适应某些规矩
/// 使用场景举例： 请求发起前检查到“没有携带token数据”（不满足规矩）时，自动添加token数据（使其适应规矩），再发起请求
public protocol RequestAdapter {
    /// 检查`URLRequest`并使其适应某些规矩，最终返回处理的结果
    ///
    /// - parameter urlRequest: 要改编的请求
    /// - throws: 如果适应时出错，则抛出`Error`
    /// - returns: 改编后的已适应`URLRequest`
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest
}

// MARK: -

/// `Request`是否应该重试做出决择后，`RequestRetrier`执行该闭包
public typealias RequestRetryCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval) -> Void

/// 该类型在指定的`sessionManager`执行请求并遭遇错误后，判断是否重试请求。
/// 使用场景举例： token过期导致的请求失败时，自动执行token更新，并重新发起请求
public protocol RequestRetrier {
    /// 通过调用`completion`闭包，决定`Request`是否要重试
    ///
    /// 该操作完全异步执行. 消耗多少时间来判断请求是否要重试都可行，
    /// The one requirement is that the completion closure is called to ensure the request is properly
    /// cleaned up after.
    ///
    /// - parameter manager:    执行请求的`sessionManager`
    /// - parameter request:    遭遇错误而导致失败的请求
    /// - parameter error:      执行请求时遭遇的错误
    /// - parameter completion: 当是否重试做出决择后，将被执行的`completion`闭包
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion)
}

// MARK: -

/// 该类型负责将`URLSession`转换成相应的`URLSessionTask`
protocol TaskConvertible {
    /// 根据提供的会话、适配器、调度队列，生成匹配的任务
    /// - Parameter session: 用来执行任务的会话
    /// - Parameter adapter: 对URL进行适配操作的适配器
    /// - Parameter queue: 执行创建任务操作的队列
    func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask
}

/// 保存消息头的字典，应用到`URLRequest`上
public typealias HTTPHeaders = [String: String]

// MARK: -

/// 负责发送请求并接收来自服务端的响应和关联数据，也负责管理底层的`URLSessionTask`
open class Request {

    // MARK: Helper Types

    /// 监听请求的上传或下载进度时执行的闭包
    public typealias ProgressHandler = (Progress) -> Void

    /// 请求的任务类型，归纳为`数据请求`、`下载请求`、`上传请求`、`数据流请求`
    /// 使用每种类型时， 都需要携带`TaskConvertible`和`URLSessionTask`类型的两个参数
    enum RequestTask {
        case data(TaskConvertible?, URLSessionTask?)
        case download(TaskConvertible?, URLSessionTask?)
        case upload(TaskConvertible?, URLSessionTask?)
        case stream(TaskConvertible?, URLSessionTask?)
    }

    // MARK: Properties

    /// 底层`task`的代理，使用`taskDelegateLock`进行多线程互斥保护
    open internal(set) var delegate: TaskDelegate {
        get {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            return taskDelegate
        }
        set {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            taskDelegate = newValue
        }
    }

    /// 底层`task`
    open var task: URLSessionTask? { return delegate.task }

    /// 底层`task`所归属的`session`（session执行task）
    public let session: URLSession

    /// 发送或即将发送到服务器的请求， 返回`task`创建时的请求
    open var request: URLRequest? { return task?.originalRequest }

    /// 从服务器接收回来的响应（如果存在）
    open var response: HTTPURLResponse? { return task?.response as? HTTPURLResponse }

    /// 请求尝试(失败)重试的次数
    open internal(set) var retryCount: UInt = 0

    let originalTask: TaskConvertible?

    /// 请求开始时间
    var startTime: CFAbsoluteTime?
    /// 请求结束时间
    var endTime: CFAbsoluteTime?

    var validations: [() -> Void] = []

    /// 底层`task`的回调代码
    private var taskDelegate: TaskDelegate
    private var taskDelegateLock = NSLock()

    // MARK: Lifecycle

    /// 初始化请求，根据不同类型的`task`，采用相应的`delegate`进行处理
    /// 向代理(`TaskDelegate`)的队列添加操作
    init(session: URLSession, requestTask: RequestTask, error: Error? = nil) {
        self.session = session

        switch requestTask {
        case .data(let originalTask, let task):
            taskDelegate = DataTaskDelegate(task: task)
            self.originalTask = originalTask
        case .download(let originalTask, let task):
            taskDelegate = DownloadTaskDelegate(task: task)
            self.originalTask = originalTask
        case .upload(let originalTask, let task):
            taskDelegate = UploadTaskDelegate(task: task)
            self.originalTask = originalTask
        case .stream(let originalTask, let task):
            taskDelegate = TaskDelegate(task: task)
            self.originalTask = originalTask
        }
        
        delegate.error = error
        delegate.queue.addOperation { self.endTime = CFAbsoluteTimeGetCurrent() }
    }

    // MARK: Authentication

    /// Associates an HTTP Basic credential with the request.
    ///
    /// - parameter user:        The user.
    /// - parameter password:    The password.
    /// - parameter persistence: The URL credential persistence. `.ForSession` by default.
    ///
    /// - returns: The request.
    @discardableResult
    open func authenticate(
        user: String,
        password: String,
        persistence: URLCredential.Persistence = .forSession)
        -> Self
    {
        let credential = URLCredential(user: user, password: password, persistence: persistence)
        return authenticate(usingCredential: credential)
    }

    /// Associates a specified credential with the request.
    ///
    /// - parameter credential: The credential.
    ///
    /// - returns: The request.
    @discardableResult
    open func authenticate(usingCredential credential: URLCredential) -> Self {
        delegate.credential = credential
        return self
    }

    /// Returns a base64 encoded basic authentication credential as an authorization header tuple.
    ///
    /// - parameter user:     The user.
    /// - parameter password: The password.
    ///
    /// - returns: A tuple with Authorization header and credential value if encoding succeeds, `nil` otherwise.
    open class func authorizationHeader(user: String, password: String) -> (key: String, value: String)? {
        guard let data = "\(user):\(password)".data(using: .utf8) else { return nil }

        let credential = data.base64EncodedString(options: [])

        return (key: "Authorization", value: "Basic \(credential)")
    }

    // MARK: State

    /// 恢复请求
    open func resume() {
        guard let task = task else { delegate.queue.isSuspended = false ; return }

        if startTime == nil { startTime = CFAbsoluteTimeGetCurrent() }

        task.resume()

        NotificationCenter.default.post(
            name: Notification.Name.Task.DidResume,
            object: self,
            userInfo: [Notification.Key.Task: task]
        )
    }

    /// 中断请求
    open func suspend() {
        guard let task = task else { return }

        task.suspend()

        NotificationCenter.default.post(
            name: Notification.Name.Task.DidSuspend,
            object: self,
            userInfo: [Notification.Key.Task: task]
        )
    }

    /// 取消请求
    open func cancel() {
        guard let task = task else { return }

        task.cancel()

        NotificationCenter.default.post(
            name: Notification.Name.Task.DidCancel,
            object: self,
            userInfo: [Notification.Key.Task: task]
        )
    }
}

// MARK: - CustomStringConvertible

extension Request: CustomStringConvertible {
    /// `Reqeust`写入输出流时的文本表示形式，包含了请求方法、请求地址，如果接收了接收响应也包含响应状态码
    open var description: String {
        var components: [String] = []

        if let HTTPMethod = request?.httpMethod {
            components.append(HTTPMethod)
        }

        if let urlString = request?.url?.absoluteString {
            components.append(urlString)
        }

        if let response = response {
            components.append("(\(response.statusCode))")
        }

        return components.joined(separator: " ")
    }
}

// MARK: - CustomDebugStringConvertible

extension Request: CustomDebugStringConvertible {
    /// The textual representation used when written to an output stream, in the form of a cURL command.
    open var debugDescription: String {
        return cURLRepresentation()
    }

    func cURLRepresentation() -> String {
        var components = ["$ curl -v"]

        guard let request = self.request,
              let url = request.url,
              let host = url.host
        else {
            return "$ curl command could not be created"
        }

        if let httpMethod = request.httpMethod, httpMethod != "GET" {
            components.append("-X \(httpMethod)")
        }

        if let credentialStorage = self.session.configuration.urlCredentialStorage {
            let protectionSpace = URLProtectionSpace(
                host: host,
                port: url.port ?? 0,
                protocol: url.scheme,
                realm: host,
                authenticationMethod: NSURLAuthenticationMethodHTTPBasic
            )

            if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
                for credential in credentials {
                    guard let user = credential.user, let password = credential.password else { continue }
                    components.append("-u \(user):\(password)")
                }
            } else {
                if let credential = delegate.credential, let user = credential.user, let password = credential.password {
                    components.append("-u \(user):\(password)")
                }
            }
        }

        if session.configuration.httpShouldSetCookies {
            if
                let cookieStorage = session.configuration.httpCookieStorage,
                let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty
            {
                let string = cookies.reduce("") { $0 + "\($1.name)=\($1.value);" }

            #if swift(>=3.2)
                components.append("-b \"\(string[..<string.index(before: string.endIndex)])\"")
            #else
                components.append("-b \"\(string.substring(to: string.characters.index(before: string.endIndex)))\"")
            #endif
            }
        }

        var headers: [AnyHashable: Any] = [:]

        session.configuration.httpAdditionalHeaders?.filter {  $0.0 != AnyHashable("Cookie") }
                                                    .forEach { headers[$0.0] = $0.1 }

        request.allHTTPHeaderFields?.filter { $0.0 != "Cookie" }
                                    .forEach { headers[$0.0] = $0.1 }

        components += headers.map {
            let escapedValue = String(describing: $0.value).replacingOccurrences(of: "\"", with: "\\\"")

            return "-H \"\($0.key): \(escapedValue)\""
        }

        if let httpBodyData = request.httpBody, let httpBody = String(data: httpBodyData, encoding: .utf8) {
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

            components.append("-d \"\(escapedBody)\"")
        }

        components.append("\"\(url.absoluteString)\"")

        return components.joined(separator: " \\\n\t")
    }
}

// MARK: -

/// 用于管理底层为`URLSessionDataTask`的特殊`Request`类型
open class DataRequest: Request {

    /// 辅助用内部类型，负责将`URLRequest`转换成`URLSessionDataTask`
    struct Requestable: TaskConvertible {
        /// url请求
        let urlRequest: URLRequest

        /// 使用指定适配器进行URL适配，并返回检索该URL对应内容的任务
        /// - Parameter session: 用来执行任务的会话
        /// - Parameter adapter: 对URL进行适配操作的适配器
        /// - Parameter queue: 执行创建任务操作的队列
        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            do {
                // 获取适配操作后的`URLRequest`
                let urlRequest = try self.urlRequest.adapt(using: adapter)
                // 创建检索指定URL内容的`task`
                return queue.sync { session.dataTask(with: urlRequest) }
            } catch {
                throw AdaptError(error: error)
            }
        }
    }

    // MARK: Properties

    /// 返回`dataTask`的`urlRequest`
    open override var request: URLRequest? {
        if let request = super.request { return request }
        if let requestable = originalTask as? Requestable { return requestable.urlRequest }

        return nil
    }

    /// The progress of fetching the response data from the server for the request.
    open var progress: Progress { return dataDelegate.progress }

    var dataDelegate: DataTaskDelegate { return delegate as! DataTaskDelegate }

    // MARK: Stream

    /// Sets a closure to be called periodically during the lifecycle of the request as data is read from the server.
    ///
    /// This closure returns the bytes most recently received from the server, not including data from previous calls.
    /// If this closure is set, data will only be available within this closure, and will not be saved elsewhere. It is
    /// also important to note that the server data in any `Response` object will be `nil`.
    ///
    /// - parameter closure: The code to be executed periodically during the lifecycle of the request.
    ///
    /// - returns: The request.
    @discardableResult
    open func stream(closure: ((Data) -> Void)? = nil) -> Self {
        dataDelegate.dataStream = closure
        return self
    }

    // MARK: Progress

    /// Sets a closure to be called periodically during the lifecycle of the `Request` as data is read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is read from the server.
    ///
    /// - returns: The request.
    @discardableResult
    open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        dataDelegate.progressHandler = (closure, queue)
        return self
    }
}

// MARK: -

/// Specific type of `Request` that manages an underlying `URLSessionDownloadTask`.
open class DownloadRequest: Request {

    // MARK: Helper Types

    /// A collection of options to be executed prior to moving a downloaded file from the temporary URL to the
    /// destination URL.
    public struct DownloadOptions: OptionSet {
        /// Returns the raw bitmask value of the option and satisfies the `RawRepresentable` protocol.
        public let rawValue: UInt

        /// A `DownloadOptions` flag that creates intermediate directories for the destination URL if specified.
        public static let createIntermediateDirectories = DownloadOptions(rawValue: 1 << 0)

        /// A `DownloadOptions` flag that removes a previous file from the destination URL if specified.
        public static let removePreviousFile = DownloadOptions(rawValue: 1 << 1)

        /// Creates a `DownloadFileDestinationOptions` instance with the specified raw value.
        ///
        /// - parameter rawValue: The raw bitmask value for the option.
        ///
        /// - returns: A new log level instance.
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }

    /// A closure executed once a download request has successfully completed in order to determine where to move the
    /// temporary file written to during the download process. The closure takes two arguments: the temporary file URL
    /// and the URL response, and returns a two arguments: the file URL where the temporary file should be moved and
    /// the options defining how the file should be moved.
    public typealias DownloadFileDestination = (
        _ temporaryURL: URL,
        _ response: HTTPURLResponse)
        -> (destinationURL: URL, options: DownloadOptions)

    enum Downloadable: TaskConvertible {
        case request(URLRequest)
        case resumeData(Data)

        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            do {
                let task: URLSessionTask

                switch self {
                case let .request(urlRequest):
                    let urlRequest = try urlRequest.adapt(using: adapter)
                    task = queue.sync { session.downloadTask(with: urlRequest) }
                case let .resumeData(resumeData):
                    task = queue.sync { session.downloadTask(withResumeData: resumeData) }
                }

                return task
            } catch {
                throw AdaptError(error: error)
            }
        }
    }

    // MARK: Properties

    /// The request sent or to be sent to the server.
    open override var request: URLRequest? {
        if let request = super.request { return request }

        if let downloadable = originalTask as? Downloadable, case let .request(urlRequest) = downloadable {
            return urlRequest
        }

        return nil
    }

    /// The resume data of the underlying download task if available after a failure.
    open var resumeData: Data? { return downloadDelegate.resumeData }

    /// The progress of downloading the response data from the server for the request.
    open var progress: Progress { return downloadDelegate.progress }

    var downloadDelegate: DownloadTaskDelegate { return delegate as! DownloadTaskDelegate }

    // MARK: State

    /// Cancels the request.
    open override func cancel() {
        downloadDelegate.downloadTask.cancel { self.downloadDelegate.resumeData = $0 }

        NotificationCenter.default.post(
            name: Notification.Name.Task.DidCancel,
            object: self,
            userInfo: [Notification.Key.Task: task as Any]
        )
    }

    // MARK: Progress

    /// Sets a closure to be called periodically during the lifecycle of the `Request` as data is read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is read from the server.
    ///
    /// - returns: The request.
    @discardableResult
    open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        downloadDelegate.progressHandler = (closure, queue)
        return self
    }

    // MARK: Destination

    /// Creates a download file destination closure which uses the default file manager to move the temporary file to a
    /// file URL in the first available directory with the specified search path directory and search path domain mask.
    ///
    /// - parameter directory: The search path directory. `.DocumentDirectory` by default.
    /// - parameter domain:    The search path domain mask. `.UserDomainMask` by default.
    ///
    /// - returns: A download file destination closure.
    open class func suggestedDownloadDestination(
        for directory: FileManager.SearchPathDirectory = .documentDirectory,
        in domain: FileManager.SearchPathDomainMask = .userDomainMask)
        -> DownloadFileDestination
    {
        return { temporaryURL, response in
            let directoryURLs = FileManager.default.urls(for: directory, in: domain)

            if !directoryURLs.isEmpty {
                return (directoryURLs[0].appendingPathComponent(response.suggestedFilename!), [])
            }

            return (temporaryURL, [])
        }
    }
}

// MARK: -

/// Specific type of `Request` that manages an underlying `URLSessionUploadTask`.
open class UploadRequest: DataRequest {

    // MARK: Helper Types

    enum Uploadable: TaskConvertible {
        case data(Data, URLRequest)
        case file(URL, URLRequest)
        case stream(InputStream, URLRequest)

        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            do {
                let task: URLSessionTask

                switch self {
                case let .data(data, urlRequest):
                    let urlRequest = try urlRequest.adapt(using: adapter)
                    task = queue.sync { session.uploadTask(with: urlRequest, from: data) }
                case let .file(url, urlRequest):
                    let urlRequest = try urlRequest.adapt(using: adapter)
                    task = queue.sync { session.uploadTask(with: urlRequest, fromFile: url) }
                case let .stream(_, urlRequest):
                    let urlRequest = try urlRequest.adapt(using: adapter)
                    task = queue.sync { session.uploadTask(withStreamedRequest: urlRequest) }
                }

                return task
            } catch {
                throw AdaptError(error: error)
            }
        }
    }

    // MARK: Properties

    /// The request sent or to be sent to the server.
    open override var request: URLRequest? {
        if let request = super.request { return request }

        guard let uploadable = originalTask as? Uploadable else { return nil }

        switch uploadable {
        case .data(_, let urlRequest), .file(_, let urlRequest), .stream(_, let urlRequest):
            return urlRequest
        }
    }

    /// The progress of uploading the payload to the server for the upload request.
    open var uploadProgress: Progress { return uploadDelegate.uploadProgress }

    var uploadDelegate: UploadTaskDelegate { return delegate as! UploadTaskDelegate }

    // MARK: Upload Progress

    /// Sets a closure to be called periodically during the lifecycle of the `UploadRequest` as data is sent to
    /// the server.
    ///
    /// After the data is sent to the server, the `progress(queue:closure:)` APIs can be used to monitor the progress
    /// of data being read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is sent to the server.
    ///
    /// - returns: The request.
    @discardableResult
    open func uploadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        uploadDelegate.uploadProgressHandler = (closure, queue)
        return self
    }
}

// MARK: -

#if !os(watchOS)

/// Specific type of `Request` that manages an underlying `URLSessionStreamTask`.
@available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
open class StreamRequest: Request {
    enum Streamable: TaskConvertible {
        case stream(hostName: String, port: Int)
        case netService(NetService)

        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            let task: URLSessionTask

            switch self {
            case let .stream(hostName, port):
                task = queue.sync { session.streamTask(withHostName: hostName, port: port) }
            case let .netService(netService):
                task = queue.sync { session.streamTask(with: netService) }
            }

            return task
        }
    }
}

#endif

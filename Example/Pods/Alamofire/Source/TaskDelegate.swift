//
//  TaskDelegate.swift
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

/// `TaskDelegate`负责处理所有底层`task`的代理回调，在`task`完成后执行隶属于串行操作队列(`queue`)的所有操作
open class TaskDelegate: NSObject {

    // MARK: Properties

    /// 在`task`完成后，用来执行所有操作的串行操作队列
    public let queue: OperationQueue

    /// 服务端返回的数据
    public var data: Data? { return nil }

    /// 在`task`整个生命周期中生成的错误
    public var error: Error?

    /// 要处理的`task`实例，由`taskLock`进行多线程互斥保护
    var task: URLSessionTask? {
        set {
            taskLock.lock(); defer { taskLock.unlock() }
            _task = newValue
        }
        get {
            taskLock.lock(); defer { taskLock.unlock() }
            return _task
        }
    }

    var initialResponseTime: CFAbsoluteTime?
    var credential: URLCredential?
    var metrics: AnyObject? // URLSessionTaskMetrics

    private var _task: URLSessionTask? {
        didSet { reset() }
    }

    /// 多线程的同步锁，保护`task`
    private let taskLock = NSLock()

    // MARK: Lifecycle

    init(task: URLSessionTask?) {
        _task = task

        // 创建队列，最大任务并发数为1、手动执行任务、处理耗时任务
        self.queue = {
            let operationQueue = OperationQueue()

            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.isSuspended = true
            operationQueue.qualityOfService = .utility

            return operationQueue
        }()
    }

    func reset() {
        error = nil
        initialResponseTime = nil
    }

    // MARK: URLSessionTaskDelegate

    var taskWillPerformHTTPRedirection: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest) -> URLRequest?)?
    var taskDidReceiveChallenge: ((URLSession, URLSessionTask, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    var taskNeedNewBodyStream: ((URLSession, URLSessionTask) -> InputStream?)?
    var taskDidCompleteWithError: ((URLSession, URLSessionTask, Error?) -> Void)?

    
    /// 告知代理，远程服务器请求进行HTTP重定向
    /// - Parameter session: 包含任务的会话
    /// - Parameter task: 请求结果要求重定向的任务
    /// - Parameter response: 包含服务器响应的对象
    /// - Parameter request: 填写了(重定向)新位置的URL请求对象
    /// - Parameter completionHandler: 要执行的闭包，传递请求参数值修改后的URL请求对象，或传递`NULL`拒绝重定向并直接返回响应的`body`
    @objc(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void)
    {
        /**
         只有`task`处于默认或短暂`session`时该方法才会执行
         处于后台`session`的`task`会自动跟随重定向
         */
        
        var redirectRequest: URLRequest? = request

        if let taskWillPerformHTTPRedirection = taskWillPerformHTTPRedirection {
            redirectRequest = taskWillPerformHTTPRedirection(session, task, response, request)
        }

        completionHandler(redirectRequest)
    }
    
    /// 向代理索要证书，以响应来自远程服务器的鉴权要求
    /// - Parameter session: 包含任务的会话
    /// - Parameter task: 要求鉴权的请求所属的任务
    /// - Parameter challenge: 包含了鉴权要求的对象
    /// - Parameter completionHandler: 要执行的闭包，其参数为`disposition`或`credential`
    @objc(URLSession:task:didReceiveChallenge:completionHandler:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?

        if let taskDidReceiveChallenge = taskDidReceiveChallenge {
            (disposition, credential) = taskDidReceiveChallenge(session, task, challenge)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let host = challenge.protectionSpace.host

            if
                let serverTrustPolicy = session.serverTrustPolicyManager?.serverTrustPolicy(forHost: host),
                let serverTrust = challenge.protectionSpace.serverTrust
            {
                if serverTrustPolicy.evaluate(serverTrust, forHost: host) {
                    disposition = .useCredential
                    credential = URLCredential(trust: serverTrust)
                } else {
                    disposition = .cancelAuthenticationChallenge
                }
            }
        } else {
            if challenge.previousFailureCount > 0 {
                disposition = .rejectProtectionSpace
            } else {
                credential = self.credential ?? session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)

                if credential != nil {
                    disposition = .useCredential
                }
            }
        }

        completionHandler(disposition, credential)
    }
    
    /// 当任务请求新的请求主体流(request body stream)向远程服务器发送数据时，告知代理
    /// - Parameter session: 包含任务的会话
    /// - Parameter task: 需要新的主体流(body stream)
    /// - Parameter completionHandler: 执行该闭包，传递新的主体流
    @objc(URLSession:task:needNewBodyStream:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        needNewBodyStream completionHandler: @escaping (InputStream?) -> Void)
    {
        /**
         `task`只在两种情况下调用该代理方法：
         1. 为`uploadTask(withStreamedRequest:)`创建的任务提供初始的请求主体流
         2. 任务已拥有主体流，因身份验证或其它可恢复的服务器错误导致需要重新发送请求时，为任务提供替代的请求主体流
         
         注意： 如果使用文件`url`或`data`对象来提供请求主体(`request body`), 则没必要实现该方法
         */
        
        var bodyStream: InputStream?

        if let taskNeedNewBodyStream = taskNeedNewBodyStream {
            bodyStream = taskNeedNewBodyStream(session, task)
        }

        completionHandler(bodyStream)
    }
    
    /// 告知代理，任务已经完成数据传输
    /// - Parameter session: 包含任务的会话
    /// - Parameter task: 已完成请求的数据传输的任务
    /// - Parameter error: 如果发生错误，`error`对象描述了传输为何失败。否则为`null`
    @objc(URLSession:task:didCompleteWithError:)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        /**
         服务器相关的错误不会通过`error`参数进行汇报。
         代理方法的`error`参数只能接收到客户端的错误，比如无法处理主机名、无法连接主机等
         */
        if let taskDidCompleteWithError = taskDidCompleteWithError {
            taskDidCompleteWithError(session, task, error)
        } else {
            if let error = error {
                if self.error == nil { self.error = error }

                if
                    let downloadDelegate = self as? DownloadTaskDelegate,
                    let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
                {
                    downloadDelegate.resumeData = resumeData
                }
            }

            queue.isSuspended = false
        }
    }
}

// MARK: -

/// 专门负责处理底层为`dataTask`的代理回调，在任务完成后执行队列的所有操作
class DataTaskDelegate: TaskDelegate, URLSessionDataDelegate {

    // MARK: Properties

    /// 要处理的`dataTask`实例
    var dataTask: URLSessionDataTask { return task as! URLSessionDataTask }

    override var data: Data? {
        if dataStream != nil {
            return nil
        } else {
            return mutableData
        }
    }

    var progress: Progress
    var progressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?

    var dataStream: ((_ data: Data) -> Void)?

    private var totalBytesReceived: Int64 = 0
    private var mutableData: Data

    private var expectedContentLength: Int64?

    // MARK: Lifecycle

    
    /// 初始化任务代理实例，负责指定任务的回调处理
    /// - Parameter task: 要处理回调的任务
    override init(task: URLSessionTask?) {
        mutableData = Data()
        progress = Progress(totalUnitCount: 0)

        super.init(task: task)
    }

    /// 重置状态，包括进度、接收的数据等
    override func reset() {
        super.reset()

        progress = Progress(totalUnitCount: 0)
        totalBytesReceived = 0
        mutableData = Data()
        expectedContentLength = nil
    }

    // MARK: URLSessionDataDelegate

    var dataTaskDidReceiveResponse: ((URLSession, URLSessionDataTask, URLResponse) -> URLSession.ResponseDisposition)?
    var dataTaskDidBecomeDownloadTask: ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)?
    var dataTaskDidReceiveData: ((URLSession, URLSessionDataTask, Data) -> Void)?
    var dataTaskWillCacheResponse: ((URLSession, URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)?

    
    /// 数据任务接收到来自服务器的初步响应，即消息头(header)
    /// - Parameter session: 包含数据任务的会话
    /// - Parameter dataTask: 接收初步响应的数据任务
    /// - Parameter response: 填充了消息头的URL响应对象
    /// - Parameter completionHandler: 执行该闭包以完成转接，传递不同值决定继续作为数据数据执行、还是转换成下载任务
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        /**
         当首次接收到响应头，需要取消转接、或将数据任务转换成下载任务时才实现该方法
         如果不实现本方法，`session`默认会让任务继续执行
         
         每次执行至`urlSession(_:dataTask:didReceive:completionHandler:)`被调用这一步时：
         1. 根据应用需求收集上次接收的数据并处理。包括将数据存储到文件系统、解析为自定义类型、展示给用户等。
         2. 调用`completionHandler`传递`URLSession.ResponseDisposition.allow`, 开始下一步的接收。
         3. 实现`urlSession(_:task:didCompleteWithError:)`。在会话发送完最后部分的所有数据后会调用该方法
         */
        
        // ResponseDisposition: 决定了数据会话在接收到消息头后，接下来将如何继续处理
        // .allow: 允许加载操作继续执行
        var disposition: URLSession.ResponseDisposition = .allow
        // 响应内容的长度
        expectedContentLength = response.expectedContentLength

        if let dataTaskDidReceiveResponse = dataTaskDidReceiveResponse {
            disposition = dataTaskDidReceiveResponse(session, dataTask, response)
        }

        // 调用completionHandler，告知接下来是继续作为数据任务执行，还是转换成下载任务
        completionHandler(disposition)
    }

    
    /// 告知代理，数据任务已转换为下载任务
    /// - Parameter session: 包含数据任务的会话
    /// - Parameter dataTask: 要被下载任务替换的数据任务
    /// - Parameter downloadTask: 新的下载任务
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didBecome downloadTask: URLSessionDownloadTask)
    {
        /**
         当`urlSession(_:dataTask:didReceive:completionHandler:)`代理方法的处理结果转换成
         下载任务(URLSession.ResponseDisposition.becomeDownload )时，会话调用本代理方法向你提供新的下载任务
         在本代理方法执行后，`sessionDelegate`将不会再接收到原始数据任务相关的进一步的代理方法
         */
        dataTaskDidBecomeDownloadTask?(session, dataTask, downloadTask)
    }

    /// 数据任务接收到部分期望的数据
    /// - Parameter session: 包含了提供数据的数据任务的会话
    /// - Parameter dataTask: 提供数据的数据任务
    /// - Parameter data: 包含转换后数据的`data`对象
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        /**
         通常`data`参数值都是由一些不同的数据对象拼凑起来，尽可能使用`enumerateBytes(:)`方法来迭代获取数据，
         而不是使用`bytes`方法(将数据对象压入到一个内存块)
         该方法可能被调用多次，且每次仅提供自上次调之后的数据。有需要时应用要负责数据的拼接
         */
    
        // 记录请求开始时间
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }

        if let dataTaskDidReceiveData = dataTaskDidReceiveData {
            dataTaskDidReceiveData(session, dataTask, data)
        } else {
            if let dataStream = dataStream {
                dataStream(data)
            } else {
                mutableData.append(data)
            }

            let bytesReceived = Int64(data.count)
            totalBytesReceived += bytesReceived
            let totalBytesExpected = dataTask.response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown

            progress.totalUnitCount = totalBytesExpected
            progress.completedUnitCount = totalBytesReceived

            if let progressHandler = progressHandler {
                progressHandler.queue.async { progressHandler.closure(self.progress) }
            }
        }
    }
    
    /// 询问代理，数据任务(或上传任务)是否将响应存储至缓存
    /// - Parameter session: 包含数据任务(或上传任务)的会话
    /// - Parameter dataTask: 要处理的数据任务
    /// - Parameter proposedResponse: 默认的缓存行为，该行为基于当前缓存策略(poli)和接收到具体消息头，如`Cache-Control`
    /// - Parameter completionHandler: 必须调用的此闭包，否则造成内存泄漏。
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        willCacheResponse proposedResponse: CachedURLResponse,
        completionHandler: @escaping (CachedURLResponse?) -> Void)
    {
        /**
         `session`在`task`完成所有期望数据的接收后调用本代理方法。
         如果没有实现本方法，默认行为是使用`session.configuration`对象指定的缓存策略
         该方法的主要目的是阻止某些特殊URL的缓存，或修改URL响应关联的`userInfo`字典
         
         只有`URLProtocol`在处理请求时选择了缓存响应，才会调用此方法。
         只有满足下列规则时，才会缓存响应：
         1. URL地址为HTTP或HTTPS的请求 （或支持缓存的自定义网络协议）
         2. 请求成功（状态码介于200~299的范围）
         3. 提供的响应来自于服务器，而不是出自缓存
         4. `sessoin.configuration`的缓存策略允许进行缓存
         5. 服务器返回缓存中，缓存相关的消息头(如果出现)是允许缓存的
         6. 响应的大小要小于缓存的合理范围（如：磁盘缓存时，响应必须小于缓存磁盘空间的5%）
         */
        
        var cachedResponse: CachedURLResponse? = proposedResponse

        if let dataTaskWillCacheResponse = dataTaskWillCacheResponse {
            cachedResponse = dataTaskWillCacheResponse(session, dataTask, proposedResponse)
        }

        completionHandler(cachedResponse)
    }
}

// MARK: -

class DownloadTaskDelegate: TaskDelegate, URLSessionDownloadDelegate {

    // MARK: Properties

    var downloadTask: URLSessionDownloadTask { return task as! URLSessionDownloadTask }

    var progress: Progress
    var progressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?

    var resumeData: Data?
    override var data: Data? { return resumeData }

    var destination: DownloadRequest.DownloadFileDestination?

    var temporaryURL: URL?
    var destinationURL: URL?

    var fileURL: URL? { return destination != nil ? destinationURL : temporaryURL }

    // MARK: Lifecycle

    override init(task: URLSessionTask?) {
        progress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }

    override func reset() {
        super.reset()

        progress = Progress(totalUnitCount: 0)
        resumeData = nil
    }

    // MARK: URLSessionDownloadDelegate

    var downloadTaskDidFinishDownloadingToURL: ((URLSession, URLSessionDownloadTask, URL) -> URL)?
    var downloadTaskDidWriteData: ((URLSession, URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?
    var downloadTaskDidResumeAtOffset: ((URLSession, URLSessionDownloadTask, Int64, Int64) -> Void)?

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL)
    {
        temporaryURL = location

        guard
            let destination = destination,
            let response = downloadTask.response as? HTTPURLResponse
        else { return }

        let result = destination(location, response)
        let destinationURL = result.destinationURL
        let options = result.options

        self.destinationURL = destinationURL

        do {
            if options.contains(.removePreviousFile), FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            if options.contains(.createIntermediateDirectories) {
                let directory = destinationURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            try FileManager.default.moveItem(at: location, to: destinationURL)
        } catch {
            self.error = error
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64)
    {
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }

        if let downloadTaskDidWriteData = downloadTaskDidWriteData {
            downloadTaskDidWriteData(
                session,
                downloadTask,
                bytesWritten,
                totalBytesWritten,
                totalBytesExpectedToWrite
            )
        } else {
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten

            if let progressHandler = progressHandler {
                progressHandler.queue.async { progressHandler.closure(self.progress) }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didResumeAtOffset fileOffset: Int64,
        expectedTotalBytes: Int64)
    {
        if let downloadTaskDidResumeAtOffset = downloadTaskDidResumeAtOffset {
            downloadTaskDidResumeAtOffset(session, downloadTask, fileOffset, expectedTotalBytes)
        } else {
            progress.totalUnitCount = expectedTotalBytes
            progress.completedUnitCount = fileOffset
        }
    }
}

// MARK: -

class UploadTaskDelegate: DataTaskDelegate {

    // MARK: Properties

    var uploadTask: URLSessionUploadTask { return task as! URLSessionUploadTask }

    var uploadProgress: Progress
    var uploadProgressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?

    // MARK: Lifecycle

    override init(task: URLSessionTask?) {
        uploadProgress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }

    override func reset() {
        super.reset()
        uploadProgress = Progress(totalUnitCount: 0)
    }

    // MARK: URLSessionTaskDelegate

    var taskDidSendBodyData: ((URLSession, URLSessionTask, Int64, Int64, Int64) -> Void)?

    func URLSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64)
    {
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }

        if let taskDidSendBodyData = taskDidSendBodyData {
            taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
        } else {
            uploadProgress.totalUnitCount = totalBytesExpectedToSend
            uploadProgress.completedUnitCount = totalBytesSent

            if let uploadProgressHandler = uploadProgressHandler {
                uploadProgressHandler.queue.async { uploadProgressHandler.closure(self.uploadProgress) }
            }
        }
    }
}

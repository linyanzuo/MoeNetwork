//
//  Alamofire.swift
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

/// 适配了`URLConvertible`协议的类型可用于构造`URL`
///
/// 构造URL的三种类型：`String`、`URL`、`URLComponents`，均扩展实现了`URLConvertible`协议
/// 统一通过调用`asURL()`方法实现向URL的转换。
public protocol URLConvertible {
    /// 返回符合`RFC 2396`的URL，或无法转换成URL时抛出错误`Error`
    func asURL() throws -> URL
}

extension String: URLConvertible {
    /// 如果字符串表示的是一个遵守`RFC 2396`的有效URL字符则返回`URL`实例，否则抛出`AFError`
    ///
    /// - throws: 如果字符串不是有效的URL字符，则抛出错误
    /// - returns: `URL`实例或`AFError`
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw AFError.invalidURL(url: self) }
        return url
    }
}

extension URL: URLConvertible {
    /// 返回`URL`本身
    public func asURL() throws -> URL { return self }
}

extension URLComponents: URLConvertible {
    /// Returns a URL if `url` is not nil, otherwise throws an `Error`.
    ///
    /// - throws: An `AFError.invalidURL` if `url` is `nil`.
    /// - returns: A URL or throws an `AFError`.
    public func asURL() throws -> URL {
        guard let url = url else { throw AFError.invalidURL(url: self) }
        return url
    }
}

// MARK: -

/// 适配了`URLRequestConvertible`协议的类型可用于构造`URLRequest`
public protocol URLRequestConvertible {
    /// 返回`URLRequest`实例，如果有错误发生则抛出`Error`
    ///
    /// - throws: 如果底层`URLRequst`为nil，则抛出错误
    /// - returns: URLRequest实例
    func asURLRequest() throws -> URLRequest
}

extension URLRequestConvertible {
    /// The URL request.
    public var urlRequest: URLRequest? { return try? asURLRequest() }
}

extension URLRequest: URLRequestConvertible {
    /// Returns a URL request or throws if an `Error` was encountered.
    public func asURLRequest() throws -> URLRequest { return self }
}

// MARK: -

extension URLRequest {
    /// 使用指定的请求地址、请求方法、请求头创建`URLReqeust`实例
    ///
    /// - parameter url:     请求地址
    /// - parameter method:  请求方法
    /// - parameter headers: 请求头，默认为nil
    ///
    /// - returns: 新创建的`URLRequest`实例
    public init(url: URLConvertible, method: HTTPMethod, headers: HTTPHeaders? = nil) throws {
        let url = try url.asURL()

        self.init(url: url)

        httpMethod = method.rawValue

        if let headers = headers {
            for (headerField, headerValue) in headers {
                setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
    }

    /// 使用指定的适配器，生成`URLRequest`实例
    /// - Parameter adapter: 适配器
    func adapt(using adapter: RequestAdapter?) throws -> URLRequest {
        guard let adapter = adapter else { return self }
        return try adapter.adapt(self)
    }
}

// MARK: - Data Request

/// 创建指定了请求地址、请求方式、请求参数、参数编码、消息头的`DataRequest`，并使用默认的`sessionManager`发送请求获取内容
///
/// - parameter url:        请求地址
/// - parameter method:     请求方式，默认为`.get`
/// - parameter parameters: 请求参数. 默认为`nil`
/// - parameter encoding:   请求参数的编码. 默认为`URLEncoding.default`
/// - parameter headers:    消息头. 默认为`nil`
///
/// - returns: 创建的`DataRequest`实例
@discardableResult
public func request(
    _ url: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    encoding: ParameterEncoding = URLEncoding.default,
    headers: HTTPHeaders? = nil)
    -> DataRequest
{
    return SessionManager.default.request(
        url,
        method: method,
        parameters: parameters,
        encoding: encoding,
        headers: headers
    )
}

/// Creates a `DataRequest` using the default `SessionManager` to retrieve the contents of a URL based on the
/// specified `urlRequest`.
///
/// - parameter urlRequest: The URL request
///
/// - returns: The created `DataRequest`.
@discardableResult
public func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
    return SessionManager.default.request(urlRequest)
}

// MARK: - Download Request

// MARK: URL Request

/// Creates a `DownloadRequest` using the default `SessionManager` to retrieve the contents of the specified `url`,
/// `method`, `parameters`, `encoding`, `headers` and save them to the `destination`.
///
/// If `destination` is not specified, the contents will remain in the temporary location determined by the
/// underlying URL session.
///
/// - parameter url:         The URL.
/// - parameter method:      The HTTP method. `.get` by default.
/// - parameter parameters:  The parameters. `nil` by default.
/// - parameter encoding:    The parameter encoding. `URLEncoding.default` by default.
/// - parameter headers:     The HTTP headers. `nil` by default.
/// - parameter destination: The closure used to determine the destination of the downloaded file. `nil` by default.
///
/// - returns: The created `DownloadRequest`.
@discardableResult
public func download(
    _ url: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    encoding: ParameterEncoding = URLEncoding.default,
    headers: HTTPHeaders? = nil,
    to destination: DownloadRequest.DownloadFileDestination? = nil)
    -> DownloadRequest
{
    return SessionManager.default.download(
        url,
        method: method,
        parameters: parameters,
        encoding: encoding,
        headers: headers,
        to: destination
    )
}

/// Creates a `DownloadRequest` using the default `SessionManager` to retrieve the contents of a URL based on the
/// specified `urlRequest` and save them to the `destination`.
///
/// If `destination` is not specified, the contents will remain in the temporary location determined by the
/// underlying URL session.
///
/// - parameter urlRequest:  The URL request.
/// - parameter destination: The closure used to determine the destination of the downloaded file. `nil` by default.
///
/// - returns: The created `DownloadRequest`.
@discardableResult
public func download(
    _ urlRequest: URLRequestConvertible,
    to destination: DownloadRequest.DownloadFileDestination? = nil)
    -> DownloadRequest
{
    return SessionManager.default.download(urlRequest, to: destination)
}

// MARK: Resume Data

/// Creates a `DownloadRequest` using the default `SessionManager` from the `resumeData` produced from a
/// previous request cancellation to retrieve the contents of the original request and save them to the `destination`.
///
/// If `destination` is not specified, the contents will remain in the temporary location determined by the
/// underlying URL session.
///
/// On the latest release of all the Apple platforms (iOS 10, macOS 10.12, tvOS 10, watchOS 3), `resumeData` is broken
/// on background URL session configurations. There's an underlying bug in the `resumeData` generation logic where the
/// data is written incorrectly and will always fail to resume the download. For more information about the bug and
/// possible workarounds, please refer to the following Stack Overflow post:
///
///    - http://stackoverflow.com/a/39347461/1342462
///
/// - parameter resumeData:  The resume data. This is an opaque data blob produced by `URLSessionDownloadTask`
///                          when a task is cancelled. See `URLSession -downloadTask(withResumeData:)` for additional
///                          information.
/// - parameter destination: The closure used to determine the destination of the downloaded file. `nil` by default.
///
/// - returns: The created `DownloadRequest`.
@discardableResult
public func download(
    resumingWith resumeData: Data,
    to destination: DownloadRequest.DownloadFileDestination? = nil)
    -> DownloadRequest
{
    return SessionManager.default.download(resumingWith: resumeData, to: destination)
}

// MARK: - Upload Request

// MARK: File

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `url`, `method` and `headers`
/// for uploading the `file`.
///
/// - parameter file:    The file to upload.
/// - parameter url:     The URL.
/// - parameter method:  The HTTP method. `.post` by default.
/// - parameter headers: The HTTP headers. `nil` by default.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(
    _ fileURL: URL,
    to url: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil)
    -> UploadRequest
{
    return SessionManager.default.upload(fileURL, to: url, method: method, headers: headers)
}

/// Creates a `UploadRequest` using the default `SessionManager` from the specified `urlRequest` for
/// uploading the `file`.
///
/// - parameter file:       The file to upload.
/// - parameter urlRequest: The URL request.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(_ fileURL: URL, with urlRequest: URLRequestConvertible) -> UploadRequest {
    return SessionManager.default.upload(fileURL, with: urlRequest)
}

// MARK: Data

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `url`, `method` and `headers`
/// for uploading the `data`.
///
/// - parameter data:    The data to upload.
/// - parameter url:     The URL.
/// - parameter method:  The HTTP method. `.post` by default.
/// - parameter headers: The HTTP headers. `nil` by default.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(
    _ data: Data,
    to url: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil)
    -> UploadRequest
{
    return SessionManager.default.upload(data, to: url, method: method, headers: headers)
}

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `urlRequest` for
/// uploading the `data`.
///
/// - parameter data:       The data to upload.
/// - parameter urlRequest: The URL request.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(_ data: Data, with urlRequest: URLRequestConvertible) -> UploadRequest {
    return SessionManager.default.upload(data, with: urlRequest)
}

// MARK: InputStream

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `url`, `method` and `headers`
/// for uploading the `stream`.
///
/// - parameter stream:  The stream to upload.
/// - parameter url:     The URL.
/// - parameter method:  The HTTP method. `.post` by default.
/// - parameter headers: The HTTP headers. `nil` by default.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(
    _ stream: InputStream,
    to url: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil)
    -> UploadRequest
{
    return SessionManager.default.upload(stream, to: url, method: method, headers: headers)
}

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `urlRequest` for
/// uploading the `stream`.
///
/// - parameter urlRequest: The URL request.
/// - parameter stream:     The stream to upload.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(_ stream: InputStream, with urlRequest: URLRequestConvertible) -> UploadRequest {
    return SessionManager.default.upload(stream, with: urlRequest)
}

// MARK: MultipartFormData

/// Encodes `multipartFormData` using `encodingMemoryThreshold` with the default `SessionManager` and calls
/// `encodingCompletion` with new `UploadRequest` using the `url`, `method` and `headers`.
///
/// It is important to understand the memory implications of uploading `MultipartFormData`. If the cummulative
/// payload is small, encoding the data in-memory and directly uploading to a server is the by far the most
/// efficient approach. However, if the payload is too large, encoding the data in-memory could cause your app to
/// be terminated. Larger payloads must first be written to disk using input and output streams to keep the memory
/// footprint low, then the data can be uploaded as a stream from the resulting file. Streaming from disk MUST be
/// used for larger payloads such as video content.
///
/// The `encodingMemoryThreshold` parameter allows Alamofire to automatically determine whether to encode in-memory
/// or stream from disk. If the content length of the `MultipartFormData` is below the `encodingMemoryThreshold`,
/// encoding takes place in-memory. If the content length exceeds the threshold, the data is streamed to disk
/// during the encoding process. Then the result is uploaded as data or as a stream depending on which encoding
/// technique was used.
///
/// - parameter multipartFormData:       The closure used to append body parts to the `MultipartFormData`.
/// - parameter encodingMemoryThreshold: The encoding memory threshold in bytes.
///                                      `multipartFormDataEncodingMemoryThreshold` by default.
/// - parameter url:                     The URL.
/// - parameter method:                  The HTTP method. `.post` by default.
/// - parameter headers:                 The HTTP headers. `nil` by default.
/// - parameter encodingCompletion:      The closure called when the `MultipartFormData` encoding is complete.
public func upload(
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
    to url: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil,
    encodingCompletion: ((SessionManager.MultipartFormDataEncodingResult) -> Void)?)
{
    return SessionManager.default.upload(
        multipartFormData: multipartFormData,
        usingThreshold: encodingMemoryThreshold,
        to: url,
        method: method,
        headers: headers,
        encodingCompletion: encodingCompletion
    )
}

/// Encodes `multipartFormData` using `encodingMemoryThreshold` and the default `SessionManager` and
/// calls `encodingCompletion` with new `UploadRequest` using the `urlRequest`.
///
/// It is important to understand the memory implications of uploading `MultipartFormData`. If the cummulative
/// payload is small, encoding the data in-memory and directly uploading to a server is the by far the most
/// efficient approach. However, if the payload is too large, encoding the data in-memory could cause your app to
/// be terminated. Larger payloads must first be written to disk using input and output streams to keep the memory
/// footprint low, then the data can be uploaded as a stream from the resulting file. Streaming from disk MUST be
/// used for larger payloads such as video content.
///
/// The `encodingMemoryThreshold` parameter allows Alamofire to automatically determine whether to encode in-memory
/// or stream from disk. If the content length of the `MultipartFormData` is below the `encodingMemoryThreshold`,
/// encoding takes place in-memory. If the content length exceeds the threshold, the data is streamed to disk
/// during the encoding process. Then the result is uploaded as data or as a stream depending on which encoding
/// technique was used.
///
/// - parameter multipartFormData:       The closure used to append body parts to the `MultipartFormData`.
/// - parameter encodingMemoryThreshold: The encoding memory threshold in bytes.
///                                      `multipartFormDataEncodingMemoryThreshold` by default.
/// - parameter urlRequest:              The URL request.
/// - parameter encodingCompletion:      The closure called when the `MultipartFormData` encoding is complete.
public func upload(
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
    with urlRequest: URLRequestConvertible,
    encodingCompletion: ((SessionManager.MultipartFormDataEncodingResult) -> Void)?)
{
    return SessionManager.default.upload(
        multipartFormData: multipartFormData,
        usingThreshold: encodingMemoryThreshold,
        with: urlRequest,
        encodingCompletion: encodingCompletion
    )
}

#if !os(watchOS)

// MARK: - Stream Request

// MARK: Hostname and Port

/// Creates a `StreamRequest` using the default `SessionManager` for bidirectional streaming with the `hostname`
/// and `port`.
///
/// If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.
///
/// - parameter hostName: The hostname of the server to connect to.
/// - parameter port:     The port of the server to connect to.
///
/// - returns: The created `StreamRequest`.
@discardableResult
@available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
public func stream(withHostName hostName: String, port: Int) -> StreamRequest {
    return SessionManager.default.stream(withHostName: hostName, port: port)
}

// MARK: NetService

/// Creates a `StreamRequest` using the default `SessionManager` for bidirectional streaming with the `netService`.
///
/// If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.
///
/// - parameter netService: The net service used to identify the endpoint.
///
/// - returns: The created `StreamRequest`.
@discardableResult
@available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
public func stream(with netService: NetService) -> StreamRequest {
    return SessionManager.default.stream(with: netService)
}

#endif

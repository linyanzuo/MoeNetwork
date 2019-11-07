//
//  AFError.swift
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

/// `AFError`是Alamofire返回的错误类型，它包含了一些不同的错误类型，每种都有它们关联的原因
public enum AFError: Error {
    /// 参数编码错误发生的底层原因
    public enum ParameterEncodingFailureReason {
        /// URL请求并不包含可以编码的URL地址
        case missingURL
        /// 编码处理时，`JSONSerizlization`因为系统底层错误导致操作失败
        case jsonEncodingFailed(error: Error)
        /// 编码处理时，`PropertyListSerialization`因为系统底层错误导致操作失败
        case propertyListEncodingFailed(error: Error)
    }
    
    /// 多部分(`Multipart/form-data`支持二进制数据或表单键值对)编码错误发生的底层原因
    public enum MultipartEncodingFailureReason {
        /// 准备读取的可编码主体部分的`fileURL`不是有效的文件资源地址
        case bodyPartURLInvalid(url: URL)
        /// `fileURL`的文件名不包含后缀名，即`lastPathComponent`或`pathExtension`的值为空字符串
        case bodyPartFilenameInvalid(in: URL)
        /// 无法获取`fileURL`所提供的文件
        case bodyPartFileNotReachable(at: URL)
        /// Attempting to check the reachability of the `fileURL` provided threw an error.
        case bodyPartFileNotReachableWithError(atURL: URL, error: Error)
        /// `fileURL`所提供的文件实际上是个目录
        case bodyPartFileIsDirectory(at: URL)
        /// 系统无法返回`fileURL`所提供文件的大小
        case bodyPartFileSizeNotAvailable(at: URL)
        /// 尝试获取`fileURL`所提供文件的大小时，抛出了异常
        case bodyPartFileSizeQueryFailedWithError(forURL: URL, error: Error)
        /// 无法为提供的`fielURL`创建输入流
        case bodyPartInputStreamCreationFailed(for: URL)

        /// 当尝试向硬盘写入编码后的数据时， 无法创建输出流
        case outputStreamCreationFailed(for: URL)
        /// 编码后的主体数据无法写入硬盘，因为已存在与提供的`fileURL`同名的文件
        case outputStreamFileAlreadyExists(at: URL)
        /// 用于向硬盘写入编码后数据的`fileURL`(输出路径)，不是有效的文件资源地址
        case outputStreamURLInvalid(url: URL)
        /// 因为底层错误，导致尝试向硬盘写入编码后数据时失败
        case outputStreamWriteFailed(error: Error)

        /// 因为底层错误，导致尝试读取编码后主体数据的输入流时失败
        case inputStreamReadFailed(error: Error)
    }
    
    /// 响应验证错误发生的底层原因
    public enum ResponseValidationFailureReason {
        /// 包含服务器响应的数据文件并不存在
        case dataFileNil
        /// 包含服务器响应的数据文件无法被读取
        case dataFileReadFailed(at: URL)
        /// 响应并未包含`Content-Type`，且提供的`Validation > acceptableContentTypes`并未包含通配符(*)类型
        case missingContentType(acceptableContentTypes: [String])
        /// 响应的`Content-Type`并不匹配`acceptableContentTypes`中的任何类型
        case unacceptableContentType(acceptableContentTypes: [String], responseContentType: String)
        /// 响应的状态码不被接受
        case unacceptableStatusCode(code: Int)
    }
    
    /// 响应序列化操作错误发生的底层原因
    public enum ResponseSerializationFailureReason {
        /// 服务器响应并无包含数据
        case inputDataNil
        /// 服务器响应并无包含数据，或数据长度为0
        case inputDataNilOrZeroLength
        /// 包含服务器响应的文件并不存在
        case inputFileNil
        /// 包含服务器响应的文件无法被读取
        case inputFileReadFailed(at: URL)
        /// 使用提供的`String.Encoding`进行字符串序列化失败
        case stringSerializationFailed(encoding: String.Encoding)
        /// `JSONSerialization`因底层系统错误导致序列化失败
        case jsonSerializationFailed(error: Error)
        /// `PropertyListSerialization`因底层系统错误导致序列化失败
        case propertyListSerializationFailed(error: Error)
    }
    
    /// 当`URLConvertible`类型未能创建有效的`URL`时，则返回该错误
    case invalidURL(url: URLConvertible)
    /// 当`ParameterEncoding`对象处理编码时抛出异常，则返回该错误
    case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
    /// 当多部分(`Multipart/form-data`支持二进制数据或表单键值对)编码处理的某一步出错时，则返回该错误
    case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
    /// 当调用`validate()`(响应数据检验)失败时，则返回该错误
    case responseValidationFailed(reason: ResponseValidationFailureReason)
    /// 响应序列化器进行序列化处理时遭遇错误，则返回该错误
    case responseSerializationFailed(reason: ResponseSerializationFailureReason)
}

// MARK: - Adapt Error

/// 适配器错误，用于`RequestAdapter`
struct AdaptError: Error {
    let error: Error
}

extension Error {
    var underlyingAdaptError: Error? { return (self as? AdaptError)?.error }
}

// MARK: - Error Booleans

extension AFError {
    /// Returns whether the AFError is an invalid URL error.
    public var isInvalidURLError: Bool {
        if case .invalidURL = self { return true }
        return false
    }

    /// Returns whether the AFError is a parameter encoding error. When `true`, the `underlyingError` property will
    /// contain the associated value.
    public var isParameterEncodingError: Bool {
        if case .parameterEncodingFailed = self { return true }
        return false
    }

    /// Returns whether the AFError is a multipart encoding error. When `true`, the `url` and `underlyingError` properties
    /// will contain the associated values.
    public var isMultipartEncodingError: Bool {
        if case .multipartEncodingFailed = self { return true }
        return false
    }

    /// Returns whether the `AFError` is a response validation error. When `true`, the `acceptableContentTypes`,
    /// `responseContentType`, and `responseCode` properties will contain the associated values.
    public var isResponseValidationError: Bool {
        if case .responseValidationFailed = self { return true }
        return false
    }

    /// Returns whether the `AFError` is a response serialization error. When `true`, the `failedStringEncoding` and
    /// `underlyingError` properties will contain the associated values.
    public var isResponseSerializationError: Bool {
        if case .responseSerializationFailed = self { return true }
        return false
    }
}

// MARK: - Convenience Properties

extension AFError {
    /// The `URLConvertible` associated with the error.
    public var urlConvertible: URLConvertible? {
        switch self {
        case .invalidURL(let url):
            return url
        default:
            return nil
        }
    }

    /// The `URL` associated with the error.
    public var url: URL? {
        switch self {
        case .multipartEncodingFailed(let reason):
            return reason.url
        default:
            return nil
        }
    }

    /// The `Error` returned by a system framework associated with a `.parameterEncodingFailed`,
    /// `.multipartEncodingFailed` or `.responseSerializationFailed` error.
    public var underlyingError: Error? {
        switch self {
        case .parameterEncodingFailed(let reason):
            return reason.underlyingError
        case .multipartEncodingFailed(let reason):
            return reason.underlyingError
        case .responseSerializationFailed(let reason):
            return reason.underlyingError
        default:
            return nil
        }
    }

    /// The acceptable `Content-Type`s of a `.responseValidationFailed` error.
    public var acceptableContentTypes: [String]? {
        switch self {
        case .responseValidationFailed(let reason):
            return reason.acceptableContentTypes
        default:
            return nil
        }
    }

    /// The response `Content-Type` of a `.responseValidationFailed` error.
    public var responseContentType: String? {
        switch self {
        case .responseValidationFailed(let reason):
            return reason.responseContentType
        default:
            return nil
        }
    }

    /// The response code of a `.responseValidationFailed` error.
    public var responseCode: Int? {
        switch self {
        case .responseValidationFailed(let reason):
            return reason.responseCode
        default:
            return nil
        }
    }

    /// The `String.Encoding` associated with a failed `.stringResponse()` call.
    public var failedStringEncoding: String.Encoding? {
        switch self {
        case .responseSerializationFailed(let reason):
            return reason.failedStringEncoding
        default:
            return nil
        }
    }
}

extension AFError.ParameterEncodingFailureReason {
    var underlyingError: Error? {
        switch self {
        case .jsonEncodingFailed(let error), .propertyListEncodingFailed(let error):
            return error
        default:
            return nil
        }
    }
}

extension AFError.MultipartEncodingFailureReason {
    var url: URL? {
        switch self {
        case .bodyPartURLInvalid(let url), .bodyPartFilenameInvalid(let url), .bodyPartFileNotReachable(let url),
             .bodyPartFileIsDirectory(let url), .bodyPartFileSizeNotAvailable(let url),
             .bodyPartInputStreamCreationFailed(let url), .outputStreamCreationFailed(let url),
             .outputStreamFileAlreadyExists(let url), .outputStreamURLInvalid(let url),
             .bodyPartFileNotReachableWithError(let url, _), .bodyPartFileSizeQueryFailedWithError(let url, _):
            return url
        default:
            return nil
        }
    }

    var underlyingError: Error? {
        switch self {
        case .bodyPartFileNotReachableWithError(_, let error), .bodyPartFileSizeQueryFailedWithError(_, let error),
             .outputStreamWriteFailed(let error), .inputStreamReadFailed(let error):
            return error
        default:
            return nil
        }
    }
}

extension AFError.ResponseValidationFailureReason {
    var acceptableContentTypes: [String]? {
        switch self {
        case .missingContentType(let types), .unacceptableContentType(let types, _):
            return types
        default:
            return nil
        }
    }

    var responseContentType: String? {
        switch self {
        case .unacceptableContentType(_, let responseType):
            return responseType
        default:
            return nil
        }
    }

    var responseCode: Int? {
        switch self {
        case .unacceptableStatusCode(let code):
            return code
        default:
            return nil
        }
    }
}

extension AFError.ResponseSerializationFailureReason {
    var failedStringEncoding: String.Encoding? {
        switch self {
        case .stringSerializationFailed(let encoding):
            return encoding
        default:
            return nil
        }
    }

    var underlyingError: Error? {
        switch self {
        case .jsonSerializationFailed(let error), .propertyListSerializationFailed(let error):
            return error
        default:
            return nil
        }
    }
}

// MARK: - Error Descriptions

extension AFError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "URL is not valid: \(url)"
        case .parameterEncodingFailed(let reason):
            return reason.localizedDescription
        case .multipartEncodingFailed(let reason):
            return reason.localizedDescription
        case .responseValidationFailed(let reason):
            return reason.localizedDescription
        case .responseSerializationFailed(let reason):
            return reason.localizedDescription
        }
    }
}

extension AFError.ParameterEncodingFailureReason {
    var localizedDescription: String {
        switch self {
        case .missingURL:
            return "URL request to encode was missing a URL"
        case .jsonEncodingFailed(let error):
            return "JSON could not be encoded because of error:\n\(error.localizedDescription)"
        case .propertyListEncodingFailed(let error):
            return "PropertyList could not be encoded because of error:\n\(error.localizedDescription)"
        }
    }
}

extension AFError.MultipartEncodingFailureReason {
    var localizedDescription: String {
        switch self {
        case .bodyPartURLInvalid(let url):
            return "The URL provided is not a file URL: \(url)"
        case .bodyPartFilenameInvalid(let url):
            return "The URL provided does not have a valid filename: \(url)"
        case .bodyPartFileNotReachable(let url):
            return "The URL provided is not reachable: \(url)"
        case .bodyPartFileNotReachableWithError(let url, let error):
            return (
                "The system returned an error while checking the provided URL for " +
                "reachability.\nURL: \(url)\nError: \(error)"
            )
        case .bodyPartFileIsDirectory(let url):
            return "The URL provided is a directory: \(url)"
        case .bodyPartFileSizeNotAvailable(let url):
            return "Could not fetch the file size from the provided URL: \(url)"
        case .bodyPartFileSizeQueryFailedWithError(let url, let error):
            return (
                "The system returned an error while attempting to fetch the file size from the " +
                "provided URL.\nURL: \(url)\nError: \(error)"
            )
        case .bodyPartInputStreamCreationFailed(let url):
            return "Failed to create an InputStream for the provided URL: \(url)"
        case .outputStreamCreationFailed(let url):
            return "Failed to create an OutputStream for URL: \(url)"
        case .outputStreamFileAlreadyExists(let url):
            return "A file already exists at the provided URL: \(url)"
        case .outputStreamURLInvalid(let url):
            return "The provided OutputStream URL is invalid: \(url)"
        case .outputStreamWriteFailed(let error):
            return "OutputStream write failed with error: \(error)"
        case .inputStreamReadFailed(let error):
            return "InputStream read failed with error: \(error)"
        }
    }
}

extension AFError.ResponseSerializationFailureReason {
    var localizedDescription: String {
        switch self {
        case .inputDataNil:
            return "Response could not be serialized, input data was nil."
        case .inputDataNilOrZeroLength:
            return "Response could not be serialized, input data was nil or zero length."
        case .inputFileNil:
            return "Response could not be serialized, input file was nil."
        case .inputFileReadFailed(let url):
            return "Response could not be serialized, input file could not be read: \(url)."
        case .stringSerializationFailed(let encoding):
            return "String could not be serialized with encoding: \(encoding)."
        case .jsonSerializationFailed(let error):
            return "JSON could not be serialized because of error:\n\(error.localizedDescription)"
        case .propertyListSerializationFailed(let error):
            return "PropertyList could not be serialized because of error:\n\(error.localizedDescription)"
        }
    }
}

extension AFError.ResponseValidationFailureReason {
    var localizedDescription: String {
        switch self {
        case .dataFileNil:
            return "Response could not be validated, data file was nil."
        case .dataFileReadFailed(let url):
            return "Response could not be validated, data file could not be read: \(url)."
        case .missingContentType(let types):
            return (
                "Response Content-Type was missing and acceptable content types " +
                "(\(types.joined(separator: ","))) do not match \"*/*\"."
            )
        case .unacceptableContentType(let acceptableTypes, let responseType):
            return (
                "Response Content-Type \"\(responseType)\" does not match any acceptable types: " +
                "\(acceptableTypes.joined(separator: ","))."
            )
        case .unacceptableStatusCode(let code):
            return "Response status code was unacceptable: \(code)."
        }
    }
}

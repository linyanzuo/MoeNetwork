//
//  NetworkAgent.swift
//  Alamofire
//
//  Created by Zed on 2019/10/29.
//

import UIKit
import Alamofire
import HandyJSON


class NetworkAgent {
    typealias MRequest = MoeNetwork.Request
    typealias MResponse = MoeNetwork.Response
    typealias ARequest = Alamofire.Request
    
    private let config = NetworkConfig.shared
    private let allStatuCodes = IndexSet(integersIn: 100...500)
    private var manager: Alamofire.SessionManager
        
    ///  获取共享实例
    static public let shared = NetworkAgent()
    private init(){
        manager = SessionManager(configuration: config.sessionConfiguration)
        manager.startRequestsImmediately = false
    }
    
    internal func add(request: Request) {
        // request构建了自定义请求，直接发送
        if let customRequest = request.generateCustomURLRequest() {
            ///  Todo: 自定义请求功能待完成
            let dataRequest: DataRequest = manager.request(customRequest)
            dataRequest.resume()
        }
        //  依据request的相关参数， 生成匹配的请求
        else {
            let generatedDataRequest = buildNetworkRequest(for: request)
            generatedDataRequest.resume()
        }
    }
    
    /// 构建要发送请求对应的`底层请求`
    /// - Parameter request: 要发送的请求
    private func buildNetworkRequest(for request: MRequest) -> DataRequest {
        let method = buildUnderlyingMethod(for: request)
        var dataRequest: DataRequest?
        
        switch method {
        case .get, .post:
            dataRequest = buildUnderlyingRequest(request: request)
//        case .post:
//            dataRequest = buildUnderlyingBodyRequest(request: request)
        default:
            print("待完善")
            dataRequest = buildUnderlyingRequest(request: request)
        }
        
        let serializer = buildUnderlyingSerializer(for: request)
        dataRequest!.response(responseSerializer: serializer) { [weak self] (response) in
            // 回调代码在主线程中被执行
            self?.handleUnderlyingResponse(response, for: request)
        }
        return dataRequest!
    }
}


// MARK: 构建参数
extension NetworkAgent {
    /// 构造请求的URL地址
    /// - Parameter request: 要发送的请求
    private func buildURL(for request: MRequest) -> URL {
        // 如果`path`已是完整路径，则直接返回
        if let detailURL = URL(string: request.path()),
            detailURL.host != nil, detailURL.scheme != nil
        {
            let url = URL(string: request.path())
            NetworkHelper.buildURLAssert(condition: url == nil)
            return url!
        }
        
        // 拼接完整的URL地址
        var baseURL: URL? = config.baseURL
        if request.baseURL()?.absoluteString.count ?? 0 > 0 { baseURL = request.baseURL() }
        
        var fullURL = baseURL?.appendingPathComponent(request.path(), isDirectory: false)
        NetworkHelper.buildURLAssert(condition: fullURL != nil)
        
        // 拼接额外添加的子路径
        if let subpaths = request.addtionalSubpath {
            for path in subpaths {
                fullURL = fullURL!.appendingPathComponent(path)
            }
        }
        
        return fullURL!
    }
    
    /// 构造请求的报头(`header`)
    /// - Parameter request: 要发送的请求
    internal func buildHeader(request: Request) -> [String: String] {
        var result = Dictionary<String, String>()

        // 添加Token报头域
        if request.requiredAuthorization() == true, let token = NetworkConfig.shared.authenticationToken {
            result["Authorization"] = token
        }
        // 添加额外配置的报头域
        if let fieldDict = request.addtionalHeader {
            for fieldName in fieldDict.keys {
                result[fieldName] = fieldDict[fieldName]
            }
        }
        
        return result
    }
}


// MARK: 构建底层依赖
extension NetworkAgent {
    /// 返回要发送请求中请求方法对应的底层实现
    /// - Parameter request: 要发送的请求
    internal func buildUnderlyingMethod(for request: MRequest) -> HTTPMethod {
        switch request.method() {
        case .get: return HTTPMethod.get
        case .post: return HTTPMethod.post
        case .put: return HTTPMethod.put
        case .delete: return HTTPMethod.delete
        case .head: return HTTPMethod.head
        case .patch: return HTTPMethod.patch
        }
    }
    
    /// 返回要发送请求中参数编码方式的底层实现
    /// - Parameter request: 要发送的请求
    internal func buildUnderlyingEncoding(request: Request) -> ParameterEncoding {
        switch request.method() {
        case .put:
            return JSONEncoding.default
        case .post:
            return JSONEncoding.default
        default:
            return URLEncoding.default
        }
    }
    
    /// 返回要发送请求中响应序列化器的底层实现
    /// - Parameter request: 要发送的请求
    private func buildUnderlyingSerializer(for request: MRequest) -> DataResponseSerializer<Any> {
        switch request.serializer() {
        case .xml:
            return DataRequest.propertyListResponseSerializer(options: [])
        case .handyJson:
            /// Todo: 暂使用`!`强制有值，待处理
            let responseType = request.serializer().responseType!
            return DataRequest.handyJsonResponseSerializer(options: .allowFragments,
                                                           responseType: responseType)
        default:
            return DataRequest.jsonResponseSerializer(options: .allowFragments)
        }
    }
    
    /// 返回要发送请求的最终底层实现
    /// - Parameter request: 要发送的请求
    private func buildUnderlyingRequest(request: MRequest) -> DataRequest {
        let dataRequest = manager.request(buildURL(for: request),
                                          method: buildUnderlyingMethod(for: request),
                                          parameters: request.addtionalParameter,
                                          encoding: buildUnderlyingEncoding(request: request),
                                          headers: buildHeader(request: request))
        return dataRequest
    }
    
    private func buildUnderlyingBodyRequest(request: MRequest) -> DataRequest {
        var req = URLRequest(url: request.url)
        req.httpMethod = NetworkAgent.shared.buildUnderlyingMethod(for: request).rawValue
        
        let headers = buildHeader(request: request)
        for (fieldName, fieldValue) in headers {
            req.setValue(fieldValue, forHTTPHeaderField: fieldName)
        }
        
        /// Todo: 待修改， 临时用
        if req.value(forHTTPHeaderField: "Content-Type") == nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let body = request.customBody {
            req.httpBody = body.data(using: .utf8, allowLossyConversion: false)
        }
        
        let dataRequest = manager.request(req)
        return dataRequest
    }
    
//    private func requstTest(request: MRequest) -> DataRequest {
//        let url = buildURL(for: request)
//        let method = buildUnderlyingMethod(for: request)
//        let headers = buildHeader(request: request)
//        let encoding = URLEncoding.default
//        let parameters = request.addtionalParameter
//
//        var originalRequest: URLRequest?
//
//        do {
//            originalRequest = try URLRequest(url: url, method: method, headers: headers)
//            let encodedURLRequest = try encoding.encode(originalRequest!, with: parameters)
//            return manager.request(encodedURLRequest)
//        } catch {
//            return manager.request(originalRequest, failedWith: error)
//        }
//    }
    
    /// 对底层响应的处理
    /// - Parameter response: 请求的底层响应结果
    /// - Parameter request: 要发送的请求
    private func handleUnderlyingResponse(_ response: DataResponse<Any>, for request: MRequest) {
        let result = response.result
        let startDate = Date(timeIntervalSinceReferenceDate: response.timeline.requestStartTime)
        let endDate = Date(timeIntervalSinceReferenceDate: response.timeline.requestCompletedTime)
        
        guard result.isSuccess == true else {
            let error = NetworkError(code: -1,
                                     message: "Unknow error",
                                     requstURL: response.request?.url,
                                     requestStartTime: startDate,
                                     requestCompletedTime: endDate)
            requested(request, didFailWith: error)
            return
        }
        
        // 请求成功，对数据进行二次处理
        let res = MResponse()
        res.startTime = startDate
        res.completedTime = endDate
        res.originalData = response.data
        res.jsonDictionary = response.value as? [String: Any]
        res.handyObject = response.value as? HandyObject
        res.response = response.response
        
        requested(request, didSuccessedWith: res)
    }
}


// MARK: 结果处理
extension NetworkAgent {
    
    /// 请求成功的统一结果处理
    /// - Parameter request: 发送的请求
    /// - Parameter response: 请求的响应结果
    private func requested(_ request: MRequest, didSuccessedWith response: MResponse) {
        ///  Todo: 请求完成后， 执行 Filter & Accessory
        
        // 回调已经在主纯程中执行
        request.delegate?.requestSuccessed(request: request, with: response)
        request.successedHandler?(request, response)
        
        request.delegate?.requestCompleted(request: request, isSuccess: true)
        request.completedHandler?(request, true)
    }
    
    /// 请求失败的统一结果处理
    /// - Parameter request: 发送的请求
    /// - Parameter error: 请求的错误信息，如果存在
    private func requested(_ request: MRequest, didFailWith error: NetworkError) {
        request.delegate?.requestFailed(request: request, with: error)
        request.failedHandler?(request, error)
        
        request.delegate?.requestCompleted(request: request, isSuccess: false)
        request.completedHandler?(request, false)
    }
    
//    /// Todo: 待删除
//    internal func responseHandle(response: DataResponse<Any>,
//                                 responseType: HandyObject.Type,
//                                       success: SuccessClosure?,
//                                       fail: FailClosure?,
//                                       completion: CompletionClosure? = nil) -> Bool
//    {
//        let result: Result = response.result
//
//        // -- Network connection check
//        guard result.isSuccess == true else {
//            let errMsg = AssetHelper.localizedString(key: "check_connection")
//            NetworkHelper.shared.showError(errMsg)
//            return false
//        }
//        // -- Response data format check
//        guard let dict = result.value as? [String: Any] else {
//            let errMsg = AssetHelper.localizedString(key: "response_format")
//            NetworkHelper.shared.showDevError(errMsg)
//            return false
//        }
//        // -- Response Data Deserialize
//        guard let response = responseType.deserialize(from: dict) else {
//            let errMsg = AssetHelper.localizedString(key: "deserialize_json")
//            NetworkHelper.shared.showDevError(errMsg)
//            return false
//        }
//        // -- Error Code Check
//        let errorCode = response.statusCode()
//        guard errorCode == 0 else {
//            let errMsg = AssetHelper.localizedString(key: "get_error_code")
//            MLog(errMsg)
//            let errorMessage = response.statusMessage()
//            if NetworkHelper.shared.checkHttpErrorCode(errorCode: errorCode, errorMessage: errorMessage) { return false }
//            if NetworkHelper.shared.checkServerErrorCode(errorCode: errorCode, errorMessage: errorMessage) { return false }
//
//            ///  Todo: Error修改成NetworkError导致的代码，待处理
////            fail?(NetworkError(code: errorCode, message: errorMessage))
//            return false
//        }
//        success?(response)
//        return true
//    }
}

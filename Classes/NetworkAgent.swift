//
//  NetworkAgent.swift
//  Alamofire
//
//  Created by Zed on 2019/10/29.
//

import UIKit
import Alamofire
import HandyJSON
import MoeCommon


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
        request.accessoriesStateChange(.willStart, with: false)
        
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
        var dataRequest: DataRequest?
        
        switch request.method() {
        case .get, .post:
            dataRequest = buildUnderlyingRequest(request: request)
//        case .post:
//            if request.customBody == nil { dataRequest = buildUnderlyingRequest(request: request) }
//            else { dataRequest = buildUnderlyingBodyRequest(request: request) }
        default:
            print("`buildNetworkRequest` - 待完善")
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
    /// 构造请求地址
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
    
    /// 构建请求报头(`header`)
    /// - Parameter request: 要发送的请求
    internal func buildHeaderFields(request: MRequest) -> [String: String] {
        var result = Dictionary<String, String>()
        let config = NetworkConfig.shared
        
        // 全局的报头配置及报头注入
        if let fieldDict = config.addtionalHeader { result += fieldDict }
        if let injectors = config.injectors {
            for injector in injectors { result = injector.injectHeaderField(result, to: request) }
        }
        // 请求的报头配置及报头注入
        if let fieldDict = request.addtionalHeader { result += fieldDict }
        if let injectors = request.injectors {
            for injector in injectors { result = injector.injectHeaderField(result, to: request) }
        }
        
        return result
    }
    
    /// 构建请求参数(`parameter`)
    /// - Parameter request: 要发送的请求
    internal func buildParameter(request: MRequest) -> [String: Any] {
        var result = Dictionary<String, Any>()
        let config = NetworkConfig.shared
        
        // 全局的参数配置及报头注入
        if let globalPara = config.addtionalParameter { result += globalPara }
        if let injectors = config.injectors {
            for injector in injectors { result = injector.injectParameters(result, to: request) }
        }
        // 请求的参数配置及报头注入
        if let para = request.addtionalParameter { result += para }
        if let injectors = request.injectors {
            for injector in injectors { result = injector.injectParameters(result, to: request) }
        }
        
        return result
    }
    
    internal func buildURLRequest(request: MRequest) -> URLRequest {
        var urlRequest = URLRequest(url: buildURL(for: request))
        urlRequest.httpMethod = request.method().rawValue
    
        for (fieldName, fieldValue) in buildHeaderFields(request: request) {
            urlRequest.setValue(fieldValue, forHTTPHeaderField: fieldName)
        }
        
        do {
            let encoding = buildUnderlyingEncoding(request: request)
            urlRequest = try encoding.encode(urlRequest, with: buildParameter(request: request))
        } catch {
            /// Todo: 编码错误的处理
        }
        
        // 自定义请求体
        if let body = request.customBody {
            urlRequest.httpBody = body.data(using: .utf8, allowLossyConversion: false)
        }
        
        return urlRequest
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
        // GET请求的参数只能使用URL编码`URLEncoding`
        if request.method() == .get { return URLEncoding.default }
        
        switch request.parameterEncoding() {
        case .jsonEncoding:
            return JSONEncoding.default
        case .urlEncoding:
            return URLEncoding.default
        case .xmlEncoding:
            return PropertyListEncoding.default
        }
    }
    
    /// 返回要发送请求中响应序列化器的底层实现
    /// - Parameter request: 要发送的请求
    private func buildUnderlyingSerializer(for request: MRequest) -> DataResponseSerializer<Any> {
        switch request.serializer() {
        case .xml:
            return DataRequest.propertyListResponseSerializer(options: [])
//        case .handyJson:
//            let responseType = request.serializer().responseType!
//            return DataRequest.handyJsonResponseSerializer(options: .allowFragments,
//                                                           responseType: responseType)
//        case .json:
        default:
            return DataRequest.jsonResponseSerializer(options: .allowFragments)
//        case .data:
//            return DataRequest.dataResponseSerializer()
//        case .string:
//            return DataRequest.stringResponseSerializer()
        }
    }
    
    /// 返回要发送请求的最终底层实现
    /// - Parameter request: 要发送的请求
    private func buildUnderlyingRequest(request: MRequest) -> DataRequest {
        let urlRequest = buildURLRequest(request: request)
        return manager.request(urlRequest)
    }
    
//    private func buildUnderlyingBodyRequest(request: MRequest) -> DataRequest {
//        var req = URLRequest(url: buildURL(for: request))
//        req.httpMethod = request.method().rawValue
//
//        let headers = buildHeaderFields(request: request)
//        for (fieldName, fieldValue) in headers {
//            req.setValue(fieldValue, forHTTPHeaderField: fieldName)
//        }
//
//        /// Todo: 待修改， 临时用
//        if req.value(forHTTPHeaderField: "Content-Type") == nil {
//            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        }
//
//        if let body = request.customBody {
//            req.httpBody = body.data(using: .utf8, allowLossyConversion: false)
//        }
//
//        let dataRequest = manager.request(req)
//        return dataRequest
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
                                     message: "Request fail",
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
        request.accessoriesStateChange(.willComplete, with: true)
        
        // 回调已经在主纯程中执行
        request.delegate?.requestSuccessed(request: request, with: response)
        request.successedHandler?(request, response)
        
        request.delegate?.requestCompleted(request: request, isSuccess: true)
        request.completedHandler?(request, true)
        
        request.accessoriesStateChange(.didCompleted, with: true)
    }
    
    /// 请求失败的统一结果处理
    /// - Parameter request: 发送的请求
    /// - Parameter error: 请求的错误信息，如果存在
    private func requested(_ request: MRequest, didFailWith error: NetworkError) {
        request.accessoriesStateChange(.willComplete, with: false)
        
        request.delegate?.requestFailed(request: request, with: error)
        request.failedHandler?(request, error)
        
        request.delegate?.requestCompleted(request: request, isSuccess: false)
        request.completedHandler?(request, false)
        
        request.accessoriesStateChange(.didCompleted, with: false)
    }
}

//
//  NetworkAgent.swift
//  Alamofire
//
//  Created by Zed on 2019/10/29.
//

import UIKit
import Alamofire


class NetworkAgent {
    typealias MRequest = MoeNetwork.Request
    typealias ARequest = Alamofire.Request
    
    private let config = NetworkConfig.shared
    private let allStatuCodes = IndexSet(integersIn: 100...500)
    private var manager: Alamofire.SessionManager
//    private var requestsRecord = [Int: MRequest]()
    
    ///  Get the shared instance
    static public let shared = NetworkAgent()
    private init(){
        manager = SessionManager(configuration: config.sessionConfiguration)
        manager.startRequestsImmediately = false
    }
    
    ///  Add request to session and start it
    internal func add(request: Request) {
        if let customRequest = request.generateCustomURLRequest() {
        // request构建了自定义请求，直接发送
            ///  Todo: 自定义请求功能待完成
            let dataRequest: DataRequest = manager.request(customRequest)
            dataRequest.resume()
        } else {
        //  依据request的相关参数， 生成匹配的请求
            let generatedDataRequest = buildNetworkRequest(for: request)
//            if let taskId = generatedDataRequest.task?.taskIdentifier {
//                requestsRecord[taskId] = request
//            }
            generatedDataRequest.resume()
        }
    }
    
    private func buildNetworkRequest(for request: MRequest) -> DataRequest {
        let method = buildUnderlyingMethod(for: request)
        
        switch method {
        case .get:
            return buildUnderlyingRequest(request: request)
        case .post:
            let urlRequest = buildURLRequest(for: request)
            return manager.request(urlRequest)
                .response(responseSerializer: buildUnderlyingSerializer(for: request))
            { [weak self] (response) in
                // 回调代码在主线程中被执行
                self?.handleUnderlyingResponse(response, for: request)
            }
        default:
            print("待完善")
            return buildUnderlyingRequest(request: request)
        }
    }
}


// MARK: Build parameter
extension NetworkAgent {
    ///  Build url of request
    private func buildURL(for request: MRequest) -> URL {
        let detailURL = URL(string: request.path())
        
        if detailURL != nil, detailURL?.host != nil, detailURL?.scheme != nil {
            let url = URL(string: request.path())
            NetworkHelper.shared.buildURLAssert(condition: url == nil)
            return url!
        }
        
        ///  Todo: 执行URL参数注入
        
        var baseURL: URL?
        if request.baseURL().absoluteString.count > 0 {
            baseURL = request.baseURL()
        } else {
            baseURL = config.baseURL
        }
        let url = baseURL?.appendingPathComponent(request.path(), isDirectory: false)
        NetworkHelper.shared.buildURLAssert(condition: url != nil)
        return url!
    }
    
    private func buildURLRequest(for request: MRequest) -> URLRequest {
        var urlReq = URLRequest(url: request.url)
        urlReq.httpMethod = request.method().rawValue
        urlReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if request.requiredAuthorization() {
            urlReq.setValue(request.authenticationToken(), forHTTPHeaderField: "Authorization")
        }
        if let body = request.body() {
            urlReq.httpBody = body.data(using: .utf8, allowLossyConversion: false)
        }
        
        return urlReq
    }
}


// MARK: Build underlying dependence
extension NetworkAgent {
    internal func buildUnderlyingMethod(for request: MRequest) -> HTTPMethod {
        switch request.method() {
        case .get:
            return HTTPMethod.get
        case .post:
            return HTTPMethod.post
        case .put:
            return HTTPMethod.put
        case .delete:
            return HTTPMethod.delete
        case .head:
            return HTTPMethod.head
        case .patch:
            return HTTPMethod.patch
        }
    }
    
    private func buildUnderlyingSerializer(for request: MRequest) -> DataResponseSerializer<Any> {
        switch request.serializerType() {
        case .xmlParser:
            return DataRequest.propertyListResponseSerializer(options: [])
        default:
            return DataRequest.jsonResponseSerializer(options: .allowFragments)
        }
    }
    
    private func buildUnderlyingRequest(request: MRequest) -> DataRequest {
        let url = buildURL(for: request)
        let method = buildUnderlyingMethod(for: request)
        let parameter = request.addtionalParameter()
        let serializer = buildUnderlyingSerializer(for: request)
        
        let dataRequest = manager.request(url, method: method,
                                      parameters: parameter,
                                      encoding: URLEncoding.default,
                                      headers: nil)
        
        dataRequest.response(responseSerializer: serializer) { [weak self] (response) in
            // 回调代码在主线程中被执行
            self?.handleUnderlyingResponse(response, for: request)
        }
        return dataRequest
    }
    
    private func handleUnderlyingResponse(_ response: DataResponse<Any>, for request: MRequest) {
        let result = response.result
        
        guard result.isSuccess == true else {
            let startDate = Date(timeIntervalSinceReferenceDate: response.timeline.requestStartTime)
            let error = NetworkError(code: -1,
                                     message: "Unknow error",
                                     requstURL: response.request?.url,
                                     requestStartTime: startDate)
            requested(request, didFailWith: error)
            return
        }
        
        requested(request, didSuccessedWith: response)
    }
}


// MARK: Result handle
extension NetworkAgent {
    private func requested(_ request: MRequest, didSuccessedWith response: DataResponse<Any>) {
        ///  Todo: 请求完成后， 执行 Filter & Accessory
        
        // 回调已经在主纯程中执行
        request.delegate?.requestSuccessed(request: request)
        request.successedHandler?(request)
        
        request.delegate?.requestCompleted(request: request, isSuccess: true)
        request.completedHandler?(request, true)
    }
    
    private func requested(_ request: MRequest, didFailWith error: NetworkError) {
        request.delegate?.requestFailed(request: request, with: error)
        request.failedHandler?(request, error)
        
        request.delegate?.requestCompleted(request: request, isSuccess: false)
        request.completedHandler?(request, false)
    }
}

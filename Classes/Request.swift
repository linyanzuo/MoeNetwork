//
//  Request.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import UIKit
import HandyJSON


public protocol RequestResultHandle {
    func requestSuccessed(request: Request, with response: Response)
    func requestFailed(request: Request, with error: NetworkError)
    func requestCompleted(request: Request, isSuccess: Bool)
}
public extension RequestResultHandle {
    func requestCompleted(request: Request, isSuccess: Bool) {}
}


public typealias SuccessHandler = (_ request: Request, _ response: Response) -> Void
public typealias FailHandler = (_ request: Request, _ error: NetworkError) -> Void
public typealias CompletionHandler = (_ request: Request, _ isSuccess: Bool) -> Void


public enum Serializer {
    case http
    case json
    /// 暂未测试
    case xml
    case handyJson(ResponseData.Type)
    
    public var responseType: ResponseData.Type? {
        switch self {
        case .handyJson(let type):
            return type
        default:
            return nil
        }
    }
}


open class Request: NSObject {
    public enum Method: String {
        case get    = "GET"
        case post   = "POST"
        case put    = "PUT"
        case delete = "DELETE"
        case head   = "HEAD"
        case patch  = "PATCH"
    }

    // MARK: Object Life Cycle
    
    open var customBody: String?
    open var addtionalSubpath: [String]?
    open var addtionalParameter: [String: Any]?
    open var addtionalHeader: [String: String]?
    
    /// Todo: 待删除
    var url: URL {
        get { return URL(string: "http://47.56.83.245:8400/v2/w")!.appendingPathComponent(path()) }
    }
    
    ///  负责处理请求结果的代理对象
    ///  通过代理或回调的方式均可处理请求结果，两者选一即可
    ///  若代理与回调的方式均被实现，则先触发代理方法，后触发回调代码块
    internal var delegate: RequestResultHandle?
    
    ///  请求成功的回调处理，另请参阅`delegate`
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var successedHandler: SuccessHandler?
    ///  请求失败的回调处理，另请参阅`delegate`
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var failedHandler: FailHandler?
    ///  请求完成的回调处理，不管成功或失败都会回调，
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var completedHandler: CompletionHandler?

    public required override init() {
        super.init()
    }

    // MARK: Methods that subclass should override
    
    /// The URL host of request. This should only contain the host part of URL.
    /// Subclass should override this method to return the host of request. And have no need to call super
    open func baseURL() -> URL? {
        return nil
    }

    /// The URL path of request. This should only contain the path part of URL
    /// Subclass should override this method to return the path of request. And have no need to call super
    open func path() -> String {
        return "Subclass must override this method, then return the path of request"
    }

    /// HTTP(s) request method, default is `GET`
    /// Subclass can override this method to return other request method
    open func method() -> Method {
        return .get
    }

    /// Add Token Authorizaton for request header, default is `False`
    /// Subclass can override thie method to return `True` if it needed
    open func requiredAuthorization() -> Bool {
        return false
    }

    /// Notifies that request is about to be send
    /// Subclass can override this method to do something like show loading view
    open func requestWillSend(){
    }

    /// Notifies that request is about to be send
    /// Subclass can override this method to do something like hide loading view
    open func requestDidFinish(isSuccess: Bool) {
    }
    
    open func generateCustomURLRequest() -> URLRequest? {
        return nil
    }
    
    open func serializer() -> Serializer {
        return .json
    }
    
    open func start(withDelegate delegate: RequestResultHandle) {
        self.delegate = delegate
        NetworkAgent.shared.add(request: self)
    }
    
    open func start(with successedHandler: SuccessHandler?,
                    failedHandler: FailHandler? ) {
        return start(with: successedHandler, failedHandler: failedHandler, completedHandler: nil)
    }
    
    open func start(with successedHandler: SuccessHandler?,
                    failedHandler: FailHandler?,
                    completedHandler: CompletionHandler?)
    {
        /** `optional`闭包参数默认就是`@escaping`
         Basically, @escaping is valid only on closures in function parameter position. The noescape-by-default rule only applies to these closures at function parameter position, otherwise they are escaping. Aggregates, such as enums with associated values (e.g. Optional), tuples, structs, etc., if they have closures, follow the default rules for closures that are not at function parameter position, i.e. they are escaping.
         */
        self.successedHandler = successedHandler
        self.failedHandler = failedHandler
        self.completedHandler = completedHandler
        NetworkAgent.shared.add(request: self)
    }
}


// MARK: Methods to send request
public extension Request {
    func send(body: String, success: SuccessHandler?, fail: FailHandler?, completion: CompletionHandler?) {
        self.customBody = body
        self.start(with: success, failedHandler: fail, completedHandler: completion)
    }
    
    func send(body: String, success: SuccessHandler?, fail: FailHandler?) {
        return send(body: body, success: success, fail: fail, completion: nil)
    }

    func send(parameters: [String: Any]?,
              success: SuccessHandler?,
              fail: FailHandler?,
              completion: CompletionHandler?)
    {
        self.addtionalParameter = parameters
        self.start(with: success, failedHandler: fail, completedHandler: completion)
    }
    
    func send(parameters: [String: Any]?, success: SuccessHandler?, fail: FailHandler?) {
        return send(parameters: parameters, success: success, fail: fail, completion: nil)
    }

    func send(subpath: [String]?, success: SuccessHandler?, fail: FailHandler?, completion: CompletionHandler?) {
        self.addtionalSubpath = subpath
        self.start(with: success, failedHandler: fail, completedHandler: completion)
    }
    
    func send(subpath: [String]?, success: SuccessHandler?, fail: FailHandler?) {
        return send(subpath: subpath, success: success, fail: fail, completion: nil)
    }
}

//
//  Request.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import UIKit


public protocol RequestResultHandle {
    func requestSuccessed(request: Request)
    func requestFailed(request: Request, with error: NetworkError)
    func requestCompleted(request: Request, isSuccess: Bool)
}
public extension RequestResultHandle {
    func requestCompleted(request: Request, isSuccess: Bool) {}
}


public typealias SuccessHanlder = (_ request: Request) -> Void
public typealias FailHanlder = (_ request: Request, _ error: NetworkError) -> Void
public typealias CompletionHanlder = (_ request: Request, _ isSuccess: Bool) -> Void


open class Request: NSObject {
    public enum Method: String {
        case get    = "GET"
        case post   = "POST"
        case put    = "PUT"
        case delete = "DELETE"
        case head   = "HEAD"
        case patch  = "PATCH"
    }
    
    public enum SerializerType {
        case http
        case json
        case xmlParser
    }

    // MARK: Object Life Cycle
    var url: URL {
        get { return baseURL().appendingPathComponent(path()) }
    }
    
    ///  负责处理请求结果的代理对象
    ///  通过代理或回调的方式均可处理请求结果，两者选一即可
    ///  若代理与回调的方式均被实现，则先触发代理方法，后触发回调代码块
    internal var delegate: RequestResultHandle?
    
    ///  请求成功的回调处理，另请参阅`delegate`
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var successedHandler: SuccessHanlder?
    ///  请求失败的回调处理，另请参阅`delegate`
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var failedHandler: FailHanlder?
    ///  请求完成的回调处理，不管成功或失败都会回调，
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var completedHandler: CompletionHanlder?

    public required override init() {
        super.init()
    }

    // MARK: Methods that subclass should override
    
    /// The URL host of request. This should only contain the host part of URL.
    /// Subclass should override this method to return the host of request. And have no need to call super
    open func baseURL() -> URL {
        return URL(string: "Subclass must override this method, which return the host of request")!
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

    /// The authentication token that add to the header of request
    /// Subclasss must override this method to return the token for authorication. Have no need to call super
    open func authenticationToken() -> String {
        return "Subclasss must override this method, then return the authorication token"
    }

    /// Class use to deserialize HTTP(s) response
    /// Subclass must override this method to return a related class
    open func responseType() -> Response.Type {
        return Response.self
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
    
    open func addtionalParameter() -> Dictionary<String, Any>? {
        return nil
    }
    
    open func serializerType() -> SerializerType {
        return .json
    }
    
    open func body() -> String? {
        return nil
    }
    
    open func start(withDelegate delegate: RequestResultHandle) {
        self.delegate = delegate
        NetworkAgent.shared.add(request: self)
    }
    
    open func start(withHandler successedHandler: @escaping SuccessHanlder,
                    failedHandler: @escaping FailHanlder,
                    completedHandler: @escaping CompletionHanlder)
    {
        self.successedHandler = successedHandler
        self.failedHandler = failedHandler
        self.completedHandler = completedHandler
        NetworkAgent.shared.add(request: self)
    }
}


// MARK: Methods to send request
public extension Request {
    func send(body: String, success: SuccessClosure?, fail: FailClosure?) {
        Network.request(self, body: body, success: success, fail: fail, completion: nil)
    }

    func send(body: String, success: SuccessClosure?, fail: FailClosure?, completion: CompletionClosure?) {
        Network.request(self, body: body, success: success, fail: fail, completion: completion)
    }

    func send(parameters: [String: Any]?, success: SuccessClosure?, fail: FailClosure?) {
        Network.request(self, parameters: parameters, success: success, fail: fail)
    }

    func send(parameters: [String: Any]?, success: SuccessClosure?, fail: FailClosure?, completion: CompletionClosure?) {
        Network.request(self, parameters: parameters, success: success, fail: fail, completion: completion)
    }

    func send(subpath: [String]?, success: SuccessClosure?, fail: FailClosure?) {
        Network.request(self, subpaths: subpath, success: success, fail: fail, completion: nil)
    }

    func send(subpath: [String]?, success: SuccessClosure?, fail: FailClosure?, completion: CompletionClosure?) {
        Network.request(self, subpaths: subpath, success: success, fail: fail, completion: completion)
    }
}

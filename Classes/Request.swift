//
//  Request.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import UIKit


open class Request: NSObject {
    public enum Method: String {
        case get    = "GET"
        case post   = "POST"
        case put    = "PUT"
        case delete = "DELETE"
        //        case head   = "HEAD"
        //        case patch  = "PATCH"
    }

    // MARK: Object Lide Cycle
    var url: URL {
        get { return baseURL().appendingPathComponent(path()) }
    }

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

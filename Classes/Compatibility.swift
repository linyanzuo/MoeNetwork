//
//  Compatibility.swift
//  Alamofire
//
//  Created by Zed on 2019/11/13.
//

import Foundation


// MARK: `1.0`版本的`Request`兼容
public typealias SuccessClosure = (_ data: HandyObject) -> Void
public typealias FailClosure = (_ error: NetworkError) -> Void
public typealias CompletionClosure = (_ isSuccessful: Bool) -> Void


public extension Request {
    func send(body: String, success: SuccessClosure?, fail: FailClosure?) {
        return send(body: body, success: success, fail: fail, completion: nil)
    }

    func send(body: String,
              success: SuccessClosure?,
              fail: FailClosure?,
              completion: CompletionClosure?)
    {
        self.customBody = body
        commonStart(success: success, fail: fail, completion: completion)
    }

    func send(parameters: [String: Any]?, success: SuccessClosure?, fail: FailClosure?) {
        return send(parameters: parameters, success: success, fail: fail, completion: nil)
    }

    func send(parameters: [String: Any]?,
              success: SuccessClosure?,
              fail: FailClosure?,
              completion: CompletionClosure?)
    {
        self.addtionalParameter = parameters
        commonStart(success: success, fail: fail, completion: completion)
    }

    func send(subpath: [String]?, success: SuccessClosure?, fail: FailClosure?) {
        send(subpath: subpath, success: success, fail: fail, completion: nil)
    }

    func send(subpath: [String]?,
              success: SuccessClosure?,
              fail: FailClosure?,
              completion: CompletionClosure?)
    {
        self.addtionalSubpath = subpath
        commonStart(success: success, fail: fail, completion: completion)
    }
    
    func commonStart(success: SuccessClosure?,
                     fail: FailClosure?,
                     completion: CompletionClosure?)
    {
        self.start(with: { (request, response) in
            guard let handyObj = response.handyObject else {
                let error = NetworkError(code: -1,
                                         message: "HandyJSON对象序列化失败",
                                         requstURL: request.url,
                                         requestStartTime: response.startTime,
                                         requestCompletedTime: response.completedTime)
                fail?(error)
                return
            }
            success?(handyObj)
        }, failedHandler: { (request, error) in
            fail?(error)
        }) { (request, isSuccess) in
            completion?(isSuccess)
        }
    }
    
// MARK: --
//    func send(body: String, success: SuccessHandler?, fail: FailHandler?, completion: CompletionHandler?) {
//        self.customBody = body
//        self.start(with: success, failedHandler: fail, completedHandler: completion)
//    }
//
//    func send(body: String, success: SuccessHandler?, fail: FailHandler?) {
//        return send(body: body, success: success, fail: fail, completion: nil)
//    }
//
//    func send(parameters: [String: Any]?,
//              success: SuccessHandler?,
//              fail: FailHandler?,
//              completion: CompletionHandler?)
//    {
//        self.addtionalParameter = parameters
//        self.start(with: success, failedHandler: fail, completedHandler: completion)
//    }
//
//    func send(parameters: [String: Any]?, success: SuccessHandler?, fail: FailHandler?) {
//        return send(parameters: parameters, success: success, fail: fail, completion: nil)
//    }
//
//    func send(subpath: [String]?, success: SuccessHandler?, fail: FailHandler?, completion: CompletionHandler?) {
//        self.addtionalSubpath = subpath
//        self.start(with: success, failedHandler: fail, completedHandler: completion)
//    }
//
//    func send(subpath: [String]?, success: SuccessHandler?, fail: FailHandler?) {
//        return send(subpath: subpath, success: success, fail: fail, completion: nil)
//    }
}

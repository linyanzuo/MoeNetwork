//
//  Compatibility.swift
//  Alamofire
//
//  Created by Zed on 2019/11/13.
//

import Foundation

    
// MARK: --
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

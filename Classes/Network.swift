//
//  Network.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import UIKit
import Alamofire
import HandyJSON


public typealias SuccessClosure = (_ data: Response) -> Void
public typealias FailClosure = (_ error: NetworkError) -> Void
public typealias CompletionClosure = (_ isSuccessful: Bool) -> Void


/// Network Engine
class Network: NSObject {
    static let sessionManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        return Alamofire.SessionManager(configuration: configuration)
    }()

    static func request(_ request: Request,
                        subpaths: [String]?,
                        success: SuccessClosure?,
                        fail: FailClosure?,
                        completion: CompletionClosure? = nil)
    {
        let encoding = NetworkAgent.shared.buildUnderlyingEncoding(request: request)
        let method = NetworkAgent.shared.buildUnderlyingMethod(for: request)
        let header = NetworkAgent.shared.buildHeader(request: request)

        var url = request.url
        if subpaths != nil {
            for path in subpaths! {
                url = url.appendingPathComponent(path)
            }
        }

        request.requestWillSend()
        sessionManager.request(url, method: method, parameters: nil, encoding: encoding, headers: header).responseJSON { (response) in
//            let serializer = request.serializer().responseType ?? ResponseData.self
//            let isSuccessful = NetworkAgent.shared.responseHandle(response: response,
//                                                                  responseType: serializer,
//                                                                  success: success,
//                                                                  fail: fail)
//            request.requestDidFinish(isSuccess: isSuccessful)
//            completion?(isSuccessful)
        }
    }
}

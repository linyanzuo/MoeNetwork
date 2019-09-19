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
public typealias FailClosure = (_ error: Error) -> Void
public typealias CompletionClosure = (_ isSuccessful: Bool) -> Void


/// Network Engine
class Network: NSObject {
    static func request(_ request: Request,
                        body: String,
                        success: SuccessClosure?,
                        fail: FailClosure?,
                        completion: CompletionClosure? = nil)
    {
        var req = URLRequest(url: request.url)
        req.httpMethod = self.method(request: request).rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if request.requiredAuthorization() {
            let token = request.authenticationToken()
            req.setValue(token, forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body.data(using: .utf8, allowLossyConversion: false)

        request.requestWillSend()
        Alamofire.request(req).responseJSON { (response) in
            let isSuccessful = responseHandle(response: response,
                                              responseType: request.responseType(),
                                              success: success,
                                              fail: fail)
            request.requestDidFinish(isSuccess: isSuccessful)
            completion?(isSuccessful)
        }
    }

    static func request(_ request: Request,
                        parameters: [String: Any]?,
                        success: SuccessClosure?,
                        fail: FailClosure?,
                        completion: CompletionClosure? = nil)
    {
        let encoding = self.encoding(request: request)
        let header = self.header(request: request)
        let method = self.method(request: request)

        request.requestWillSend()
        Alamofire.request(request.url, method: method, parameters: parameters, encoding: encoding, headers: header).responseJSON { (response) in
            let isSuccessful = responseHandle(response: response,
                                              responseType: request.responseType(),
                                              success: success,
                                              fail: fail)
            request.requestDidFinish(isSuccess: isSuccessful)
            completion?(isSuccessful)
        }
    }

    static func request(_ request: Request,
                        subpaths: [String]?,
                        success: SuccessClosure?,
                        fail: FailClosure?,
                        completion: CompletionClosure? = nil)
    {
        let encoding = self.encoding(request: request)
        let header = self.header(request: request)
        let method = self.method(request: request)

        var url = request.url
        if subpaths != nil {
            for path in subpaths! {
                url = url.appendingPathComponent(path)
            }
        }

        request.requestWillSend()
        Alamofire.request(url, method: method, parameters: nil, encoding: encoding, headers: header).responseJSON { (response) in
            let isSuccessful = responseHandle(response: response,
                                              responseType: request.responseType(),
                                              success: success,
                                              fail: fail)
            request.requestDidFinish(isSuccess: isSuccessful)
            completion?(isSuccessful)
        }
    }


    static private func responseHandle(response: DataResponse<Any>,
                                       responseType: HandyJSON.Type,
                                       success: SuccessClosure?,
                                       fail: FailClosure?,
                                       completion: CompletionClosure? = nil) -> Bool
    {
        let result: Result = response.result

        // -- Network connection check
        guard result.isSuccess == true else {
            let errMsg = AssetHelper.localizedString(key: "check_connection")
            NetworkHelper.shared.alertDebugError(errMsg)
            return false
        }
        // -- Response data format check
        guard let dict = result.value as? [String: Any] else {
            let errMsg = AssetHelper.localizedString(key: "response_format")
            NetworkHelper.shared.alertDebugError(errMsg)
            return false
        }
        // -- Response Data Deserialize
        guard let response = responseType.deserialize(from: dict) as? Response else {
            let errMsg = AssetHelper.localizedString(key: "deserialize_json")
            NetworkHelper.shared.alertDebugError(errMsg)
            return false
        }
        // -- Error Code Check
        let errorCode = response.statusCode()
        guard errorCode == 0 else {
            let errMsg = AssetHelper.localizedString(key: "get_error_code")
            MLog(errMsg)
            let errorMessage = response.statusMessage()
            #if DEBUG
            if NetworkHelper.shared.checkHttpErrorCode(errorCode: errorCode, errorMessage: errorMessage) { return false }
            #endif
            if NetworkHelper.shared.checkServerErrorCode(errorCode: errorCode, errorMessage: errorMessage) { return false }

            fail?(Error(code: errorCode, message: errorMessage))
            return false
        }
        success?(response)
        return true
    }
}


// MARK: Request Config
extension Network {
    private static func header(request: Request) -> [String: String] {
        var result = Dictionary<String, String>()

        if request.requiredAuthorization() == true {
            result["Authorization"] = request.authenticationToken()
        }
        return result
    }

    private static func encoding(request: Request) -> ParameterEncoding {
        switch request.method() {
        case .put:
            return JSONEncoding.default
        case .post:
            return JSONEncoding.default
        default:
            return URLEncoding.default
        }
    }

    private static func method(request: Request) -> HTTPMethod {
        switch request.method() {
        case .get:
            return HTTPMethod.get
        case .post:
            return HTTPMethod.post
        case .put:
            return HTTPMethod.put
        case .delete:
            return HTTPMethod.delete
        }
    }
}

//
//  Network.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import UIKit
import Alamofire
import HandyJSON
import MoeUI


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

        Alamofire.request(req).responseJSON { (response) in
            let isSuccessful = responseHandle(response: response,
                                              responseType: request.responseType(),
                                              success: success,
                                              fail: fail)
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

        Alamofire.request(request.url, method: method, parameters: parameters, encoding: encoding, headers: header).responseJSON { (response) in

            let isSuccessful = responseHandle(response: response,
                                              responseType: request.responseType(),
                                              success: success,
                                              fail: fail)
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

        Alamofire.request(url, method: method, parameters: nil, encoding: encoding, headers: header).responseJSON { (response) in
            let isSuccessful = responseHandle(response: response,
                                              responseType: request.responseType(),
                                              success: success,
                                              fail: fail)
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
            let errMsg = "ERROR: Request fail, please check network connection"
            MLog(errMsg)
            NotificationCenter.default.post(name: Notification.Name.ConnectionState.NoNetwork,
                                            object: self,
                                            userInfo: [Notification.Key.HintMessage: errMsg])
            return false
        }
        // -- Response data format check
        guard let dict = result.value as? [String: Any] else {
            globalAlert("ERROR: Response data parse fail, it's not json data. Please contact to server")
            return false
        }
        // -- Response Data Deserialize
        guard let response = responseType.deserialize(from: dict) as? Response else {
            globalAlert("Request Success, but deserialize json data fail. Please check is the `responseType` of request right or if the properties of response match")
            return false
        }
        // -- Error Code Check
        let errorCode = response.statusCode()
        guard errorCode == 0 else {
            MLog("Request Success, but get `Error Status Code`")
            let errorMessage = response.statusMessage()
            #if DEBUG
            if httpErrorCodeHandler(errorCode: errorCode, errorMessage: errorMessage) { return false }
            #endif
            if statusCodeHandler(errorCode: errorCode, errorMessage: errorMessage) { return false }

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


// MARK: Error Code Handle
extension Network {
    private static func httpErrorCodeHandler(errorCode: Int, errorMessage: String) -> Bool {
        let bundle = Bundle(for: self.classForCoder())
        guard let url = bundle.url(forResource: "Http_Error_Code", withExtension: "plist") else {
            globalAlert("Load Http_Error_Code fail, please check the url or `Http_Error_Code.plst`")
            return false
        }
        guard let httpErrorCodeTable = NSDictionary(contentsOf: url) else {
            globalAlert("File format error, Http_Error_Code.plist should be Dictionary")
            return false
        }
        guard let httpErrorCodes = httpErrorCodeTable.allKeys as? [String] else {
            globalAlert("There is no http error code in Http_Error_Code table")
            return false
        }

        for httpErrorCode in httpErrorCodes {
            if Int(httpErrorCode) == errorCode, let errMsg = httpErrorCodeTable.value(forKey: httpErrorCode) as? String {
                globalAlert(errMsg)
                return true
            }
        }
        return false
    }

    private static func statusCodeHandler(errorCode: Int, errorMessage: String) -> Bool {
        var name: Notification.Name? = nil
        switch errorCode {
        case 41001:
            name = Notification.Name.Network.TokenMissing
        case 41002:
            name = Notification.Name.Network.TokenInvalidate
        case 41003:
            name = Notification.Name.Network.PermissionDenied
        default:
            MLog("Unhandle Status Code: \(errorCode);\n\(errorMessage)")
        }

        guard name != nil else { return false }
        NotificationCenter.default.post(name: name!,
                                        object: self,
                                        userInfo: [Notification.Key.HintMessage: errorMessage])
        return true
    }
}


// Mark: Message Alert
extension Network {
    private static func globalAlert(_ message: String) {
        MLog(message)
//        MoeUI.alertError(with: message)
    }
}

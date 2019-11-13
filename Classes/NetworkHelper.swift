//
//  NetworkHelper.swift
//  Alamofire
//
//  Created by Zed on 2019/9/17.
//

import Foundation
import Alamofire


public class NetworkHelper {
    public enum ConnectionState: String{
        case wifi = "org.moe.network.connectionState.wifi"
        case mobile = "org.moe.network.connectionState.mobile"
        case noNetwork = "org.moe.network.connection.noNetwork"
        case unKnow = "org.moe.network.connectionState.unkonw"
    }

    static public let shared = NetworkHelper()
    private init(){}

    var reachability: NetworkReachabilityManager? = NetworkReachabilityManager()
}


// MARK: Reachability
extension NetworkHelper {
    /// Starts listening for changes in network reachability status.
    /// Post notification named `ConnectionState` if status change
    public func startListening() {
        reachability?.listener = { status in
            var state: ConnectionState = .noNetwork
            if self.reachability?.isReachable ?? false {
                switch status {
                case .notReachable:
                    state = .noNetwork
                case .unknown:
                    state = .unKnow
                case .reachable(.ethernetOrWiFi):
                    state = .wifi
                case .reachable(.wwan):
                    state = .mobile
                }
            }
            let userInfo = ["ConnectionState" : state]
            NotificationCenter.default.post(name: Notification.Name.Network.ConnectionState, object: self, userInfo: userInfo)
        }
        reachability?.startListening()
    }

    /// Stops listening for changes in network reachability status.
    public func stopListening() {
        reachability?.stopListening()
    }
}


// MARK: Error Code Handle
extension NetworkHelper {
    internal func checkHttpErrorCode(errorCode: Int, errorMessage: String) -> Bool {
        let assetBundle = AssetHelper.assetBundle()
        let language = Bundle.main.preferredLocalizations.first

        guard let url = assetBundle.url(forResource: "Http_Error_Code", withExtension: "plist", subdirectory: nil, localization: language) else {
            showDevError("Load Http_Error_Code fail, please check the url or `Http_Error_Code.plst`")
            return false
        }
        guard let httpErrorCodeTable = NSDictionary(contentsOf: url) else {
            showDevError("File format error, Http_Error_Code.plist should be Dictionary")
            return false
        }
        guard let httpErrorCodes = httpErrorCodeTable.allKeys as? [String] else {
            showDevError("There is no http error code in Http_Error_Code table")
            return false
        }

        for httpErrorCode in httpErrorCodes {
            if Int(httpErrorCode) == errorCode, let errMsg = httpErrorCodeTable.value(forKey: httpErrorCode) as? String {
                self.showDevError(errMsg)
                return true
            }
        }
        return false
    }

    internal func checkServerErrorCode(errorCode: Int, errorMessage: String) -> Bool {
        var name: Notification.Name? = nil
        switch errorCode {
        case 41001:
            name = Notification.Name.Network.TokenMissing
        case 41002:
            name = Notification.Name.Network.TokenInvalidate
        case 41003:
            name = Notification.Name.Network.PermissionDenied
        default:
            showDevError("Unhandle Status Code: \(errorCode);\n\(errorMessage)")
        }

        guard name != nil else { return false }
        NotificationCenter.default.post(name: name!,
                                        object: self,
                                        userInfo: [Notification.Key.HintMessage: errorMessage])
        return true
    }
}


// MARK: Debug error
extension NetworkHelper {
    internal func showDevError(_ message: String) {
        MLog(message)
        NotificationCenter.default.post(name: Notification.Name.Network.DebugError,
                                        object: self,
                                        userInfo: [Notification.Key.HintMessage: message])
    }

    internal func showError(_ message: String) {
        NotificationCenter.default.post(name: Notification.Name.Network.AlertError,
                                        object: self,
                                        userInfo: [Notification.Key.HintMessage: message])
    }
    
    internal static func buildURLAssert(condition: Bool) {
        assert(condition, "Build URL Fail, please check `baseURL` and `path` of request")
    }
}


// MARK: Pod Asset Helper
class AssetHelper: NSObject {
    internal static func assetBundle() -> Bundle {
        let frameworkBundle = Bundle(for: self.classForCoder())
        var assetBundle = frameworkBundle
        if let targetBundleUrl = frameworkBundle.url(forResource: "MoeNetwork", withExtension: "bundle"),
            let targetBundle = Bundle(url: targetBundleUrl)
        { assetBundle = targetBundle }
        return assetBundle
    }

    internal static func localizedString(key: String) -> String {
        let assetBundle = self.assetBundle()
        let table = "Error_Hint"
        return assetBundle.localizedString(forKey: key, value: "", table: table)
    }
}

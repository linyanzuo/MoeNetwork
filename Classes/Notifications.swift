//
//  Notifications.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import Foundation


extension Notification.Name {
    public struct Network {
        public static let TokenMissing = Notification.Name(rawValue: "org.moe.network.notification.name.network.tokenMissing")
        public static let TokenInvalidate = Notification.Name(rawValue: "org.moe.network.notification.name.network.tokenInvalidate")
        public static let PermissionDenied = Notification.Name(rawValue: "org.moe.network.notification.name.network.permissionDenied")
    }
    public struct ConnectionState {
        public static let Wifi = Notification.Name(rawValue: "org.moe.network.notification.name.networkState.wifi")
        public static let Mobile = Notification.Name(rawValue: "org.moe.network.notification.name.networkState.mobile")
        public static let NoNetwork = Notification.Name(rawValue: "org.moe.network.notification.name.network.noNetwork")
    }
}


extension Notification {
    public struct Key {
        public static let StatusCode = "org.moe.notification.name.statusCode"
        public static let HintMessage = "org.moe.notification.name.hintMessage"
    }
}


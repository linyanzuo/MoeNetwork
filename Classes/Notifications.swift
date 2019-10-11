//
//  Notifications.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import Foundation


extension Notification.Name {
    public struct Network {
        public static let ConnectionState = Notification.Name(rawValue: "org.moe.network.notification.name.network.connectionState")
        public static let DebugError = Notification.Name(rawValue: "org.moe.network.notification.name.network.debugError")
        public static let AlertError = Notification.Name(rawValue: "org.moe.network.notification.name.network.alertError")
        public static let TokenMissing = Notification.Name(rawValue: "org.moe.network.notification.name.network.tokenMissing")
        public static let TokenInvalidate = Notification.Name(rawValue: "org.moe.network.notification.name.network.tokenInvalidate")
        public static let PermissionDenied = Notification.Name(rawValue: "org.moe.network.notification.name.network.permissionDenied")
    }
}


extension Notification {
    public struct Key {
        public static let StatusCode = "org.moe.notification.name.statusCode"
        public static let HintMessage = "org.moe.notification.name.hintMessage"
    }
}


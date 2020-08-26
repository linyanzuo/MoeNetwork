//
//  Notifications.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//
/**
 【通知定义】
 */

import Foundation


extension Notification.Name {
    public struct Network {
        public static let ConnectionState = Notification.Name(rawValue: "com.moemone.network.notification.name.network.connectionState")
        public static let DebugError = Notification.Name(rawValue: "com.moemone.network.notification.name.network.debugError")
        public static let AlertError = Notification.Name(rawValue: "com.moemone.network.notification.name.network.alertError")
        public static let TokenMissing = Notification.Name(rawValue: "com.moemone.network.notification.name.network.tokenMissing")
        public static let TokenInvalidate = Notification.Name(rawValue: "com.moemone.network.notification.name.network.tokenInvalidate")
        public static let PermissionDenied = Notification.Name(rawValue: "com.moemone.network.notification.name.network.permissionDenied")
    }
}


extension Notification {
    public struct Key {
        public static let StatusCode = "com.moemone.notification.name.statusCode"
        public static let HintMessage = "com.moemone.notification.name.hintMessage"
    }
}


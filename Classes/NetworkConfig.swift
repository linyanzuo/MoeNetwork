//
//  NetworkConfig.swift
//  MoeNetwork
//
//  Created by Zed on 2019/10/29.
//

import Foundation


//public protocol URLInject {
//    /// 在此方法中向请求的URL注入新的参数
//    /// - Parameter url: 请求的URL地址
//    /// - Parameter request: 要发送的请求
//    func injectURL(_ url: URL, to request: Request)
//}


/// 全局配置
public class NetworkConfig {
    
    /// 请求的基础地址，如`host`、`host/path`
    public var baseURL: URL?
    /// 请求的超时时间，默认为10秒
    public var requestTimeOut: TimeInterval = 10.0
    /// 用户身份验证的Token值
    public var authenticationToken: String?
    /// 添加额外的全局参数
    open var addtionalParameter: [String: Any]?
    /// 添加额外的全局报头域
    open var addtionalHeader: [String: String]?

    
    /// 用于初始化`HttpSessionManager`的会话配置实例
    internal var sessionConfiguration: URLSessionConfiguration
    
    /// 获取共享实例
    static public let shared = NetworkConfig()
    private init() {
        sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 10.0
    }
    
    // MARK: URL注入
//    private lazy var injecters: [URLInject] = {
//        return Array<URLInject>()
//    }()
//
//    public func addInjecter(_ injecter: URLInject) {
//        /// Todo: 过滤重复的注入器
////        let isRepeat = injecters.contains { (item) -> Bool in
////            return item == injecter
////        }
//        injecters.append(injecter)
//    }
//
//    public func clearInjecter() {
//        injecters.removeAll()
//    }
}

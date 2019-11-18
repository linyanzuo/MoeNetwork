//
//  NetworkConfig.swift
//  MoeNetwork
//
//  Created by Zed on 2019/10/29.
//

import Foundation


/// 全局配置
public class NetworkConfig {
    
    /// 请求的基础地址，如`host`、`host/path`
    public var baseURL: URL?
    /// 请求的超时时间，默认为10秒
    public var requestTimeOut: TimeInterval = 10.0
    /// 添加额外的全局参数
    open var addtionalParameter: [String: Any]?
    /// 添加额外的全局报头域
    open var addtionalHeader: [String: String]?

    /// 用于初始化`HttpSessionManager`的会话配置实例
    internal var sessionConfiguration: URLSessionConfiguration
    
    /// 记录请求注入器的数组
    private(set) var injectors: [RequestInjection]?
    /// 记录请求附件的数组
    private(set) var accessories: [RequestAccessory]?
    
    /// 获取共享实例
    static public let shared = NetworkConfig()
    private init() {
        sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 10.0
    }
}


// MARK: 注入 & 附件
extension NetworkConfig {
    public func addInjectors(_ injectors: RequestInjection) {
        if self.injectors == nil { self.injectors = Array<RequestInjection>() }
        for injector in self.injectors! {
            let isRepeat = self.injectors?.contains(where: { (item) -> Bool in
                return injector.identifier() == item.identifier()
            })
            if isRepeat == false { self.injectors?.append(injector) }
        }
    }
    
    public func clearInjectors() {
        if injectors != nil { injectors!.removeAll() }
    }
    
    public func addAssectories(_ accessories: RequestInjection) {
        if self.accessories == nil { self.accessories = Array<RequestAccessory>() }
        for accessory in self.accessories! {
            let isRepeat = self.accessories?.contains(where: { (item) -> Bool in
                return accessory.identifier() == item.identifier()
            })
            if isRepeat == false { self.accessories?.append(accessory) }
        }
    }
    
    public func clearAssectories() {
        if accessories != nil { accessories!.removeAll() }
    }
}

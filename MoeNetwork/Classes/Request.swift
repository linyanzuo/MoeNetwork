//
//  Request.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//
/**
 【请求】基类
 1. 提供「代理」和「闭包(Block)」两种回调处理方式
 2. 提供「请求附件」和「请求注入」
 */

import UIKit
import HandyJSON


// MARK: - 请求结果的回调代理方法

public protocol RequestResultHandle {
    /// 请求成功的回调代理方法
    func requestSuccessed(request: Request, with response: Response)
    /// 请求失败的回调代理方法
    func requestFailed(request: Request, with error: NetworkError)
    /// 请求完成的回调代理方法，不论失败或成功最终都会执行
    func requestCompleted(request: Request, isSuccess: Bool)
}
public extension RequestResultHandle {
    func requestSuccessed(request: Request, with response: Response) {}
    func requestFailed(request: Request, with error: NetworkError) {}
    func requestCompleted(request: Request, isSuccess: Bool) {}
}


// MARK: - 请求结果的回调闭包

/// 请求成功的回调闭包
public typealias SuccessHandler = (_ request: Request, _ response: Response) -> Void
/// 请求失败的回调闭包
public typealias FailHandler = (_ request: Request, _ error: NetworkError) -> Void
/// 请求完成的回调闭包，不论失败或成功最终都会执行
public typealias CompletionHandler = (_ request: Request, _ isSuccess: Bool) -> Void


// MARK: - 请求类

open class Request: NSObject {
    /// 添加额外的子路径
    public var addtionalSubpath: [String]?
    /// 添加额外的参数
    public var addtionalParameter: Parameter?
    /// 添加额外的报头域
    public var addtionalHeader: HeadeField?
    
    /// 自定义请求体的实现，此时POST请求的额外参数(`addtionalParameter`)、网络配置的全局额外参数都将失效
    public var customBody: String?
    
    ///  负责处理请求结果的代理对象
    ///  通过代理或回调的方式均可处理请求结果，两者选一即可
    ///  若代理与回调的方式均被实现，则先触发代理方法，后触发回调代码块
    internal var delegate: RequestResultHandle?
    
    ///  请求成功的回调处理，另请参阅`delegate`
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var successedHandler: SuccessHandler?
    ///  请求失败的回调处理，另请参阅`delegate`
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var failedHandler: FailHandler?
    ///  请求完成的回调处理，不管成功或失败都会回调，
    ///  请勿与`delegate`同时使用，避免重复处理
    internal var completedHandler: CompletionHandler?
    
    /// 记录请求注入器的数组
    private(set) var injectors: [RequestInjection]?
    /// 记录请求附件的数组
    private(set) var accessories: [RequestAccessory]?

    /// 开始发起网络请求
    private func commonStart() { NetworkAgent.shared.add(request: self) }
    
    /// 返回请求地址的基础地址(`请求地址的共用部分`)，如`www.xxx.com/api`。将与`path`进行拼接得到最终请求地址
    /// 可通过`NetworkConfig`的`baseURL`配置全局的基础地址，或通过重写`Request`的`baseURL`返回基础地址。
    /// 若二者均被实现，则优先取`Request`自身的`baseURL`作为基础地址
    open func baseURL() -> URL? { return nil }

    /// 返回请求地址(`URL`)的具体路径部分，如`home/banner`。将与`baseURL`进行拼接得到最终请求地址
    /// 若该值为完整的URL路径(包含`scheme`,`host`)，则直接作为请求地址，不再进行其它拼接
    open func path() -> String { return "请返回请求的具体路径" }

    /// 返回请求方法, 默认为`GET`
    open func method() -> Method { return .get }
    
    /// 返回对响应进行序列化操作的序列化器，默认为`.json`
    open func serializer() -> Response.Serializer { return .json }
    
    /// 返回请求的`Content-Type`配置，默认为JSON编码
    open func parameterEncoding() -> ParameterEncoding {
        return .jsonEncoding
    }
    
    /// 构造自定义请求`URLRequest`
    open func generateCustomURLRequest() -> URLRequest? { return nil }
    
    /// 发送请求，并使用代理处理结果回调
    /// - Parameter delegate: 回调代理
    public func start(withDelegate delegate: RequestResultHandle) {
        self.delegate = delegate
        commonStart()
    }
    
    /// 发送请求，并使用闭包处理结果回调
    /// - Parameters:
    ///   - successedHandler:   请求成功时执行的回调闭包
    ///   - failedHandler:      请求失败时执行的回调闭包
    ///   - completedHandler:   请求结束时执行的回调闭包，不管成功或失败都会执行
    public func start(
        with successedHandler: SuccessHandler?,
        failedHandler: FailHandler? = nil,
        completedHandler: CompletionHandler? = nil
    ) {
        /** `optional`闭包参数默认就是`@escaping`
         Basically, @escaping is valid only on closures in function parameter position. The noescape-by-default rule only applies to these closures at function parameter position, otherwise they are escaping. Aggregates, such as enums with associated values (e.g. Optional), tuples, structs, etc., if they have closures, follow the default rules for closures that are not at function parameter position, i.e. they are escaping.
         */
        self.successedHandler = successedHandler
        self.failedHandler = failedHandler
        self.completedHandler = completedHandler
        commonStart()
    }
}


// MARK: - 对象结果的请求类

//open class DataObjectRequest<T>: Request {
//
//}


// MARK: 请求附件协议

///  `请求附件`协议定义了数个用于追踪请求状态的可选方法。
///  所有的协议方法都将在主线程中被执行
public protocol RequestAccessory {
    /// `附件`的唯一标识， 用于区分不同附件
    /// 每个请求(`Request`)中，相同标识的附件只能添加一个
    func identifier() -> String
    
    /// 请求即将发送前执行。
    /// `附件`(遵守该协议的对象)可相应执行额外的工作，如展示加载状态的视图
    func requestWillStart(request: Request)
    
    /// 请求执行结束后执行。此时尚未触发回调的代理或闭包
    /// `附件`(遵守该协议的对象)可相应执行额外的工作，如隐藏加载状态的视图
    func request(request: Request, willCompletedSuccessfully isSuccess: Bool)

    /// 请求执行结束后执行。此时已经完成了代理或闭包的回调执行
    func request(request: Request, didCompletedSuccessfully isSuccess: Bool)
}
public extension RequestAccessory {
    func requestWillStart(request: Request) {}
    func request(request: Request, willCompletedSuccessfully isSuccess: Bool) {}
    func request(request: Request, didCompletedSuccessfully isSuccess: Bool) {}
}


// MARK: 请求附件

extension Request {
    enum AccessoryState {
        case willStart
        case willComplete
        case didCompleted
    }
    
    // 当前状态发生改变时，通知所有`附件`执行相应操作
    internal func accessoriesStateChange(_ state: AccessoryState, with successComplete: Bool) {
        guard let accessories = accessories else { return }
        
        for accessory in accessories {
            switch state {
            case .willStart:
                accessory.requestWillStart(request: self)
            case .willComplete:
                accessory.request(request: self, willCompletedSuccessfully: successComplete)
            case .didCompleted:
                accessory.request(request: self, didCompletedSuccessfully: successComplete)
            }
        }
    }
    
    /// 添加附件，注意相同标识的附件只会添加一次
    /// - Parameter accessory: 要添加的附件
    @discardableResult
    public func addAccessory(_ accessory: RequestAccessory) -> Self {
        if accessories == nil { accessories = Array<RequestAccessory>() }
        let isRepeat = accessories?.contains(where: { (item) -> Bool in
            return item.identifier() == accessory.identifier()
        })
        if isRepeat == false { self.accessories?.append(accessory) }

        return self
    }
    
    /// 移除已添加的指定附件(如果存在)，移除成功则返回`True`
    /// - Parameter accessory: 要移除的附件
    @discardableResult
    public func removeAccessory(_ accessory: RequestAccessory) -> Bool {
        let index = accessories?.firstIndex(where: { (item) -> Bool in
            item.identifier() == accessory.identifier()
        })
        guard index != nil else { return false }

        accessories?.remove(at: index!)
        return true
    }
    
    /// 移除已添加的所有附件
    public func removeAllAccessories() {
        accessories?.removeAll()
    }
}


// MARK: 请求注入协议

///  遵守`请求注入`协议的对象可在构建请求前进行拦截并执行注入，如调整请求参数等
///  所有的协议方法都将在主线程中被执行
public protocol RequestInjection {
    /// `注入器`的唯一标识， 用于区分不同注入器
    /// 每个请求(`Request`)中，相同标识的注入器只能添加一个
    func identifier() -> String
    
    /// 拦截请求的所有参数，进行注入后返回请求最终发送的所有参数
    /// - Parameter parameters: 注入前请求的所有参数
    /// - Parameter request: 要发送的请求
    func injectParameters(_ parameters: [String: Any], to request: Request) -> [String: Any]
    
    /// 拦截请求的所有请求头域，进行注入后返回请求最终发送的所有请求头域
    /// - Parameter field: 注入前请求的所有请求头域
    /// - Parameter request: 要发送的请求
    func injectHeaderField(_ field: [String: String], to request: Request) -> [String: String]
}
public extension RequestInjection {
    func identifier() -> String {
        return String(describing: self)
    }
    
    func injectParameters(_ parameters: [String: Any], to request: Request) -> [String: Any] {
        return parameters
    }
    
    func injectHeaderField(_ field: [String: String], to request: Request) -> [String: String] {
        return field
    }
}


// MARK: 请求注入

extension Request {
    
    /// 添加注入器，注意相同标识的注入器只会添加一次
    /// - Parameter injector: 要添加的注入器
    @discardableResult
    public func addInjector(_ injector: RequestInjection) -> Self {
        if injectors == nil { injectors = Array<RequestInjection>() }
        let isRepeat = injectors?.contains(where: { (item) -> Bool in
            return item.identifier() == injector.identifier()
        })
        if isRepeat == false { injectors?.append(injector) }
        
        return self
    }
    
    /// 移除已添加的指定注入器(如果存在)，移除成功则返回`True`
    /// - Parameter injector: 要移除的注入器
    @discardableResult
    public func removeInjector(_ injector: RequestAccessory) -> Bool {
        let index = injectors?.firstIndex(where: { (item) -> Bool in
            return item.identifier() == injector.identifier()
        })
        guard index != nil else { return false }
        
        injectors?.remove(at: index!)
        return true
    }
    
    /// 移除已添加的所有注入器
    public func removeAllInjectors() {
        injectors?.removeAll()
    }
    
}

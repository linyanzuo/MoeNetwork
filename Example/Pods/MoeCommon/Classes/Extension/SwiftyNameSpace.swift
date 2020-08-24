//
//  SwiftyNameSpace.swift
//  MoeCommon
//
//  Created by Zed on 2019/11/19.
//

// MARK: Wrappable Define

//  基本类型、结构体等, 使用等号`==`
public protocol TypeWrapperProtocol {
    associatedtype WrappedType
    var wrappedValue: WrappedType { get }
    init(value: WrappedType)
}
public struct NamespaceWrapper<T>: TypeWrapperProtocol {
    public let wrappedValue: T
    public init(value: T) {
        self.wrappedValue = value
    }
}

//  对象类型, 使用冒号`:`
public protocol NamespaceWrappable {
    associatedtype WrapperType
    var moe: WrapperType { get }
    static var moe: WrapperType.Type { get }
}
public extension NamespaceWrappable {
    var moe: NamespaceWrapper<Self> {
        return NamespaceWrapper(value: self)
    }
    static var moe: NamespaceWrapper<Self>.Type {
        return NamespaceWrapper.self
    }
}


// MARK: Extension

extension String: NamespaceWrappable {}

extension UIApplication: NamespaceWrappable {}
extension UIViewController: NamespaceWrappable {}

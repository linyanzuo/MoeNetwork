//
//  Standard.swift
//  MoeCommon
//
//  Created by Zed on 2019/11/19.
//

// MARK: String

extension TypeWrapperProtocol where WrappedType == String {
    /// 获取指定位置的子字符串并返回
    /// - Parameter start: 开始截取位置(包含该位置的值)
    /// - Parameter length: 截取长度, 不指定则取到结束
    public func subString(start:Int, length:Int = -1) -> String {
        var len = length
        if len == -1 {
            len = wrappedValue.count - start
        }
        let st = wrappedValue.index(wrappedValue.startIndex, offsetBy:start)
        let en = wrappedValue.index(st, offsetBy:len)
        return String(wrappedValue[st ..< en])
    }
}

// MARK: Operator

public func += <KeyType, ValueType> (
    left: inout Dictionary<KeyType, ValueType>,
    right: Dictionary<KeyType, ValueType>)
{
    for (key, value) in right { left.updateValue(value, forKey: key) }
}

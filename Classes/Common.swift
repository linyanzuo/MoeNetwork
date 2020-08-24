//
//  Common.swift
//  Alamofire
//
//  Created by Zed on 2019/9/19.
//

import Foundation


/// 错误信息输出
///
/// 输出调试信息, 包含: `method name@file name`, `line number`, `log message`
internal func MLog<T> (
    _ fmt: T,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    #if DEBUG
    let fileName = NSString(string: file).pathComponents.last!
    print("[MoeUI_Debug_Print: \(fileName) > \(function), \(line)]\n\t\(fmt)")
    #endif
    //    debugPrint(fmt)
    
    /// Todo: 日志记录
}


func += <KeyType, ValueType> (
    left: inout Dictionary<KeyType, ValueType>,
    right: Dictionary<KeyType, ValueType>
) {
    for (key, value) in right {
        left.updateValue(value, forKey: key)
    }
}

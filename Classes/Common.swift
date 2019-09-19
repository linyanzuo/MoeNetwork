//
//  Common.swift
//  Alamofire
//
//  Created by Zed on 2019/9/19.
//

import Foundation


/// Debug message log
///
/// print debug message, include: `method name@file name`, `line number`, `log message`
public func MLog<T>(_ fmt: T, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let fileName = NSString(string: file).pathComponents.last!
    print("[MoeUI_Debug_Print: \(fileName) > \(function), \(line)]\n\t\(fmt)")
    //    debugPrint(fmt)
    #endif
}

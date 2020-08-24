//
//  MoeError.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import Foundation
import HandyJSON


public struct NetworkError: Error {
    /// 错误编码
    public let code: Int?
    /// 错误的描述信息，如果存在
    public let message: String?
    /// 请求的URL地址
    public let requstURL: URL?
    /// 请求的开始时间
    public let requestStartTime: Date?
    /// 请求的结束时间
    public let requestCompletedTime: Date?
}


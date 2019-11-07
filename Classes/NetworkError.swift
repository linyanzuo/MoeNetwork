//
//  MoeError.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import Foundation
import HandyJSON


public struct NetworkError: Error {
    /// Code of Error
    let code: Int
    /// Description of Error Message
    let message: String
    ///  the url of request
    let requstURL: URL?
    ///  the time when requst was send
    let requestStartTime: Date
}


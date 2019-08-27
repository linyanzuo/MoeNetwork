//
//  MoeError.swift
//  MoeNetwork
//
//  Created by Zed on 2019/8/26.
//

import Foundation
import HandyJSON


public class Error: HandyJSON {
    /// Code of Error
    var code: Int = -1
    /// Description of Error Message
    var message: String = "No Message"

    public required init() {}

    convenience init(code: Int, message: String) {
        self.init()
        self.code = code
        self.message = message
    }
}


//
//  BaseResponse.swift
//  MoeNetwork_Example
//
//  Created by Zed on 2019/8/27.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import MoeNetwork


class BaseResponse: ResponseData {
    required init() { }
    
    var errcode: Int?
    var errmsg: String?

//    override func statusCode() -> Int {
//        return self.errcode ?? -1
//    }
//
//    override func statusMessage() -> String {
//        return self.errmsg ?? "No Message"
//    }
}

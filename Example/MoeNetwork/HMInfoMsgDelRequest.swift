//
//  HMInfoMsgDelRequest.swift
//  MoeNetwork_Example
//
//  Created by Zed on 2019/10/31.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import MoeNetwork


///删除站内信
class HMInfoMsgDelRequest: Request {
    
    override func path() -> String {
        return "/message"
    }
    
    override func requiredAuthorization() -> Bool {
        return true
    }
    
    override func method() -> Method {
        return .delete
    }
}

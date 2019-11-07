//
//  HMBetOrderRandomRequest.swift
//  MoeNetwork_Example
//
//  Created by Zed on 2019/10/31.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import MoeNetwork


///随机投注
class HMBetOrderRandomRequest: BaseRequest {
    override func path() -> String {
        return "/betOrder/random"
    }
    
    override func requiredAuthorization() -> Bool {
        return true
    }
    
    override func method() -> Method {
        return .post
    }
    
    override func responseType() -> Response.Type {
        return HMBetOrderRandomResponse.self
    }
    
    override func body() -> String? {
        return "{\"size\":1,\"code\":\"SIX4-ZHIX-ZXFS\",\"periodNo\":\"20191031150\"}"
    }
}


class HMBetOrderRandomResponse: BaseResponse {
    var data: HMBetOrderRandomData?
}

struct HMBetOrderRandomData: ResponseData {
    var expressions: [String]?
}

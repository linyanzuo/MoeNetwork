//
//  Request.swift
//  MoeNetwork_Example
//
//  Created by Zed on 2019/8/27.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import MoeNetwork


class BaseRequest: Request {
    override init() {
        super.init()
        test()
    }
    
    func test() {
        self.addAccessory(LoadingAccessory())
        self.addInjector(TokenInjector())
    }
}


struct LoadingAccessory: RequestAccessory {
    func identifier() -> String {
        return "Loading"
    }
    
    func requestWillStart(request: Request) {
        print("展示正在加载")
    }
    
    func request(request: Request, willCompletedSuccessfully isSuccess: Bool) {
        print("隐藏正在加载")
    }
    
    func request(request: Request, didCompletedSuccessfully isSuccess: Bool) {
        print("----------")
    }
}


struct TokenInjector: RequestInjection {    
    func identifier() -> String {
        return "TokenInjector"
    }
    
    func injectHeaderField(_ field: [String : String], to request: Request) -> [String : String] {
        var field = field
        let token = "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhMTIxQHFxLmNvbSIsImF1dGgiOiJST0xFX1VTRVIiLCJpZCI6MTE4NjQ1NTg5OTY3NjgwMzA3MywidGVsIjoiMTU4MTg1NDAwMDEiLCJlbWFpbCI6ImExMjFAcXEuY29tIiwiY291bnRyeV9jb2RlIjoiKzg2IiwiZXhwIjoxNzQ1MzAzNzQxfQ.-L8kV6QUj7ZAbZHsw8ymXO0w-sPkK8F9s7Rqd9w4W779cv98tiFENaznRTb-A9KXALEUHG1HzMT9GATejpQcxA"
        field.updateValue(token, forKey: "Authorization")
        return field
    }
    
    func injectParameters(_ parameters: [String : Any], to request: Request) -> [String : Any] {
        var para: [String : Any] = parameters
        para.updateValue("iOS", forKey: "Platform")
        return para
    }
}

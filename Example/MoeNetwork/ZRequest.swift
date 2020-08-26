//
//  Created by Zed on 2019/8/12.
//  Copyright © 2019 www.moemone.com. All rights reserved.
//

import UIKit
import HandyJSON
import MoeNetwork


class ZRequest<T: DataObject>: Request {
    var zPath: String
    var zMethod: Request.Method
    var zRequiredAuth: Bool

    init(path: String, method: Request.Method, auth: Bool = false) {
        self.zPath = path
        self.zMethod = method
        self.zRequiredAuth = auth
        super.init()
    }

    override func path() -> String {
        return self.zPath
    }

    override func method() -> Request.Method {
        return self.zMethod
    }

    override func serializer() -> Response.Serializer {
//        return .handyJson(T.self)
//        return .handyJson(ZResponse<T>.self)
        return .handyJson(ZResponse<WalletBalance>.self)
    }
}


struct TokenInjector: RequestInjection {
    func identifier() -> String {
        return "TokenInjector"
    }
    
    func injectHeaderField(_ field: [String : String], to request: Request) -> [String : String] {
//        if let token = BaseSingleton.share.loginer.token {
//            var field = field
//            field.updateValue(token, forKey: "Authorization")
//            return field
//        }
        return field
    }

    func injectParameters(_ parameters: [String : Any], to request: Request) -> [String : Any] {
        var para: [String : Any] = parameters
        para.updateValue("iOS", forKey: "Platform")
        return para
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

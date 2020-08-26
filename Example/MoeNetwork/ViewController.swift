//
//  ViewController.swift
//  MoeNetwork
//
//  Created by linyanzuo1222@gmail.com on 08/26/2019.
//  Copyright (c) 2019 linyanzuo1222@gmail.com. All rights reserved.
//

import UIKit
import MoeCommon
import MoeNetwork


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        
        // MARK: - JSON转模型测试
//        let mockResp = "{\"code\":200,\"data\":{\"balance\":\"123456\"}}"
//        let result = ZResponse<WalletBalance>.deserialize(from: mockResp)
//        MLog(result)

        // MARK: GET请求测试
        let api = WalletAPI.balance()
        api.start(with: { (req, resp) in
            MLog(req)
            MLog(resp.dataObject)
        }, failedHandler: { (req, error) in
            MLog(req)
            MLog(error)
        }) { (req, isSuccess) in
            MLog(req)
            MLog(isSuccess)
        }
        
//        banner.addtionalParameter = [
//            "current" : 0,
//            "size" : 10
//        ]
//        banner.addtionalHeader = ["Lang" : "zh_CN"]
//        banner.start(with: { (request, response) in
//            guard let obj = response.dataObject as? HMBannerResponse else { return }
//            MLog(obj.data)
//        }) { (request, error) in
//
//        }
    }
}


extension ViewController: RequestResultHandle {
    func requestSuccessed(request: Request, with response: Response) {
        MLog("Success: \(request)")
    }
    
    func requestFailed(request: Request, with error: NetworkError) {
        MLog("Fail: \(error)")
    }
    
    func requestCompleted(request: Request, isSuccess: Bool) {
        MLog("Comple: \(isSuccess)")
    }
}


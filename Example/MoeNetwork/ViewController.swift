//
//  ViewController.swift
//  MoeNetwork
//
//  Created by linyanzuo1222@gmail.com on 08/26/2019.
//  Copyright (c) 2019 linyanzuo1222@gmail.com. All rights reserved.
//

import UIKit
import MoeNetwork


/// Debug message log
///
/// print debug message, include: `method name@file name`, `line number`, `log message`
internal func MLog<T>(_ fmt: T, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let fileName = NSString(string: file).pathComponents.last!
    print("[MoeUI_Debug_Print: \(fileName) > \(function), \(line)]\n\t\(fmt)")
    //    debugPrint(fmt)
    #endif
}


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue

        // MARK: GET请求测试
        let banner = HomeAPI.banner()
        banner.addtionalParameter = [
            "current" : 0,
            "size" : 10
        ]
        banner.addtionalHeader = ["Lang" : "zh_CN"]
        banner.start(with: { (request, response) in
            guard let obj = response.handyObject as? HMBannerResponse else { return }
            MLog(obj.data)
        }) { (request, error) in
            
        }
        
        // MARK: POST请求测试
//        HomeAPI.betOrderRandom().start(withDelegate: self)
        let random = HomeAPI.betOrderRandom()
//        random.addtionalParameter = [
//            "size" : 1,
//            "code" : "SIX4-ZHIX-ZXFS",
//            "periodNo" : "20191112159"
//        ]
        random.customBody = "{\"size\":1,\"code\":\"SIX4-ZHIX-ZXFS\",\"periodNo\":\"20191112159\"}"
        random.addtionalHeader = ["Lang" : "zh_CN"]
        random.start(with: { (request, response) in
            guard let obj = response.handyObject as? HMBetOrderRandomResponse else { return }
            MLog( obj.data?.expressions)
        }, failedHandler: nil, completedHandler: nil)

        // MARK: --- 分割线 ---
//        HomeAPI.hotGames().send(parameters: nil, success: { (data) in
//            let response = data as? HMHotGamesResponse
//            print(String(describing: response))
//        }) { (error) in
//            print(error)
//        }
        
//        let request = HomeAPI.banner()
//        request.start(with: self)
        
//        HomeAPI.hotGames().start(with: { (request) in
//            MLog("Success: \(request)")
//        }, failedHandler: { (request, error) in
//            MLog("Fail: \(error)")
//        }) { (request, isSuccess) in
//            MLog("Comple: \(isSuccess)")
//        }
        
//        HomeAPI.hotGames().start(withDelegate: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        print(HMBannerResponse.persistenceURL())
//        let banner = HMBannerResponse.load(from: "Banner")
//        print(String(describing: banner))
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


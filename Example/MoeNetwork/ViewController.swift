//
//  ViewController.swift
//  MoeNetwork
//
//  Created by linyanzuo1222@gmail.com on 08/26/2019.
//  Copyright (c) 2019 linyanzuo1222@gmail.com. All rights reserved.
//

import UIKit
import MoeNetwork


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let params: [String: Any] = [
            "current" : 0,
            "size" : 10
        ]
//        HMBannerRequest().send(parameters: params, success: { (data) in
//            let response = data as? HMBannerResponse
//            response?.save(to: "Banner")
//            print(String(describing: response))
//        }) { (error) in
//            print(error)
//        }

//        HomeAPI.hotGames().send(parameters: nil, success: { (data) in
//            let response = data as? HMHotGamesResponse
//            print(String(describing: response))
//        }) { (error) in
//            print(error)
//        }
        
//        HomeAPI.hotGames().start()
        
//        let request = HomeAPI.banner()
//        request.start(with: self)
        
//        HomeAPI.hotGames().start(with: { (request) in
//            MLog("Success: \(request)")
//        }, failedHandler: { (request, error) in
//            MLog("Fail: \(error)")
//        }) { (request, isSuccess) in
//            MLog("Comple: \(isSuccess)")
//        }
        
        HomeAPI.betOrderRandom().start(withDelegate: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(HMBannerResponse.persistenceURL())
        let banner = HMBannerResponse.load(from: "Banner")
        print(String(describing: banner))
    }
}


extension ViewController: RequestResultHandle {
    func requestSuccessed(request: Request) {
        MLog("Success: \(request)")
    }
    
    func requestFailed(request: Request, with error: NetworkError) {
        MLog("Fail: \(error)")
    }
    
    func requestCompleted(request: Request, isSuccess: Bool) {
        MLog("Comple: \(isSuccess)")
    }
}


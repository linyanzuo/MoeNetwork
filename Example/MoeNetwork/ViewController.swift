//
//  ViewController.swift
//  MoeNetwork
//
//  Created by linyanzuo1222@gmail.com on 08/26/2019.
//  Copyright (c) 2019 linyanzuo1222@gmail.com. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let params: [String: Any] = [
            "current" : 0,
            "size" : 10
        ]
        HMBannerRequest().send(parameters: params, success: { (data) in
            let response = data as? HMBannerResponse
            response?.save(to: "Banner")
            print(String(describing: response))
        }) { (error) in
            print(error)
        }

        HomeAPI.hotGames().send(parameters: nil, success: { (data) in
            let response = data as? HMHotGamesResponse
            print(String(describing: response))
        }) { (error) in
            print(error)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(HMBannerResponse.persistenceURL())
        let banner = HMBannerResponse.load(from: "Banner")
        print(String(describing: banner))
    }
}


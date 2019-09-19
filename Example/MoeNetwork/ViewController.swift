//
//  ViewController.swift
//  MoeNetwork
//
//  Created by linyanzuo1222@gmail.com on 08/26/2019.
//  Copyright (c) 2019 linyanzuo1222@gmail.com. All rights reserved.
//

import UIKit
//import MoeUI


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let params: [String: Any] = [
            "current" : 0,
            "size" : 10
        ]
        HMBannerRequest().send(parameters: params, success: { (data) in
            let response = data as? HMBannerResponse
//            MLog(response)
        }) { (error) in
//            MLog(error)
        }

        HomeAPI.hotGames.send(parameters: nil, success: { (data) in
            let response = data as? HMHotGamesResponse
//            MLog(response) 
        }) { (error) in
//            MLog(error)
        }
    }

}


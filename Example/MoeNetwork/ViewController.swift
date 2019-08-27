//
//  ViewController.swift
//  MoeNetwork
//
//  Created by linyanzuo1222@gmail.com on 08/26/2019.
//  Copyright (c) 2019 linyanzuo1222@gmail.com. All rights reserved.
//

import UIKit
import MoeUI


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let parameters: [String: Any] = ["current" : 1,
                                         "size" : 20]
        PersonalAPI.betOrder.send(parameters: parameters, success: { (data) in
            MLog(data)
        }) { (error) in
            MLog(error)
        }
    }

}


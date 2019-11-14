//
//  AppDelegate.swift
//  MoeNetwork
//
//  Created by linyanzuo1222@gmail.com on 08/26/2019.
//  Copyright (c) 2019 linyanzuo1222@gmail.com. All rights reserved.
//

import UIKit
import MoeNetwork
//import MoeUI


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    @objc func test(noti: Notification) {
        guard let state = noti.userInfo?["ConnectionState"] as? NetworkHelper.ConnectionState
            else { return }

        switch state {
        case .wifi:
            MLog("Wifi网络")
        case .mobile:
            MLog("移动网络")
        case .unKnow, .noNetwork:
            MLog("无网络连接")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        networkConfig()
        
//        let person = Developer()
//        person.name = "zed"
//        person.save(to: "Zed")
//        
//        if let recover = Developer.load(from: "Zed") {
//            print(recover.subject)
//        }

        return true
    }
    
    private func networkConfig() {
        NotificationCenter.default.addObserver(self, selector: #selector(test), name: Notification.Name.Network.ConnectionState, object: nil)
        NetworkHelper.shared.startListening()
        
        let config = NetworkConfig.shared
        config.baseURL = URL(string: "http://47.56.83.245:8400/v2/w")!
        config.authenticationToken = "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhMTIxQHFxLmNvbSIsImF1dGgiOiJST0xFX1VTRVIiLCJpZCI6MTE4NjQ1NTg5OTY3NjgwMzA3MywidGVsIjoiMTU4MTg1NDAwMDEiLCJlbWFpbCI6ImExMjFAcXEuY29tIiwiY291bnRyeV9jb2RlIjoiKzg2IiwiZXhwIjoxNzQ1MzAzNzQxfQ.-L8kV6QUj7ZAbZHsw8ymXO0w-sPkK8F9s7Rqd9w4W779cv98tiFENaznRTb-A9KXALEUHG1HzMT9GATejpQcxA"
        config.addtionalHeader = ["Lang": "zh_CN"]
        config.addtionalParameter = ["Version": "1.0.0"]
    }
}


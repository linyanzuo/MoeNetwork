//
//  NetworkConfig.swift
//  MoeNetwork
//
//  Created by Zed on 2019/10/29.
//

import Foundation


///  Global config
class NetworkConfig {
    
    ///  Base url of request, always host
    public var baseURL: URL?
    ///  CDN url of request
//    public var cdnURL: String
    ///  Used to initialize HttpSessionManager
    public var sessionConfiguration: URLSessionConfiguration
    
    ///  Get the shared instance
    static public let shared = NetworkConfig()
    private init() {
//        baseURL = "Please change the `baseURL` to match your environment"
//        cdnURL = "Please change the `cdnURL` to match your environment"
        sessionConfiguration = URLSessionConfiguration.default
    }
    
}

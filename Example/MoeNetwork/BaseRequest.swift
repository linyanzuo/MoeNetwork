//
//  Request.swift
//  MoeNetwork_Example
//
//  Created by Zed on 2019/8/27.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import MoeNetwork


class BaseRequest: Request {
    override func baseURL() -> URL {
        return URL(string: "http://47.52.20.37:8400/v2/w")!
    }

    override func authenticationToken() -> String {
        return "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ3aWtpaG9tZUBxcS5jb20iLCJhdXRoIjoiUk9MRV9VU0VSIiwiaWQiOjExNTg1ODk3NzgyNDkzMjY1OTMsImVtYWlsIjoid2lraWhvbWVAcXEuY29tIiwiY291bnRyeV9jb2RlIjoiKzg2IiwiZXhwIjoxNzM4NjYwNzUxfQ.z_PkQY7D9_S2egAf4QG6XhseKAS9ig9hlUAf2G-LQ0dg5mRGJr0CSh7RemlmtYxHt1THzeibdZvUlcBJ6ezpcQ"
    }
}

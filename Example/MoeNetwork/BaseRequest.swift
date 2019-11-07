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
        return "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhMTIxQHFxLmNvbSIsImF1dGgiOiJST0xFX1VTRVIiLCJpZCI6MTE4NjQ1NTg5OTY3NjgwMzA3MywidGVsIjoiMTU4MTg1NDAwMDEiLCJlbWFpbCI6ImExMjFAcXEuY29tIiwiY291bnRyeV9jb2RlIjoiKzg2IiwiZXhwIjoxNzQ1MzAzNzQxfQ.-L8kV6QUj7ZAbZHsw8ymXO0w-sPkK8F9s7Rqd9w4W779cv98tiFENaznRTb-A9KXALEUHG1HzMT9GATejpQcxA"
    }
}

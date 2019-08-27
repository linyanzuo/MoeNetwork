//
//  PMBetOrderAPI.swift
//  EPPlay
//
//  Created by Zed on 2019/8/14.
//  Copyright © 2019 YuXiTech. All rights reserved.
//

import MoeNetwork


/// 分页查询投注记录列表
class PSBetOrderRequest: BaseRequest {
    override func path() -> String {
        return "/betOrder"
    }

    override func responseType() -> Response.Type {
        return PMBetOrderResponse.self
    }

    override func requiredAuthorization() -> Bool {
        return true
    }

    override func method() -> Request.Method {
        return .get
    }
}


class PMBetOrderResponse: BaseResponse {
    var data: PMBetOrderData?
}
struct PMBetOrderData: ResponseData {
    var records: [PMBetOrderRecord]?
    var total: Int?
    var size: Int?
    var current: Int?
    var searchCount: Bool?
    var pages: Int?
}
struct PMBetOrderRecord: ResponseData {
    var id: String?
    var userId: String?
    var trackId: String?
    var lotteryId: String?
    var lotteryName: String?
    var categoryId: String?
    var categoryName: String?
    var gameId: String?
    var gameName: String?
    var periodNo: String?
    var multiple: Int?
    var coinId: String?
    var coinName: String?
    var amount: Int?
    var reward: Int?
    var point: Int?
    var pointRate: Int?
    var status: Int?
    var bettingNumber: String?
    var created: String?
    var lastUpdateTime: String?
    var imageUrl: String?
    var lotteryNumber: String?
}

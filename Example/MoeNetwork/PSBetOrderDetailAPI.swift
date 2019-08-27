//
//  PSBetOrderDetailAPI.swift
//  EPPlay
//
//  Created by Zed on 2019/8/15.
//  Copyright © 2019 YuXiTech. All rights reserved.
//

import MoeNetwork


/// 查看投注记录详情
class PSBetOrderDetailRequest: Request {
    override func path() -> String {
        return "/betOrder"
    }

    override func requiredAuthorization() -> Bool {
        return true
    }

    override func responseType() -> Response.Type {
        return PSBetOrderDetailResponse.self
    }
}


class PSBetOrderDetailResponse: Response {
    var data: PSBetOrderDetailData?
}
struct PSBetOrderDetailData: ResponseData {
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


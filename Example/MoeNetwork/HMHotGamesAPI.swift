//
//  HMHotGamesAPI.swift
//  EPPlay
//
//  Created by yuxiitech on 2019/8/13.
//  Copyright © 2019 YuXiTech. All rights reserved.
//

import UIKit
import MoeNetwork
import HandyJSON

/// 查询所有热门玩法
class HMHotGamesRequest: BaseRequest {
    override func path() -> String {
        return "lottery/game/queryHotGames"
    }

    override func serializer() -> Serializer {
        return .handyJson(HMHotGamesResponse.self)
    }
}


class HMHotGamesResponse: BaseResponse {
    var data: [HMHotGamesData]?
}


struct HMHotGamesData: ResponseData {
    var id: String?
    var code: String?
    var name: String?
    var hotFlag: Int?
    var lotteryId: String?
    var lotteryName: String?
    var categoryId: String?
    var categoryCode: String?
    var categoryName: String?
    var type: Int?
    var typeName: String?
    var weight: Int?
    var status: Int?
    var created: String?
    var lastUpdateTime: String?
    var hotImage: String?
}

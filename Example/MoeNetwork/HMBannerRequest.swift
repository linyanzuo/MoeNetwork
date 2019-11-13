//
//  HMBannerRequest.swift
//  EPPlay
//
//  Created by Zed on 2019/8/12.
//  Copyright © 2019 YuXiTech. All rights reserved.
//

import UIKit
import MoeNetwork
import HandyJSON


/// 分页查询Banner列表
class HMBannerRequest: BaseRequest, Persistence {
    override func path() -> String {
        return "/banner"
    }
    
    override func method() -> Request.Method {
        return .get
    }
    
    override func serializer() -> Serializer {
        return .handyJson(HMBannerResponse.self)
    }

    override func requestWillSend() {
        print("HMBannerRequest will send")
    }

    override func requestDidFinish(isSuccess: Bool) {
        print("HMBannerRequest did finish")
    }

    deinit {
        print("HMBannerRequest deinit")
    }
}


class HMBannerResponse: BaseResponse, Persistence {
    var data: HMBannerData?
}


struct HMBannerData: HandyObject, Persistence {
    var records: [HMBannerRecord]?
    var total: Int?
    var size: Int?
    var current: Int?
    var searchCount: Bool?
    var pages: Int?
}


/// 如果HMBannerRecord没有遵守Persistence协议, 会导致Codable协议报错如下
/// Type 'HMBannerData' does not conform to protocol 'Decodable'
struct HMBannerRecord: HandyObject, Persistence {
    var id: String?
    var category: String?
    var name: String?
    var title: String?
    var introduction: String?
    var imageUrl: String?
    var linkUrl: String?
    var created: String?
    var lastUpdateTime: String?
}



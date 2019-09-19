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
class HMBannerRequest: BaseRequest {
    override func path() -> String {
        return "/banner"
    }

    override func responseType() -> Response.Type {
        return HMBannerResponse.self
    }

    override func method() -> Request.Method {
        return .post
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


class HMBannerResponse: BaseResponse {
    var data: HMBannerData?
}


struct HMBannerData: ResponseData {
    var records: [HMBannerRecord]?
    var total: Int?
    var size: Int?
    var current: Int?
    var searchCount: Bool?
    var pages: Int?
}


struct HMBannerRecord: ResponseData {
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



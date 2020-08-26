//
//  Response.swift
//  EPPlay
//
//  Created by Zed on 2019/8/12.
//  Copyright © 2019 YuXiTech. All rights reserved.
//

import UIKit
import MoeNetwork


class ZResponse<T: DataObject>: DataObject {
    /// 返回状态码，1000为成功
    var code: Int?
    /// 返回信息
    var desc: String?
    /// 标识
    var cid: String?
    /// 返回的封装数据
    var data: T?

    required init() {}
}


class ZDataObject: DataObject {
    required init() {}
}

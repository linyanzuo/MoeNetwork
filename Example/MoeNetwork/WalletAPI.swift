//
//  WalletAPI.swift
//  TPSLIVE
//
//  Created by Zed on 2020/8/24.
//  Copyright © 2020 HS. All rights reserved.
//

import MoeNetwork

/// 钱包API接口
public struct WalletAPI {
    
    static func balance() -> ZRequest<WalletBalance> {
        return ZRequest( path: "user/getBalance", method: .get, auth: true)
    }
    
}


class WalletBalance: DataObject {
    /// 总余额
    var overallBalance: String?
    /// 可提现金额
    var balance: String?
    /// 提现中金额
    var withdrawingAmounts: String?
    /// 待入账金额
    var notIncomeBalance: String?
    
    required init() {}
}

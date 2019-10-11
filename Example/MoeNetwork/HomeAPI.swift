//
//  HomeAPI.swift
//  EPPlay
//
//  Created by Zed on 2019/8/13.
//  Copyright © 2019 YuXiTech. All rights reserved.
//


/// [首页API接口](http://47.52.20.37:8401/swagger-ui.html#/)
public struct HomeAPI {

    /// 分页查询Banner列表
    static func banner() -> HMBannerRequest { return HMBannerRequest() }

    /// 查询所有热门玩法
    static func hotGames() -> HMHotGamesRequest { return HMHotGamesRequest() }
}

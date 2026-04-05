//
//  ResourceCategory.swift
//
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation

/// 资源类别
///
/// 用于标识资源类型，`ResourceCenter` 通过类别将资源路由到对应的 `ResourceLoader`。
public enum ResourceCategory: Hashable, Sendable {
    /// 未知类型
    case unknown
    /// 文件资源
    case file
    /// 网络资源
    case web
    /// 自定义类型
    case custom(String)
}

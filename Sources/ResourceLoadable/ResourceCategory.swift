//
//  ResourceCategory.swift
//  
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation

/// 资源列表
public enum ResourceCategory: Hashable {
    case unknown
    case file
    case web
    case custom(String)
}

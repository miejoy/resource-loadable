//
//  ResourceLoader.swift
//  
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

/// 资源加载者
public protocol ResourceLoader: AnyObject {
    
    /// 支持的资源类别列表
    static var categories: Set<ResourceCategory> { get }
    
    /// 加载对应资源
    func load<Resource: LoadableResource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) -> AnyPublisher<Resource.Response, Error>
}

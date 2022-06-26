//
//  ResourceHandleable.swift
//  
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

public protocol ResourceHandleable: AnyObject {
    
    static var handlerCategorys: Set<ResourceCategory> { get }
        
    func load<Resource: ResourceLoadable>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) -> AnyPublisher<Resource.Response, Error>
}

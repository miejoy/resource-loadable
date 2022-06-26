//
//  ResourceManager.swift
//  
//
//  Created by 黄磊 on 2022/6/18.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

public final class ResourceManager {
    static var shared : ResourceManager = {
        let manager = ResourceManager()
        return manager
    }()
    
    
    var registerHandlerMap: [ResourceCategory: any ResourceHandleable] = [:]
    
    public func registerHandler<Handler: ResourceHandleable>(_ resourceHandler: Handler) {
        Handler.handlerCategorys.forEach { category in
            if let oldResourceHandler = registerHandlerMap[category] {
                ResourceMonitor.shared.record(event: .duplicateRegistration(oldResourceHandler, resourceHandler))
            }
            registerHandlerMap[category] = resourceHandler
            ResourceMonitor.shared.record(event: .addResourceHander(resourceHandler, category))
        }
    }
    
    func load<Resource: ResourceLoadable>(_ resource: Resource, with extraData: Resource.ExtraData) -> AnyPublisher<Resource.Response, Error> {
        if let handler = registerHandlerMap[Resource.category] {
            return handler.load(resource, with: extraData)
        }
        ResourceMonitor.shared.record(event: .noHandlerFoundForResource(Resource.category))
        let publisher = PassthroughSubject<Resource.Response, Error>()
        publisher.send(completion: .failure(LoadResourceError.noHandlerForResource(Resource.category)))
        return publisher.eraseToAnyPublisher()
    }
}

public enum LoadResourceError: Error {
    case noHandlerForResource(ResourceCategory)
    case noValueReceiveWhenCompletion
    case resourceTypeError
}

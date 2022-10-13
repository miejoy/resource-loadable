//
//  ResourceCenter.swift
//  
//
//  Created by 黄磊 on 2022/6/18.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

/// 资源中心
public final class ResourceCenter {
    static var shared : ResourceCenter = {
        let manager = ResourceCenter()
        return manager
    }()
    
    
    var registerLoaderMap: [ResourceCategory: any ResourceLoader] = [:]
    
    public func registerLoader<Loader: ResourceLoader>(_ resourceLoader: Loader) {
        Loader.categories.forEach { category in
            if let oldResourceLoader = registerLoaderMap[category] {
                ResourceMonitor.shared.record(event: .duplicateRegistration(oldResourceLoader, resourceLoader))
            }
            registerLoaderMap[category] = resourceLoader
            ResourceMonitor.shared.record(event: .addResourceLoader(resourceLoader, category))
        }
    }
    
    func load<Resource: LoadableResource>(_ resource: Resource, with extraData: Resource.ExtraData) -> AnyPublisher<Resource.Response, Error> {
        if let loader = registerLoaderMap[Resource.category] {
            return loader.load(resource, with: extraData)
        }
        ResourceMonitor.shared.record(event: .noLoaderFoundForResource(Resource.category))
        let publisher = PassthroughSubject<Resource.Response, Error>()
        publisher.send(completion: .failure(LoadResourceError.noLoaderForResource(Resource.category)))
        return publisher.eraseToAnyPublisher()
    }
}

public enum LoadResourceError: Error {
    case noLoaderForResource(ResourceCategory)
    case noValueReceiveWhenCompletion
    case resourceTypeError
}

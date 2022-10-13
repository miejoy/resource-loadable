//
//  WebResource.swift
//  
//
//  Created by 黄磊 on 2022/6/25.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import ResourceLoadable
import Combine

protocol LoadableWebResource: LoadableResource {
    static var action: String { get }
}

extension LoadableWebResource {
    static var category: ResourceCategory { .web }
}

class WebResourceLoader: ResourceLoader {
    
    static var categories: Set<ResourceCategory> = [.web]
    
    func load<Resource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) -> AnyPublisher<Resource.Response, Error> where Resource : LoadableResource {
        let publisher = PassthroughSubject<Resource.Response, Error>()
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            let data = "{\"name\":\"test\"}".data(using: .utf8)!
            let response = try! JSONDecoder().decode(Resource.Response.self, from: data)
            publisher.send(response)
            publisher.send(completion: .finished)
        }
        return publisher.eraseToAnyPublisher()
    }
}

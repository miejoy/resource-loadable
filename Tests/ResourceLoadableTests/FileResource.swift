//
//  FileResource.swift
//  
//
//  Created by 黄磊 on 2022/6/25.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import ResourceLoadable
import Combine

protocol LoadableFileResource: LoadableResource where ExtraData == Void {
    var fileName: String { get }
}


extension LoadableFileResource {
    static var category: ResourceCategory { .file }
}

struct FileResource: LoadableFileResource {
    
    typealias Response = String
    
    var fileName: String
}

class FileResourceLoader: ResourceLoader {
    static var categories: Set<ResourceCategory> = [.file]
    
    let publisher = CurrentValueSubject<String, Error>("")
    
    func load<Resource>(_ resource: Resource, with extraData: Resource.ExtraData) -> AnyPublisher<Resource.Response, Error> where Resource : LoadableResource {
        let thePublisher = publisher as! CurrentValueSubject<Resource.Response, Error>
        if let fileRes = resource as? FileResource {
            publisher.send(fileRes.fileName)
        }
        return thePublisher.eraseToAnyPublisher()
    }
}

class FilePassthroughLoader: ResourceLoader {
    static var categories: Set<ResourceCategory> = [.file]
    
    let publisher = PassthroughSubject<String, Error>()
    
    func load<Resource>(_ resource: Resource, with extraData: Resource.ExtraData) -> AnyPublisher<Resource.Response, Error> where Resource : LoadableResource {
        let thePublisher = publisher as! PassthroughSubject<Resource.Response, Error>
        return thePublisher.eraseToAnyPublisher()
    }
}


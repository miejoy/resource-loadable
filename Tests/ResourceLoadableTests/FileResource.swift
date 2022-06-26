//
//  FileResource.swift
//  
//
//  Created by 黄磊 on 2022/6/25.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import ResourceLoadable
import Combine

protocol FileResourceLoadable: ResourceLoadable where ExtraData == Void {
    var fileName: String { get }
}


extension FileResourceLoadable {
    static var category: ResourceCategory { .file }
}

struct FileResource: FileResourceLoadable {
    
    typealias Response = String
    
    var fileName: String
}

class FileHandler: ResourceHandleable {
    static var handlerCategorys: Set<ResourceCategory> = [.file]
    
    let publisher = CurrentValueSubject<String, Error>("")
    
    func load<Resource>(_ resource: Resource, with extraData: Resource.ExtraData) -> AnyPublisher<Resource.Response, Error> where Resource : ResourceLoadable {
        let thePublisher = publisher as! CurrentValueSubject<Resource.Response, Error>
        if let fileRes = resource as? FileResource {
            publisher.send(fileRes.fileName)
        }
        return thePublisher.eraseToAnyPublisher()
    }
}

class FilePassthroughHandler: ResourceHandleable {
    static var handlerCategorys: Set<ResourceCategory> = [.file]
    
    let publisher = PassthroughSubject<String, Error>()
    
    func load<Resource>(_ resource: Resource, with extraData: Resource.ExtraData) -> AnyPublisher<Resource.Response, Error> where Resource : ResourceLoadable {
        let thePublisher = publisher as! PassthroughSubject<Resource.Response, Error>
        return thePublisher.eraseToAnyPublisher()
    }
}


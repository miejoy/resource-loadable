//
//  FileResource.swift
//
//
//  Created by 黄磊 on 2022/6/25.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Combine
@testable import ResourceLoadable

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

final class FileResourceLoader: @unchecked Sendable, ResourceLoader {
    static let categories: Set<ResourceCategory> = [.file]
    let publisher = CurrentValueSubject<String, Error>("")

    func load<Resource: LoadableResource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) -> AnyPublisher<Resource.Response, Error> {
        let typed = publisher as! CurrentValueSubject<Resource.Response, Error>
        if let fileRes = resource as? FileResource {
            publisher.send(fileRes.fileName)
        }
        return typed.eraseToAnyPublisher()
    }
}

final class FilePassthroughLoader: @unchecked Sendable, ResourceLoader {
    static let categories: Set<ResourceCategory> = [.file]
    let publisher = PassthroughSubject<String, Error>()

    func load<Resource: LoadableResource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) -> AnyPublisher<Resource.Response, Error> {
        let typed = publisher as! PassthroughSubject<Resource.Response, Error>
        return typed.eraseToAnyPublisher()
    }
}

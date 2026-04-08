//
//  FileResource.swift
//
//
//  Created by 黄磊 on 2022/6/25.
//  Copyright © 2022 Miejoy. All rights reserved.
//

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
    
    var lastValue: String = ""
    var shouldFail: Bool = false
    var failureError: Error?

    func load<Resource: LoadableResource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) async throws -> AsyncStream<Resource.Response> {
        if shouldFail, let error = failureError {
            throw error
        }
        
        if let fileRes = resource as? FileResource {
            lastValue = fileRes.fileName
        }
        
        return AsyncStream { continuation in
            let typedValue = lastValue as! Resource.Response
            continuation.yield(typedValue)
            continuation.finish()
        }
    }
}

final class FilePassthroughLoader: @unchecked Sendable, ResourceLoader {
    static let categories: Set<ResourceCategory> = [.file]
    
    nonisolated(unsafe) var continuation: AsyncStream<String>.Continuation?

    func load<Resource: LoadableResource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) async throws -> AsyncStream<Resource.Response> {
        return AsyncStream { [weak self] continuation in
            // 存储 continuation 以便外部可以调用 send/finish
            self?.continuation = continuation
        } as! AsyncStream<Resource.Response>
    }
    
    func send(_ value: String) {
        continuation?.yield(value)
    }
    
    func finish() {
        continuation?.finish()
    }
}

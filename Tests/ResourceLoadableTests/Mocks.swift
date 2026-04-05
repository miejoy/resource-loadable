// Tests/ResourceLoadableTests/Mocks.swift
//
//  Mocks.swift
//
//  测试辅助类型

import Combine
@testable import ResourceLoadable

// MARK: - Box（用于在 @Sendable 回调中安全捕获结果）

final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

// MARK: - FileResource

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

// MARK: - FileResourceLoader（CurrentValueSubject，同步返回值）

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

// MARK: - FilePassthroughLoader（PassthroughSubject，不立即发值）

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

// MARK: - 测试 Observer

/// ResourceMonitor 观察者，强持有以防止弱引用提前释放
final class TestObserver: @unchecked Sendable, ResourceMonitorObserver {
    var events: [String] = []
    var addCount = 0
    var noLoaderCount = 0
    var duplicateCount = 0

    func receiveResourceEvent(_ event: ResourceEvent) {
        switch event {
        case .addResourceLoader: addCount += 1
        case .noLoaderFoundForResource: noLoaderCount += 1
        case .duplicateRegistration: duplicateCount += 1
        case .fatalError: break
        }
    }
}

// MARK: - 测试辅助

func resetResourceCenter(loader: (any ResourceLoader)? = nil) {
    ResourceCenter.shared.loaderMap = [:]
    if let loader { ResourceCenter.shared.registerLoader(loader) }
}

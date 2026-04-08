//
//  ResourceLoadableTests.swift
//
//
//  Created by 黄磊 on 2022/6/24.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Testing
@testable import ResourceLoadable

// MARK: - 测试辅助

/// 用于在 @Sendable 回调中安全捕获结果的包装类
final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

/// ResourceMonitor 观察者，强持有以防止弱引用提前释放
private final class TestObserver: @unchecked Sendable, ResourceMonitorObserver {
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

private func resetResourceCenter(loader: (any ResourceLoader)? = nil) {
    ResourceCenter.shared.loaderMap = [:]
    if let loader { ResourceCenter.shared.registerLoader(loader) }
}

// MARK: - ResourceLoadable 测试

@Suite("ResourceLoadable", .serialized)
struct ResourceLoadableTests {

    @Test("open() 持续接收值")
    func testOpenResource() async throws {
        resetResourceCenter()
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        var arrReceives = [String]()
        let stream = try await fileResource.open()
        
        for try await value in stream {
            arrReceives.append(value)
        }

        #expect(arrReceives.count == 1)
        #expect(arrReceives[0] == fileName)
    }

    @Test("openOnce() 只返回第一个值")
    func testOpenResourceOnce() async throws {
        resetResourceCenter()
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        let result = try await fileResource.openOnce()
        #expect(result == fileName)
    }

    @Test("无加载器时触发 noLoaderFoundForResource 并返回错误")
    func testErrorNoHandlerWhenOpenResourceOnce() async throws {
        resetResourceCenter()

        let observer = TestObserver()
        let token = ResourceMonitor.shared.addObserver(observer)
        defer { token.cancel() }

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        do {
            _ = try await fileResource.openOnce()
            Issue.record("Expected noLoaderForResource error")
        } catch let error as LoadResourceError {
            if case .noLoaderForResource = error {
                #expect(observer.noLoaderCount == 1)
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("重复注册同一类别触发 duplicateRegistration")
    func testDuplicateRegistration() {
        resetResourceCenter()

        let observer = TestObserver()
        let token = ResourceMonitor.shared.addObserver(observer)
        defer { token.cancel() }

        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)
        #expect(observer.duplicateCount == 0)

        ResourceCenter.shared.registerLoader(fileHandler)
        #expect(observer.duplicateCount == 1)
    }
}

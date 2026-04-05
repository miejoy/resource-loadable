//
//  ResourceLoadableTests.swift
//
//
//  Created by 黄磊 on 2022/6/24.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Testing
import Combine
@testable import ResourceLoadable

// MARK: - 测试辅助

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
    func testOpenResource() {
        resetResourceCenter()
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        var arrReceives = [String]()
        var isCompletion = false
        let cancellable = fileResource.open().sink { _ in
            isCompletion = true
        } receiveValue: { str in
            arrReceives.append(str)
        }

        #expect(!isCompletion)
        #expect(arrReceives.count == 1)
        #expect(arrReceives[0] == fileName)

        let newTest = "newText"
        fileHandler.publisher.send(newTest)
        #expect(!isCompletion)
        #expect(arrReceives.count == 2)
        #expect(arrReceives[0] == fileName)
        #expect(arrReceives[1] == newTest)

        fileHandler.publisher.send(completion: .finished)
        #expect(isCompletion)

        cancellable.cancel()
    }

    @Test("openOnce(callback:) 只返回第一个值")
    func testOpenResourceOnce() {
        resetResourceCenter()
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        let box = Box<String>("")
        let doneBox = Box(false)
        fileResource.openOnce { result in
            if case .success(let str) = result {
                box.value = str
            }
            doneBox.value = true
        }

        #expect(doneBox.value)
        #expect(box.value == fileName)
    }

    @Test("openOnce() Future 形式只返回第一个值")
    func testOpenResourceOnceWithFuture() {
        resetResourceCenter()
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        var response = ""
        var isCompletion = false
        let cancellable = fileResource.openOnce().sink { completion in
            if case .failure(_) = completion {
                Issue.record("completion with error")
            }
            isCompletion = true
        } receiveValue: { data in
            response = data
        }

        #expect(isCompletion)
        #expect(response == fileName)
        cancellable.cancel()
    }

    @Test("Publisher 完成未发值时返回 noValueReceiveWhenCompletion")
    func testNoResponseWhenOpenResourceOnce() {
        resetResourceCenter()
        let fileHandler = FilePassthroughLoader()
        ResourceCenter.shared.registerLoader(fileHandler)

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        let responseBox = Box<String?>(nil)
        let errorBox = Box<Error?>(nil)
        let doneBox = Box(false)
        fileResource.openOnce { result in
            switch result {
            case .success(let str): responseBox.value = str
            case .failure(let error): errorBox.value = error
            }
            doneBox.value = true
        }

        #expect(!doneBox.value)
        #expect(responseBox.value == nil)

        fileHandler.publisher.send(completion: .finished)
        #expect(doneBox.value)
        if case .noValueReceiveWhenCompletion = errorBox.value as? LoadResourceError {} else {
            Issue.record("no error response")
        }
        #expect(responseBox.value == nil)
    }

    @Test("无加载器时触发 noLoaderFoundForResource 并返回错误")
    func testErrorNoHandlerWhenOpenResourceOnce() {
        resetResourceCenter()

        let observer = TestObserver()
        let token = ResourceMonitor.shared.addObserver(observer)
        defer { token.cancel() }

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        let responseBox = Box<String?>(nil)
        let errorBox = Box<Error?>(nil)
        let doneBox = Box(false)
        fileResource.openOnce { result in
            switch result {
            case .success(let str): responseBox.value = str
            case .failure(let error): errorBox.value = error
            }
            doneBox.value = true
        }

        #expect(doneBox.value)
        #expect(responseBox.value == nil)
        #expect(observer.noLoaderCount == 1)
        if case .noLoaderForResource = errorBox.value as? LoadResourceError {} else {
            Issue.record("no error response")
        }
        #expect(responseBox.value == nil)
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

    @Test("openOnce() async/await 版本")
    func testOpenResourceOnceAsync() async throws {
        resetResourceCenter()
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)

        let result = try await fileResource.openOnce()
        #expect(result == fileName)
    }
}

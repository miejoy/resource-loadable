//
//  CombineUtilsTests.swift
//
//
//  Created by 黄磊 on 2022/12/7.
//

import Testing
import Combine
@testable import ResourceLoadable

// MARK: - 测试辅助

/// 用于在 @Sendable 回调中安全捕获结果的包装类
final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

// MARK: - CombineUtils 测试
@Suite("CombineUtils")
struct CombineUtilsTests {

    @Test("asFuture 异步成功")
    func testAsFutureSucceed() {
        var receiveValue = false
        var isCompletion = false
        let testStr = "test"

        let publish = PassthroughSubject<String, Error>()
        let cancellable = publish.asFuture().sink { _ in
            isCompletion = true
        } receiveValue: { str in
            #expect(str == testStr)
            receiveValue = true
        }

        #expect(!receiveValue)
        #expect(!isCompletion)

        publish.send(testStr)

        #expect(receiveValue)
        #expect(isCompletion)

        cancellable.cancel()
    }

    @Test("asFuture 同步成功（CurrentValueSubject）")
    func testAsFutureSucceedSync() {
        var receiveValue = false
        var isCompletion = false
        let testStr = "test"

        let publish = CurrentValueSubject<String, Error>(testStr)
        let cancellable = publish.asFuture().sink { _ in
            isCompletion = true
        } receiveValue: { str in
            #expect(str == testStr)
            receiveValue = true
        }

        #expect(receiveValue)
        #expect(isCompletion)

        cancellable.cancel()
    }

    @Test("asFuture 失败")
    func testAsFutureFailed() {
        var receiveValue = false
        var isCompletion = false
        let error: Error = LoadResourceError.resourceTypeError
        var finishError: Error? = nil

        let publish = PassthroughSubject<String, Error>()
        let cancellable = publish.asFuture().sink { completion in
            isCompletion = true
            if case .failure(let err) = completion {
                finishError = err
            }
        } receiveValue: { _ in
            receiveValue = true
        }

        #expect(!receiveValue)
        #expect(!isCompletion)

        publish.send(completion: .failure(error))

        #expect(!receiveValue)
        #expect(finishError != nil)
        if case .resourceTypeError = finishError as? LoadResourceError {} else {
            Issue.record("Error not match")
        }

        cancellable.cancel()
    }

    @Test("asFuture 完成未发值时返回 noValueReceiveWhenCompletion")
    func testAsFutureFailedNoData() {
        var receiveValue = false
        var isCompletion = false
        var finishError: Error? = nil

        let publish = PassthroughSubject<String, Error>()
        let cancellable = publish.asFuture().sink { completion in
            isCompletion = true
            if case .failure(let err) = completion {
                finishError = err
            }
        } receiveValue: { _ in
            receiveValue = true
        }

        #expect(!receiveValue)
        #expect(!isCompletion)

        publish.send(completion: .finished)

        #expect(!receiveValue)
        #expect(finishError != nil)
        if case .noValueReceiveWhenCompletion = finishError as? LoadResourceError {} else {
            Issue.record("Error not match")
        }

        cancellable.cancel()
    }

    @Test("receiveOnce 异步成功")
    func testReceiveOnceSucceed() {
        let box = Box<String?>(nil)
        let testStr = "test"

        let publish = PassthroughSubject<String, Error>()
        publish.receiveOnce { result in
            if case .success(let success) = result {
                box.value = success
            }
        }

        #expect(box.value == nil)

        publish.send(testStr)

        #expect(box.value == testStr)
    }

    @Test("receiveOnce 同步成功（CurrentValueSubject）")
    func testReceiveOnceSucceedSync() {
        let box = Box<String?>(nil)
        let testStr = "test"

        let publish = CurrentValueSubject<String, Error>(testStr)
        publish.receiveOnce { result in
            if case .success(let success) = result {
                box.value = success
            }
        }

        #expect(box.value == testStr)
    }

    @Test("receiveOnce 失败")
    func testReceiveOnceFailed() {
        let error: Error = LoadResourceError.resourceTypeError
        let box = Box<Error?>(nil)

        let publish = PassthroughSubject<String, Error>()
        publish.receiveOnce { result in
            if case .failure(let err) = result {
                box.value = err
            }
        }

        publish.send(completion: .failure(error))

        if case .resourceTypeError = box.value as? LoadResourceError {} else {
            Issue.record("Error not match")
        }
    }

    @Test("receiveOnce 完成未发值时返回 noValueReceiveWhenCompletion")
    func testReceiveOnceFailedNoData() {
        let box = Box<Error?>(nil)

        let publish = PassthroughSubject<String, Error>()
        publish.receiveOnce { result in
            if case .failure(let err) = result {
                box.value = err
            }
        }

        publish.send(completion: .finished)

        if case .noValueReceiveWhenCompletion = box.value as? LoadResourceError {} else {
            Issue.record("Error not match")
        }
    }

    @Test("watch 不中断数据流")
    func testWatchData() {
        let testStr = "test"
        var receiveValue = false
        var isCompletion = false
        var watchList: [String] = []
        let publish = PassthroughSubject<String, Error>()

        let cancellable = publish.watch { str in
            watchList.append(str)
        }
        .sink { _ in
            isCompletion = true
        } receiveValue: { _ in
            receiveValue = true
        }

        #expect(!receiveValue)
        #expect(!isCompletion)
        #expect(watchList == [])

        publish.send(testStr)

        #expect(receiveValue)
        #expect(!isCompletion)
        #expect(watchList == [testStr])

        publish.send(testStr)
        #expect(!isCompletion)
        #expect(watchList == [testStr, testStr])

        cancellable.cancel()
        #expect(!isCompletion)
        #expect(watchList == [testStr, testStr])

        publish.send(testStr)
        #expect(!isCompletion)
        #expect(watchList == [testStr, testStr])
    }

    @Test("Future.wait() async/await 版本")
    func testWaitFutureValue() async throws {
        let testStr = "test"
        let publish = PassthroughSubject<String, Error>()
        let future = publish.asFuture()

        publish.send(testStr)

        let output = try await future.wait()
        #expect(output == testStr)
        publish.send(completion: .finished)
    }
}

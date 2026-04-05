import Testing
import Combine
@testable import ResourceLoadable

@Suite("Combine+Utils", .serialized)
struct CombineUtilsTests {

    @Test("asFuture 异步收到值")
    func asFutureAsync() {
        let subject = PassthroughSubject<String, Error>()
        var received: String?
        var completed = false
        let cancellable = subject.asFuture().sink { _ in
            completed = true
        } receiveValue: { received = $0 }

        #expect(received == nil)
        subject.send("hello")
        #expect(received == "hello")
        #expect(completed)
        cancellable.cancel()
    }

    @Test("asFuture 同步收到值（CurrentValueSubject）")
    func asFutureSync() {
        let subject = CurrentValueSubject<String, Error>("sync")
        var received: String?
        let cancellable = subject.asFuture().sink { _ in } receiveValue: { received = $0 }
        #expect(received == "sync")
        cancellable.cancel()
    }

    @Test("asFuture 收到错误")
    func asFutureError() {
        let subject = PassthroughSubject<String, Error>()
        var error: Error?
        let cancellable = subject.asFuture().sink { completion in
            if case .failure(let e) = completion { error = e }
        } receiveValue: { _ in }

        subject.send(completion: .failure(LoadResourceError.resourceTypeError))
        if case .resourceTypeError = error as? LoadResourceError {} else {
            Issue.record("应收到 resourceTypeError")
        }
        cancellable.cancel()
    }

    @Test("asFuture 无值完成时收到 noValueReceiveWhenCompletion")
    func asFutureNoValue() {
        let subject = PassthroughSubject<String, Error>()
        var error: Error?
        let cancellable = subject.asFuture().sink { completion in
            if case .failure(let e) = completion { error = e }
        } receiveValue: { _ in }

        subject.send(completion: .finished)
        if case .noValueReceiveWhenCompletion = error as? LoadResourceError {} else {
            Issue.record("应收到 noValueReceiveWhenCompletion")
        }
        cancellable.cancel()
    }

    @Test("receiveOnce 异步收到值")
    func receiveOnceAsync() {
        let subject = PassthroughSubject<String, Error>()
        let box = Box<String?>(nil)
        subject.receiveOnce { result in
            if case .success(let v) = result { box.value = v }
        }
        #expect(box.value == nil)
        subject.send("once")
        #expect(box.value == "once")
    }

    @Test("receiveOnce 同步收到值（CurrentValueSubject）")
    func receiveOnceSync() {
        let subject = CurrentValueSubject<String, Error>("sync")
        let box = Box<String?>(nil)
        subject.receiveOnce { result in
            if case .success(let v) = result { box.value = v }
        }
        #expect(box.value == "sync")
    }

    @Test("receiveOnce 收到错误")
    func receiveOnceError() {
        let subject = PassthroughSubject<String, Error>()
        let box = Box<Error?>(nil)
        subject.receiveOnce { result in
            if case .failure(let e) = result { box.value = e }
        }
        subject.send(completion: .failure(LoadResourceError.resourceTypeError))
        if case .resourceTypeError = box.value as? LoadResourceError {} else {
            Issue.record("应收到 resourceTypeError")
        }
    }

    @Test("receiveOnce 无值完成时收到 noValueReceiveWhenCompletion")
    func receiveOnceNoValue() {
        let subject = PassthroughSubject<String, Error>()
        let box = Box<Error?>(nil)
        subject.receiveOnce { result in
            if case .failure(let e) = result { box.value = e }
        }
        subject.send(completion: .finished)
        if case .noValueReceiveWhenCompletion = box.value as? LoadResourceError {} else {
            Issue.record("应收到 noValueReceiveWhenCompletion")
        }
    }

    @Test("watch 不中断数据流，取消后不再接收")
    func watchData() {
        let subject = PassthroughSubject<String, Error>()
        var watched: [String] = []
        var received: [String] = []
        let cancellable = subject.watch { watched.append($0) }
            .sink { _ in } receiveValue: { received.append($0) }

        subject.send("a")
        subject.send("b")
        #expect(watched == ["a", "b"])
        #expect(received == ["a", "b"])
        cancellable.cancel()

        subject.send("c")
        #expect(watched == ["a", "b"])
    }

    @Test("Future.wait() async/await 版本")
    func futureWait() async throws {
        let subject = PassthroughSubject<String, Error>()
        let future = subject.asFuture()
        subject.send("waited")
        let output = try await future.wait()
        #expect(output == "waited")
    }
}

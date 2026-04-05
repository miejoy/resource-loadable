import Testing
import Combine
@testable import ResourceLoadable

/// 依赖共享单例（ResourceCenter/ResourceMonitor）的测试统一在此序列化 Suite 下运行，避免并发竞争
@Suite("ResourceLoadable（共享状态）", .serialized)
struct SharedStateTests {

    // MARK: - LoadableResource

    @Suite("LoadableResource")
    struct LoadableResourceTests {

        @Test("open() 持续推送值")
        func openContinuous() {
            let loader = FileResourceLoader()
            resetResourceCenter(loader: loader)
            let resource = FileResource(fileName: "hello")

            var received: [String] = []
            var completed = false
            let cancellable = resource.open().sink { _ in
                completed = true
            } receiveValue: { received.append($0) }

            #expect(!completed)
            #expect(received == ["hello"])

            loader.publisher.send("world")
            #expect(received == ["hello", "world"])

            loader.publisher.send(completion: .finished)
            #expect(completed)
            cancellable.cancel()
        }

        @Test("openOnce(callback:) 只返回第一个值")
        func openOnceCallback() {
            let loader = FileResourceLoader()
            resetResourceCenter(loader: loader)

            let box = Box<String?>(nil)
            FileResource(fileName: "once").openOnce { outcome in
                if case .success(let v) = outcome { box.value = v }
            }
            #expect(box.value == "once")
        }

        @Test("openOnce() 返回 Future")
        func openOnceFuture() {
            let loader = FileResourceLoader()
            resetResourceCenter(loader: loader)

            var result: String?
            var completed = false
            let cancellable = FileResource(fileName: "future").openOnce().sink { _ in
                completed = true
            } receiveValue: { result = $0 }

            #expect(completed)
            #expect(result == "future")
            cancellable.cancel()
        }

        @Test("无加载器时触发 noLoaderFoundForResource 并返回错误")
        func noLoader() {
            resetResourceCenter()
            let obs = TestObserver()
            let token = ResourceMonitor.shared.addObserver(obs)
            defer { token.cancel() }

            let box = Box<Error?>(nil)
            FileResource(fileName: "x").openOnce { result in
                if case .failure(let e) = result { box.value = e }
            }

            #expect(obs.noLoaderCount == 1)
            if case .noLoaderForResource = box.value as? LoadResourceError {} else {
                Issue.record("应收到 noLoaderForResource 错误")
            }
        }

        @Test("Publisher 完成未发值时收到 noValueReceiveWhenCompletion")
        func noValueBeforeCompletion() {
            let loader = FilePassthroughLoader()
            resetResourceCenter(loader: loader)

            let errorBox = Box<Error?>(nil)
            let doneBox = Box(false)
            FileResource(fileName: "empty").openOnce { result in
                if case .failure(let e) = result { errorBox.value = e }
                doneBox.value = true
            }
            #expect(!doneBox.value)

            loader.publisher.send(completion: .finished)
            #expect(doneBox.value)
            if case .noValueReceiveWhenCompletion = errorBox.value as? LoadResourceError {} else {
                Issue.record("应收到 noValueReceiveWhenCompletion 错误")
            }
        }

        @Test("重复注册同一类别触发 duplicateRegistration 事件")
        func duplicateRegistration() {
            resetResourceCenter()
            let obs = TestObserver()
            let token = ResourceMonitor.shared.addObserver(obs)
            defer { token.cancel() }

            let loader = FileResourceLoader()
            ResourceCenter.shared.registerLoader(loader)
            #expect(obs.duplicateCount == 0)

            ResourceCenter.shared.registerLoader(loader)
            #expect(obs.duplicateCount == 1)
        }

        @Test("openOnce() async/await 版本")
        func openOnceAsync() async throws {
            let loader = FileResourceLoader()
            resetResourceCenter(loader: loader)
            let result = try await FileResource(fileName: "async").openOnce()
            #expect(result == "async")
        }
    }

    // MARK: - ResourceMonitor

    @Suite("ResourceMonitor")
    struct ResourceMonitorTests {

        @Test("注册观察者后收到事件")
        func receiveEvents() {
            resetResourceCenter()
            let obs = TestObserver()
            let token = ResourceMonitor.shared.addObserver(obs)
            defer { token.cancel() }

            ResourceCenter.shared.registerLoader(FileResourceLoader())
            #expect(obs.addCount == 1)
        }

        @Test("取消 token 后不再收到事件")
        func cancelStopsEvents() {
            resetResourceCenter()
            let obs = TestObserver()
            let token = ResourceMonitor.shared.addObserver(obs)

            ResourceCenter.shared.registerLoader(FileResourceLoader())
            #expect(obs.addCount == 1)

            token.cancel()
            resetResourceCenter()
            ResourceCenter.shared.registerLoader(FileResourceLoader())
            #expect(obs.addCount == 1)
        }

        @Test("无加载器时触发 noLoaderFoundForResource 事件")
        func noLoaderEvent() {
            resetResourceCenter()
            let obs = TestObserver()
            let token = ResourceMonitor.shared.addObserver(obs)
            defer { token.cancel() }

            FileResource(fileName: "x").openOnce { _ in }
            #expect(obs.noLoaderCount == 1)
        }

        @Test("重复注册触发 duplicateRegistration 事件")
        func duplicateEvent() {
            resetResourceCenter()
            let obs = TestObserver()
            let token = ResourceMonitor.shared.addObserver(obs)
            defer { token.cancel() }

            let loader = FileResourceLoader()
            ResourceCenter.shared.registerLoader(loader)
            #expect(obs.duplicateCount == 0)
            ResourceCenter.shared.registerLoader(loader)
            #expect(obs.duplicateCount == 1)
        }
    }
}

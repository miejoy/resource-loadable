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

// MARK: - 测试 Observer

/// ResourceMonitor 观察者，强持有以防止弱引用提前释放
final class TestObserver: @unchecked Sendable, ResourceMonitorObserver {
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

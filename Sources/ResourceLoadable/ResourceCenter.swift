//
//  ResourceCenter.swift
//
//
//  Created by 黄磊 on 2022/6/18.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation

/// 资源中心
///
/// 负责管理所有已注册的 `ResourceLoader`，并将资源加载请求路由到对应的加载器。
/// 通过 `ResourceCenter.shared` 访问全局单例。
public final class ResourceCenter: Sendable {

    /// 全局共享单例
    public static let shared = ResourceCenter()

    /// 内部存储，所有可变状态集中于此
    final class Storage: @unchecked Sendable {
        /// 已注册的加载器映射表
        var loaderMap: [ResourceCategory: any ResourceLoader] = [:]
    }

    let storage: Storage = .init()

    private init() {}

    /// 已注册的加载器映射表（通过 resourceQueue 线程安全访问）
    var loaderMap: [ResourceCategory: any ResourceLoader] {
        get { DispatchQueue.syncOnResourceQueue { storage.loaderMap } }
        set { DispatchQueue.syncOnResourceQueue { storage.loaderMap = newValue } }
    }

    // MARK: - Public

    /// 注册资源加载器
    ///
    /// 将加载器支持的所有类别注册到资源中心。若同一类别已有加载器注册，
    /// 会触发 `ResourceMonitor` 的 `duplicateRegistration` 事件。
    ///
    /// - Parameter resourceLoader: 待注册的资源加载器
    public func registerLoader<Loader: ResourceLoader>(_ resourceLoader: Loader) {
        DispatchQueue.syncOnResourceQueue {
            Loader.categories.forEach { category in
                if let old = storage.loaderMap[category] {
                    ResourceMonitor.shared.record(event: .duplicateRegistration(old, resourceLoader))
                }
                storage.loaderMap[category] = resourceLoader
                ResourceMonitor.shared.record(event: .addResourceLoader(resourceLoader, category))
            }
        }
    }

    /// 加载资源（内部方法，由 `LoadableResource.open(with:)` 调用）
    func load<Resource: LoadableResource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) async throws -> AsyncStream<Resource.Response> {
        let loader = DispatchQueue.syncOnResourceQueue { storage.loaderMap[Resource.category] }
        guard let loader else {
            ResourceMonitor.shared.record(event: .noLoaderFoundForResource(Resource.category))
            throw LoadResourceError.noLoaderForResource(Resource.category)
        }
        return try await loader.load(resource, with: extraData)
    }
}

// MARK: - resourceQueue

extension DispatchQueue {
    private static let resourceQueueKey: DispatchSpecificKey<String> = .init()
    static let resourceQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.miejoy.resource_queue")
        queue.setSpecific(key: resourceQueueKey, value: queue.label)
        return queue
    }()

    /// 在 resourceQueue 上同步执行，已在队列上时直接执行避免死锁
    static func syncOnResourceQueue<T>(execute work: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: resourceQueueKey) == resourceQueue.label {
            return try work()
        }
        return try resourceQueue.sync(execute: work)
    }
}

// MARK: - LoadResourceError

/// 资源加载错误
public enum LoadResourceError: Error, Sendable {
    /// 找不到对应类别的加载器
    case noLoaderForResource(ResourceCategory)
    /// 流结束时未收到任何值
    case noValueReceiveWhenCompletion
    /// 资源类型不匹配
    case resourceTypeError
}

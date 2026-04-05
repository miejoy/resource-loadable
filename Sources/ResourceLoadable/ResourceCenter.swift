//
//  ResourceCenter.swift
//
//
//  Created by 黄磊 on 2022/6/18.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

/// 资源中心
///
/// 负责管理所有已注册的 `ResourceLoader`，并将资源加载请求路由到对应的加载器。
/// 通过 `ResourceCenter.shared` 访问全局单例。
public final class ResourceCenter: @unchecked Sendable {

    /// 全局共享单例
    public static let shared = ResourceCenter()

    var registerLoaderMap: [ResourceCategory: any ResourceLoader] = [:]

    private init() {}

    /// 注册资源加载器
    ///
    /// 将加载器支持的所有类别注册到资源中心。若同一类别已有加载器注册，
    /// 会触发 `ResourceMonitor` 的 `duplicateRegistration` 事件。
    ///
    /// - Parameter resourceLoader: 待注册的资源加载器
    public func registerLoader<Loader: ResourceLoader>(_ resourceLoader: Loader) {
        Loader.categories.forEach { category in
            if let oldResourceLoader = registerLoaderMap[category] {
                ResourceMonitor.shared.record(event: .duplicateRegistration(oldResourceLoader, resourceLoader))
            }
            registerLoaderMap[category] = resourceLoader
            ResourceMonitor.shared.record(event: .addResourceLoader(resourceLoader, category))
        }
    }

    /// 加载资源（内部方法，由 `LoadableResource.open(with:)` 调用）
    func load<Resource: LoadableResource>(_ resource: Resource, with extraData: Resource.ExtraData) -> AnyPublisher<Resource.Response, Error> {
        if let loader = registerLoaderMap[Resource.category] {
            return loader.load(resource, with: extraData)
        }
        ResourceMonitor.shared.record(event: .noLoaderFoundForResource(Resource.category))
        let publisher = PassthroughSubject<Resource.Response, Error>()
        publisher.send(completion: .failure(LoadResourceError.noLoaderForResource(Resource.category)))
        return publisher.eraseToAnyPublisher()
    }
}

/// 资源加载错误
public enum LoadResourceError: Error, Sendable {
    /// 找不到对应类别的加载器
    case noLoaderForResource(ResourceCategory)
    /// Publisher 完成时未收到任何值
    case noValueReceiveWhenCompletion
    /// 资源类型不匹配
    case resourceTypeError
}

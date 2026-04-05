//
//  ResourceMonitor.swift
//
//
//  Created by 黄磊 on 2022/6/19.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

/// 资源事件类型
public enum ResourceEvent: Sendable {
    /// 成功添加资源加载器
    case addResourceLoader(any ResourceLoader, ResourceCategory)
    /// 找不到对应类别的加载器
    case noLoaderFoundForResource(ResourceCategory)
    /// 重复注册同一类别的加载器
    case duplicateRegistration(_ old: any ResourceLoader, _ new: any ResourceLoader)
}

/// 资源事件观察者协议
public protocol ResourceMonitorObserver: AnyObject {
    /// 接收资源事件
    ///
    /// - Parameter event: 发生的资源事件
    func receiveResourceEvent(_ event: ResourceEvent)
}

/// 资源监听器
///
/// 用于监听 `ResourceCenter` 中发生的资源事件（加载器注册、重复注册、找不到加载器等）。
/// 通过 `ResourceMonitor.shared` 访问全局单例。
public final class ResourceMonitor: @unchecked Sendable {

    struct Observer {
        let observerId: Int
        weak var observer: ResourceMonitorObserver?
    }

    /// 全局共享单例
    public static let shared: ResourceMonitor = .init()

    var arrObservers: [Observer] = []
    var generateObserverId: Int = 0

    required init() {}

    /// 添加资源事件观察者
    ///
    /// - Parameter observer: 实现 `ResourceMonitorObserver` 的观察者
    /// - Returns: `AnyCancellable`，取消订阅时自动移除观察者
    public func addObserver(_ observer: ResourceMonitorObserver) -> AnyCancellable {
        generateObserverId += 1
        let observerId = generateObserverId
        arrObservers.append(.init(observerId: observerId, observer: observer))
        return AnyCancellable { [weak self] in
            if let index = self?.arrObservers.firstIndex(where: { $0.observerId == observerId }) {
                self?.arrObservers.remove(at: index)
            }
        }
    }

    /// 记录并分发资源事件给所有观察者
    @usableFromInline
    func record(event: ResourceEvent) {
        guard !arrObservers.isEmpty else { return }
        arrObservers.forEach { $0.observer?.receiveResourceEvent(event) }
    }
}

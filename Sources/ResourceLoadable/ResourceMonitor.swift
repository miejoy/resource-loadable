//
//  ResourceMonitor.swift
//
//
//  Created by 黄磊 on 2022/6/19.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine
import ModuleMonitor

/// 资源事件类型
public enum ResourceEvent: Sendable, MonitorEvent {
    /// 成功添加资源加载器
    case addResourceLoader(any ResourceLoader, ResourceCategory)
    /// 找不到对应类别的加载器
    case noLoaderFoundForResource(ResourceCategory)
    /// 重复注册同一类别的加载器
    case duplicateRegistration(_ old: any ResourceLoader, _ new: any ResourceLoader)
    /// 致命错误
    case fatalError(String)
}

/// 资源事件观察者协议
public protocol ResourceMonitorObserver: MonitorObserver {
    /// 接收资源事件
    ///
    /// - Parameter event: 发生的资源事件
    func receiveResourceEvent(_ event: ResourceEvent)
}

/// 资源监听器
///
/// 用于监听 `ResourceCenter` 中发生的资源事件（加载器注册、重复注册、找不到加载器等）。
/// 通过 `ResourceMonitor.shared` 访问全局单例。
public final class ResourceMonitor: ModuleMonitor<ResourceEvent> {

    /// 全局共享单例
    public nonisolated(unsafe) static let shared: ResourceMonitor = {
        ResourceMonitor { event, observer in
            (observer as? ResourceMonitorObserver)?.receiveResourceEvent(event)
        }
    }()

    /// 添加资源事件观察者
    ///
    /// - Parameter observer: 实现 `ResourceMonitorObserver` 的观察者
    /// - Returns: `AnyCancellable`，取消时自动移除观察者
    public func addObserver(_ observer: ResourceMonitorObserver) -> AnyCancellable {
        super.addObserver(observer)
    }

    /// 仅允许 ResourceMonitorObserver 类型的观察者
    public override func addObserver(_ observer: MonitorObserver) -> AnyCancellable {
        Swift.fatalError("Only ResourceMonitorObserver can observe ResourceMonitor")
    }
}

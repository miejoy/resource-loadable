//
//  ResourceMonitor.swift
//  
//
//  Created by 黄磊 on 2022/6/19.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

/// 存储器变化事件
public enum ResourceEvent {
    case addResourceLoader(any ResourceLoader, ResourceCategory)
    case noLoaderFoundForResource(ResourceCategory)
    case duplicateRegistration(_ old: any ResourceLoader, _ new: any ResourceLoader)
}

/// 存储器变化观察者
public protocol ResourceMonitorOberver: AnyObject {
    func receiveResourceEvent(_ event: ResourceEvent)
}

/// 存储器监听器
public final class ResourceMonitor {
        
    struct Observer {
        let observerId: Int
        weak var observer: ResourceMonitorOberver?
    }
    
    /// 监听器共享单例
    public static var shared: ResourceMonitor = .init()
    
    /// 所有观察者
    var arrObservers: [Observer] = []
    var generateObserverId: Int = 0
    
    required init() {
    }
    
    /// 添加观察者
    public func addObserver(_ observer: ResourceMonitorOberver) -> AnyCancellable {
        generateObserverId += 1
        let observerId = generateObserverId
        arrObservers.append(.init(observerId: generateObserverId, observer: observer))
        return AnyCancellable { [weak self] in
            if let index = self?.arrObservers.firstIndex(where: { $0.observerId == observerId}) {
                self?.arrObservers.remove(at: index)
            }
        }
    }
    
    /// 记录对应事件，这里只负责将所有事件传递给观察者
    @usableFromInline
    func record(event: ResourceEvent) {
        guard !arrObservers.isEmpty else { return }
        arrObservers.forEach { $0.observer?.receiveResourceEvent(event) }
    }
}

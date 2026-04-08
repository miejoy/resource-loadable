//
//  ResourceLoader.swift
//
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation

/// 资源加载器协议
///
/// 负责处理特定类别资源的实际加载逻辑。通过 `ResourceCenter.registerLoader(_:)` 注册后，
/// 框架会自动将对应类别的资源路由到此加载器。
public protocol ResourceLoader: AnyObject, Sendable {
    /// 此加载器支持的资源类别集合
    static var categories: Set<ResourceCategory> { get }

    /// 加载对应资源
    ///
    /// - Parameters:
    ///   - resource: 待加载的资源
    ///   - extraData: 资源的额外参数
    /// - Returns: 推送资源数据的异步流
    /// - Throws: 加载失败时抛出错误
    func load<Resource: LoadableResource>(
        _ resource: Resource,
        with extraData: Resource.ExtraData
    ) async throws -> AsyncStream<Resource.Response>
}

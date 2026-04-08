//
//  LoadableResource.swift
//
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation

/// 可被加载的资源协议
///
/// 代表可从非内存位置（如文件、网络接口等）获取固定格式数据的资源。
/// 实现此协议后，可通过 `ResourceCenter` 统一调度对应的 `ResourceLoader` 来加载。
public protocol LoadableResource {
    /// 资源类别，用于匹配对应的 `ResourceLoader`
    static var category: ResourceCategory { get }
    /// 传入的额外数据类型，不需要时设为 `Void`
    associatedtype ExtraData
    /// 返回数据类型，需实现 `Sendable`
    associatedtype Response: Sendable

    /// 打开资源并持续监听数据更新
    ///
    /// - Parameter extraData: 传入的额外参数
    /// - Returns: 持续推送数据的异步流
    /// - Throws: 加载失败时抛出错误
    func open(with extraData: ExtraData) async throws -> AsyncStream<Response>
}

extension LoadableResource {
    /// 打开资源并持续监听，默认通过 `ResourceCenter` 路由到对应 `ResourceLoader`
    ///
    /// - Parameter extraData: 传入的额外参数
    /// - Returns: 持续推送数据的异步流
    public func open(with extraData: ExtraData) async throws -> AsyncStream<Response> {
        try await ResourceCenter.shared.load(self, with: extraData)
    }

    /// 打开资源并只获取第一个值
    ///
    /// 从 `open(with:)` 返回的 AsyncStream 中读取第一个值即返回。
    /// 若流在未推送任何值的情况下结束，则抛出 `LoadResourceError.noValueReceiveWhenCompletion`。
    ///
    /// - Parameter extraData: 传入的额外参数
    /// - Returns: 解码后的响应数据
    /// - Throws: 加载失败时抛出错误
    public func openOnce(with extraData: ExtraData) async throws -> Response {
        for try await value in try await open(with: extraData) {
            return value
        }
        throw LoadResourceError.noValueReceiveWhenCompletion
    }
}

extension LoadableResource where ExtraData == Void {
    /// 打开资源并持续监听（无额外参数版本）
    ///
    /// - Returns: 持续推送数据的异步流
    public func open() async throws -> AsyncStream<Response> {
        try await open(with: ())
    }

    /// 打开资源并只获取第一个值（无额外参数版本）
    ///
    /// - Returns: 解码后的响应数据
    /// - Throws: 加载失败时抛出错误
    public func openOnce() async throws -> Response {
        try await openOnce(with: ())
    }
}

//
//  LoadableResource.swift
//
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

/// 可被加载的资源协议
///
/// 代表可从非内存位置（如文件、网络接口等）获取固定格式数据的资源。
/// 实现此协议后，可通过 `ResourceCenter` 统一调度对应的 `ResourceLoader` 来加载。
public protocol LoadableResource {
    /// 资源类别，用于匹配对应的 `ResourceLoader`
    static var category: ResourceCategory { get }
    /// 传入的额外数据类型，不需要时设为 `Void`
    associatedtype ExtraData
    /// 返回数据类型，需实现 `Decodable`
    associatedtype Response: Decodable

    /// 打开资源并持续监听数据更新
    ///
    /// - Parameter extraData: 传入的额外参数
    /// - Returns: 持续推送数据的 Publisher
    func open(with extraData: ExtraData) -> AnyPublisher<Response, Error>
}

extension LoadableResource {
    /// 打开资源并持续监听，默认通过 `ResourceCenter` 路由到对应 `ResourceLoader`
    ///
    /// - Parameter extraData: 传入的额外参数
    /// - Returns: 持续推送数据的 Publisher
    public func open(with extraData: ExtraData) -> AnyPublisher<Response, Error> {
        ResourceCenter.shared.load(self, with: extraData)
    }

    /// 打开资源并只获取第一个值，以 `Future` 形式返回
    ///
    /// - Parameter extraData: 传入的额外参数
    /// - Returns: 只返回一次结果的 Future
    public func openOnce(_ extraData: ExtraData) -> Future<Response, Error> {
        open(with: extraData).asFuture()
    }

    /// 打开资源并只获取第一个值，以回调形式返回
    ///
    /// - Parameters:
    ///   - extraData: 传入的额外参数
    ///   - callback: 结果回调
    public func openOnce(_ extraData: ExtraData, callback: @escaping @Sendable (Result<Response, Error>) -> Void) {
        open(with: extraData).receiveOnce(with: callback)
    }
}

extension LoadableResource where ExtraData == Void {
    /// 打开资源并持续监听（无额外参数版本）
    ///
    /// - Returns: 持续推送数据的 Publisher
    public func open() -> AnyPublisher<Response, Error> {
        open(with: Void())
    }

    /// 打开资源并只获取第一个值（无额外参数版本）
    ///
    /// - Returns: 只返回一次结果的 Future
    public func openOnce() -> Future<Response, Error> {
        openOnce(Void())
    }

    /// 打开资源并只获取第一个值，以回调形式返回（无额外参数版本）
    ///
    /// - Parameter callback: 结果回调
    public func openOnce(callback: @escaping @Sendable (Result<Response, Error>) -> Void) {
        openOnce(Void(), callback: callback)
    }
}

extension LoadableResource where Response: Sendable {
    /// 打开资源并只获取第一个值（async/await 版本）
    ///
    /// - Parameter extraData: 传入的额外参数
    /// - Returns: 解码后的响应数据
    /// - Throws: 加载失败时抛出错误
    public func openOnce(_ extraData: ExtraData) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.openOnce(extraData) { @Sendable result in
                continuation.resume(with: result)
            }
        }
    }
}

extension LoadableResource where ExtraData == Void, Response: Sendable {
    /// 打开资源并只获取第一个值（无额外参数 async/await 版本）
    ///
    /// - Returns: 解码后的响应数据
    /// - Throws: 加载失败时抛出错误
    public func openOnce() async throws -> Response {
        try await self.openOnce(Void())
    }
}

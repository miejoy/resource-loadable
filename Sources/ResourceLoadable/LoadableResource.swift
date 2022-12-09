//
//  LoadableResource.swift
//  
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

/// 可加载的资源
public protocol LoadableResource: Encodable {
    /// 资源类别
    static var category: ResourceCategory { get }
    /// 传入的额外数据格式，可以为 Void
    associatedtype ExtraData
    /// 返回数据格式
    associatedtype Response : Decodable

    /// 打开资源，并持续监听
    func open(with extraData: ExtraData) -> AnyPublisher<Response, Error>
}

extension LoadableResource {
    /// 默认打开资源方法
    public func open(with extraData: ExtraData) -> AnyPublisher<Response, Error> {
        ResourceCenter.shared.load(self, with: extraData)
    }
    
    /// 提供只打开读取一次的方法
    public func openOnce(_ extraData: ExtraData) -> Future<Response, Error> {
        open(with: extraData).asFuture()
    }
    
    /// 提供只打开读取一次的方法
    public func openOnce(_ extraData: ExtraData, callback: @escaping (Result<Response, Error>) -> Void) {
        open(with: extraData).receiveOnce(with: callback)
    }
}

extension LoadableResource where ExtraData == Void {
    public func open() -> AnyPublisher<Response, Error> {
        open(with: Void())
    }
    
    /// 提供只打开读取一次的方法
    public func openOnce() -> Future<Response, Error> {
        openOnce(Void())
    }
    
    public func openOnce(callback: @escaping (Result<Response, Error>) -> Void) {
        openOnce(Void(), callback: callback)
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension LoadableResource {
    public func openOnce(_ extraData: ExtraData) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.openOnce(extraData) { result in
                continuation.resume(with: result)
            }
        }
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension LoadableResource where ExtraData == Void {
    public func openOnce() async throws -> Response {
        try await self.openOnce(Void())
    }
}

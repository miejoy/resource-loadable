//
//  ResourceLoadable.swift
//  
//
//  Created by 黄磊 on 2022/6/17.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

public protocol ResourceLoadable: Encodable {
    /// 资源类别
    static var category: ResourceCategory { get }
    /// 传入的额外数据格式，可以为 Void
    associatedtype ExtraData
    /// 返回数据格式
    associatedtype Response : Decodable

    /// 打开资源，并持续监听
    func open(with extraData: ExtraData) -> AnyPublisher<Response, Error>
}

extension ResourceLoadable {
    /// 默认打开资源方法
    public func open(with extraData: ExtraData) -> AnyPublisher<Response, Error> {
        ResourceManager.shared.load(self, with: extraData)
    }
    
    /// 提供只打开读取一次的方法
    public func openOnce(_ extraData: ExtraData, callback: @escaping (Result<Response, Error>) -> Void) {
        var cancellable: AnyCancellable? = nil
        var didReceiveValue = false
        cancellable = open(with: extraData).sink { completion in
            switch completion {
            case .finished:
                if !didReceiveValue {
                    callback(.failure(LoadResourceError.noValueReceiveWhenCompletion))
                }
                break
            case .failure(let error):
                callback(.failure(error))
            }
        } receiveValue: { data in
            callback(.success(data))
            didReceiveValue = true
            cancellable?.cancel()
        }
    }
}

extension ResourceLoadable where ExtraData == Void {
    public func open() -> AnyPublisher<Response, Error> {
        open(with: Void())
    }
    
    public func openOnce(callback: @escaping (Result<Response, Error>) -> Void) {
        openOnce(Void(), callback: callback)
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension ResourceLoadable {
    public func openOnce(_ extraData: ExtraData) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.openOnce(extraData) { result in
                continuation.resume(with: result)
            }
        }
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension ResourceLoadable where ExtraData == Void {
    public func openOnce() async throws -> Response {
        try await self.openOnce(Void())
    }
}

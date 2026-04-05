//
//  Combine+Utils.swift
//
//
//  Created by 黄磊 on 2022/12/6.
//

import Combine
import Foundation

extension Publisher {
    /// 将 Publisher 转换为只返回第一个值的 Future
    ///
    /// 接收到第一个值后立即完成，若 Publisher 在未发送任何值的情况下完成，
    /// 则以 `LoadResourceError.noValueReceiveWhenCompletion` 失败。
    ///
    /// - Returns: 只返回一次结果的 Future
    public func asFuture() -> Future<Output, Error> {
        var cancellable: AnyCancellable?
        return Future<Output, Error> { promise in
            var didReceiveValue = false
            cancellable = self.sink { completion in
                if case .failure(let error) = completion {
                    promise(.failure(error))
                } else if !didReceiveValue {
                    promise(.failure(LoadResourceError.noValueReceiveWhenCompletion))
                }
                cancellable = nil
            } receiveValue: { value in
                promise(.success(value))
                didReceiveValue = true
                cancellable?.cancel()
            }
            if didReceiveValue {
                // 确保同步返回的场景不会出现内存泄漏
                cancellable?.cancel()
                cancellable = nil
            }
        }
    }

    /// 订阅并只接收第一个值，以回调形式返回结果
    ///
    /// 接收到第一个值后自动取消订阅。若 Publisher 在未发送任何值的情况下完成，
    /// 则以 `LoadResourceError.noValueReceiveWhenCompletion` 失败。
    ///
    /// - Parameter callback: 结果回调
    public func receiveOnce(with callback: @escaping @Sendable (Result<Output, Error>) -> Void) {
        var cancellable: AnyCancellable?
        var didReceiveValue = false
        cancellable = self.sink { completion in
            if case .failure(let error) = completion {
                callback(.failure(error))
            } else if !didReceiveValue {
                callback(.failure(LoadResourceError.noValueReceiveWhenCompletion))
            }
            cancellable = nil
        } receiveValue: { data in
            callback(.success(data))
            didReceiveValue = true
            cancellable?.cancel()
        }
        if didReceiveValue {
            cancellable?.cancel()
            cancellable = nil
        }
    }

    /// 在不中断数据流的情况下观察每个值
    ///
    /// - Parameter block: 每次收到值时执行的闭包
    /// - Returns: 透传原始值的 Publisher
    public func watch(with block: @escaping (Output) -> Void) -> Publishers.Map<Self, Output> {
        self.map { value in
            block(value)
            return value
        }
    }
}

extension Future where Output: Sendable {
    /// 等待 Future 的结果（async/await 版本）
    ///
    /// - Returns: Future 的输出值
    /// - Throws: Future 失败时抛出错误
    public func wait() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            self.receiveOnce { @Sendable result in
                continuation.resume(with: result)
            }
        }
    }
}

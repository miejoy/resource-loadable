//
//  Combile+Utils.swift
//  
//
//  Created by 黄磊 on 2022/12/6.
//

import Combine
import Foundation

extension Publisher {
    /// 转化为 Future
    public func asFuture() -> Future<Output, Error> {
        // 让 block 持有 cancellable
        var cancellable: AnyCancellable?
        return Future<Output, Error> { promise in
            var didReceiveValue = false
            cancellable = self.sink { completion in
                if case .failure(let error) = completion {
                    promise(.failure(error))
                } else if (!didReceiveValue) {
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
    
    /// 获取一次数据即完成
    public func receiveOnce(with callback: @escaping (Result<Output, Error>) -> Void) {
        var cancellable: AnyCancellable?
        var didReceiveValue = false
        cancellable = self.sink { completion in
            if case .failure(let error) = completion {
                callback(.failure(error))
            } else if (!didReceiveValue) {
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
    
    /// 观察其中数据
    public func watch(with block: @escaping (Output) -> Void) -> Publishers.Map<Self, Output> {
        self.map { value in
            block(value)
            return value
        }
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension Future {
    /// 等待结果
    public func wait() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            self.receiveOnce { result in
                continuation.resume(with: result)
            }
        }
    }
}

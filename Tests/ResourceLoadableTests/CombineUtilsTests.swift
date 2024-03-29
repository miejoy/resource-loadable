//
//  CombineUtilsTests.swift
//  
//
//  Created by 黄磊 on 2022/12/7.
//

import XCTest
import Combine
@testable import ResourceLoadable

class CombineUtilsTests: XCTestCase {
    
    func testAsFutureSucceed() {
        var receiveValue = false
        var isCompletion = false
        let testStr = "test"
        
        let publish = PassthroughSubject<String, Error>()
        let cancellable = publish.asFuture().sink { completion in
            isCompletion = true
        } receiveValue: { str in
            XCTAssertEqual(str, testStr)
            receiveValue = true
        }

        XCTAssertFalse(receiveValue)
        XCTAssertFalse(isCompletion)
        
        publish.send(testStr)
        
        XCTAssertTrue(receiveValue)
        XCTAssertTrue(isCompletion)
        
        cancellable.cancel()
    }
    
    func testAsFutureSucceedSync() {
        var receiveValue = false
        var isCompletion = false
        let testStr = "test"
        
        let publish = CurrentValueSubject<String, Error>(testStr)
        let cancellable = publish.asFuture().sink { completion in
            isCompletion = true
        } receiveValue: { str in
            XCTAssertEqual(str, testStr)
            receiveValue = true
        }
        
        XCTAssertTrue(receiveValue)
        XCTAssertTrue(isCompletion)
        
        cancellable.cancel()
    }
    
    func testAsFutureFailed() {
        var receiveValue = false
        var isCompletion = false
        let testStr = "test"
        let error: Error = LoadResourceError.resourceTypeError
        var finishError: Error? = nil
        
        let publish = PassthroughSubject<String, Error>()
        let cancellable = publish.asFuture().sink { completion in
            isCompletion = true
            if case .failure(let err) = completion {
                finishError = err
            }
        } receiveValue: { str in
            XCTAssertEqual(str, testStr)
            receiveValue = true
        }

        XCTAssertFalse(receiveValue)
        XCTAssertFalse(isCompletion)
        
        publish.send(completion: .failure(error))
        
        XCTAssertFalse(receiveValue)
        XCTAssertNotNil(finishError)
        
        if case .resourceTypeError = (finishError as? LoadResourceError) {
        } else {
            XCTFail("Error not match")
        }
                
        cancellable.cancel()
    }
    
    func testAsFutureFailedNoData() {
        var receiveValue = false
        var isCompletion = false
        let testStr = "test"
        var finishError: Error? = nil
        
        let publish = PassthroughSubject<String, Error>()
        let cancellable = publish.asFuture().sink { completion in
            isCompletion = true
            if case .failure(let err) = completion {
                finishError = err
            }
        } receiveValue: { str in
            XCTAssertEqual(str, testStr)
            receiveValue = true
        }

        XCTAssertFalse(receiveValue)
        XCTAssertFalse(isCompletion)
        
        publish.send(completion: .finished)
        
        XCTAssertFalse(receiveValue)
        XCTAssertNotNil(finishError)
        
        if case .noValueReceiveWhenCompletion = (finishError as? LoadResourceError) {
        } else {
            XCTFail("Error not match")
        }
                
        cancellable.cancel()
    }
    
    func testReceiveOnceSucceed() {
        var receiveValue: String? = nil
        let testStr = "test"
        
        let publish = PassthroughSubject<String, Error>()
        publish.receiveOnce { result in
            if case .success(let success) = result {
                receiveValue = success
            }
        }

        XCTAssertNil(receiveValue)
        
        publish.send(testStr)
        
        XCTAssertEqual(receiveValue, testStr)
    }
    
    func testReceiveOnceSucceedSync() {
        var receiveValue: String? = nil
        let testStr = "test"
        
        let publish = CurrentValueSubject<String, Error>(testStr)
        publish.receiveOnce { result in
            if case .success(let success) = result {
                receiveValue = success
            }
        }
        
        XCTAssertEqual(receiveValue, testStr)
    }
    
    func testReceiveOnceFailed() {
        let error: Error = LoadResourceError.resourceTypeError
        var finishError: Error? = nil
        
        let publish = PassthroughSubject<String, Error>()
        publish.receiveOnce { result in
            if case .failure(let err) = result {
                finishError = err
            }
        }
                
        publish.send(completion: .failure(error))
                
        if case .resourceTypeError = (finishError as? LoadResourceError) {
        } else {
            XCTFail("Error not match")
        }
    }
    
    func testReceiveOnceFailedNoData() {
        var finishError: Error? = nil
        
        let publish = PassthroughSubject<String, Error>()
        publish.receiveOnce { result in
            if case .failure(let err) = result {
                finishError = err
            }
        }
                
        publish.send(completion: .finished)
                
        if case .noValueReceiveWhenCompletion = (finishError as? LoadResourceError) {
        } else {
            XCTFail("Error not match")
        }
    }
    
    func testWatchData() {
        let testStr = "test"
        var receiveValue = false
        var isCompletion = false
        var watchList: [String] = []
        let publish = PassthroughSubject<String, Error>()
        
        let cancellable = publish.watch { str in
            watchList.append(str)
        }
        .sink { completion in
            isCompletion = true
        } receiveValue: { _ in
            receiveValue = true
        }

        XCTAssertFalse(receiveValue)
        XCTAssertFalse(isCompletion)
        XCTAssertEqual(watchList, [])
        
        publish.send(testStr)
        
        XCTAssertTrue(receiveValue)
        XCTAssertFalse(isCompletion)
        XCTAssertEqual(watchList, [testStr])
        
        publish.send(testStr)
        XCTAssertFalse(isCompletion)
        XCTAssertEqual(watchList, [testStr, testStr])
        
        cancellable.cancel()
        XCTAssertFalse(isCompletion)
        XCTAssertEqual(watchList, [testStr, testStr])
        
        publish.send(testStr)
        XCTAssertFalse(isCompletion)
        XCTAssertEqual(watchList, [testStr, testStr])
    }
    
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    func testWaitFutureValue() async throws {
        let testStr = "test"
        let publish = PassthroughSubject<String, Error>()
                
        let future = publish.asFuture()
        
        Task {
            publish.send(testStr)
        }
        
        let output = try await future.wait()
        
        XCTAssertEqual(output, testStr)
        publish.send(completion: .finished)
    }
}

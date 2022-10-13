//
//  ResourceLoadableTests.swift
//  
//
//  Created by 黄磊 on 2022/6/24.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Combine
import XCTest
@testable import ResourceLoadable

class ResourceLoadableTests: XCTestCase {
    
    func testOpenResource() {
        ResourceCenter.shared.registerLoaderMap = [:]
        
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)
        
        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)
        
        var arrReceives = [String]()
        var isCompletion = false
        let cancellable = fileResource.open().sink { completion in
            isCompletion = true
        } receiveValue: { str in
            arrReceives.append(str)
        }

        XCTAssert(!isCompletion)
        XCTAssertEqual(arrReceives.count, 1)
        XCTAssertEqual(arrReceives[0], fileName)
        
        let newTest = "newText"
        fileHandler.publisher.send(newTest)
        XCTAssert(!isCompletion)
        XCTAssertEqual(arrReceives.count, 2)
        XCTAssertEqual(arrReceives[0], fileName)
        XCTAssertEqual(arrReceives[1], newTest)
        
        fileHandler.publisher.send(completion: .finished)
        XCTAssert(isCompletion)
        
        cancellable.cancel()
    }
    
    func testOpenResourceOnce() {
        ResourceCenter.shared.registerLoaderMap = [:]
        
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)
        
        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)
        
        var response : String = ""
        var isCompletion = false
        fileResource.openOnce { result in
            if case .success(let str) = result {
                response = str
            }
            isCompletion = true
        }

        XCTAssert(isCompletion)
        XCTAssertEqual(response, fileName)
    }
    
    func testNoResponseWhenOpenResourceOnce() {
        ResourceCenter.shared.registerLoaderMap = [:]
        
        let fileHandler = FilePassthroughLoader()
        ResourceCenter.shared.registerLoader(fileHandler)
        
        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)
        
        var resposeStr: String? = nil
        var isCompletion = false
        var resposeError: Error? = nil
        fileResource.openOnce { result in
            switch result {
            case .success(let str):
                resposeStr = str
            case .failure(let error):
                resposeError = error
            }
            isCompletion = true
        }

        XCTAssert(!isCompletion)
        XCTAssertNil(resposeStr)
        
        fileHandler.publisher.send(completion: .finished)
        XCTAssert(isCompletion)
        if let error = resposeError as? LoadResourceError,
           case .noValueReceiveWhenCompletion = error {
        } else {
            XCTFail("no error response")
        }
        XCTAssertNil(resposeStr)
    }
    
    func testErrorNoHandlerWhenOpenResourceOnce() {
        ResourceCenter.shared.registerLoaderMap = [:]
        ResourceMonitor.shared.arrObservers = []
        class Oberver: ResourceMonitorOberver {
            var noHandlerErrorCall = false
            func receiveResourceEvent(_ event: ResourceEvent) {
                if case .noLoaderFoundForResource = event {
                    noHandlerErrorCall = true
                }
            }
        }
        let oberver = Oberver()
        let cancellable = ResourceMonitor.shared.addObserver(oberver)

        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)
        
        var resposeStr: String? = nil
        var isCompletion = false
        var resposeError: Error? = nil
        fileResource.openOnce { result in
            switch result {
            case .success(let str):
                resposeStr = str
            case .failure(let error):
                resposeError = error
            }
            isCompletion = true
        }

        XCTAssert(isCompletion)
        XCTAssertNil(resposeStr)
        XCTAssert(oberver.noHandlerErrorCall)
        if let error = resposeError as? LoadResourceError,
           case .noLoaderForResource = error {
        } else {
            XCTFail("no error response")
        }
        XCTAssertNil(resposeStr)
        
        cancellable.cancel()
    }
    
    func testDuplicateRegistration() {
        ResourceCenter.shared.registerLoaderMap = [:]
        ResourceMonitor.shared.arrObservers = []
        class Oberver: ResourceMonitorOberver {
            var duplicateRegistrationCall = false
            func receiveResourceEvent(_ event: ResourceEvent) {
                if case .duplicateRegistration = event {
                    duplicateRegistrationCall = true
                }
            }
        }
        let oberver = Oberver()
        let cancellable = ResourceMonitor.shared.addObserver(oberver)
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)
        XCTAssert(!oberver.duplicateRegistrationCall)
        
        ResourceCenter.shared.registerLoader(fileHandler)
        XCTAssert(oberver.duplicateRegistrationCall)
        
        cancellable.cancel()
    }
    
    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    func testOpenResourceOnceAsync() async throws {
        ResourceCenter.shared.registerLoaderMap = [:]
        
        let fileHandler = FileResourceLoader()
        ResourceCenter.shared.registerLoader(fileHandler)
        
        let fileName = "test"
        let fileResource = FileResource(fileName: fileName)
        
        var isCompletion = false
        let result = try await fileResource.openOnce()
        isCompletion = true
        
        XCTAssert(isCompletion)
        XCTAssertEqual(result, fileName)
    }
}


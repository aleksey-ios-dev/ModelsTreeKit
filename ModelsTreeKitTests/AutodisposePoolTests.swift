//
//  AutodisposePoolTests.swift
//  ModelsTreeKit
//
//  Created by aleksey on 21.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import XCTest
@testable import ModelsTreeKit

class AutodisposePoolTests: XCTestCase {
    let signalA = Signal<Int>()
    let signalB = Signal<String>()
    
    weak var subscriptionA: Disposable?
    weak var subscriptionB: Disposable?
    
    var pool = AutodisposePool()
    
    override func setUp() {
        subscriptionA = signalA.subscribeNext() { _ in }
        subscriptionB = signalB.subscribeNext() { _ in }
        
        subscriptionA?.putInto(pool)
        subscriptionB?.putInto(pool)
    }
    
    func testThatSubscriptionsAreNotNil() {
        XCTAssert(subscriptionA != nil)
        XCTAssert(subscriptionB != nil)
    }
    
    override func tearDown() {
        pool.drain()
        
        XCTAssert(subscriptionA == nil)
        XCTAssert(subscriptionB == nil)
    }
}

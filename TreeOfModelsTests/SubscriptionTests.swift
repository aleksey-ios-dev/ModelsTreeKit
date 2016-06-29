//
//  SubscriptionTests.swift
//  ModelsTreeKit
//
//  Created by aleksey on 21.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import XCTest
@testable import ModelsTreeKit

class SubscriptionDisposingTests: XCTestCase {
    let signal = Signal<Int>()
    weak var subscription: Disposable?

    override func setUp() {
        subscription = signal.subscribeNext() { _ in }
    }
    
    func testSubscriptionIsNotNil() {
        XCTAssert(subscription != nil)
    }
    
    override func tearDown() {
        subscription?.dispose()
        
        XCTAssert(subscription == nil)
    }
    
}

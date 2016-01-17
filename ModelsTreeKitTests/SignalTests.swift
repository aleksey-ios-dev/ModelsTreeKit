//
//  SignalTests.swift
//  ModelsTreeKit
//
//  Created by aleksey on 20.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import XCTest
@testable import ModelsTreeKit

class SignalTests: XCTestCase {
    func testThatSubscriptionPassesValue() {
        let signal = Signal<Int>()
        
        signal.subscribeNext { o in
            XCTAssertEqual(o, 5)
        }
        
        signal.sendNext(5)
    }
    
    func testThatFilterDoesntPassNonConformingValue() {
        let signal = Signal<Int>()
        
        signal.filter({object in return object > 6
            
        }).subscribeNext() { _ in
            XCTFail()
        }
        
        signal.sendNext(5)
    }

    func testThatMapTransformsValue() {
        let signal = Signal<Int>()
        
        signal.map { o in
            return "result is: \(o)"
            }.subscribeNext { o in
                XCTAssertEqual("result is: 5", o)
        }
        
        signal.sendNext(5)
    }

    func testThatCombineMergesTwoSignals() {
        let numberSignal = Signal<Int>()
        let textSignal = Signal<String>()
        
        numberSignal.combineLatest(textSignal).filter { number, text in
            return number != nil && text != nil
            }.map { number, string in
                print(string)
                return "\(number!) \(string!)"
        }.subscribeNext() { result in
            XCTAssertEqual("50 hello", result)
        }
        
        numberSignal.sendNext(50)
        textSignal.sendNext("hello")
    }
    
    func testThatBlockerBlocksSignal() {
        let testSignal = Signal<Int>()
        let blocker = Signal<Bool>()
        
        testSignal.blockWith(blocker)
        
        testSignal.subscribeNext { _ in
            XCTFail()
        }
        
        blocker.sendNext(true)
        testSignal.sendNext(4)
    }
}



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
                return "\(number!) \(string!)"
        }.subscribeNext() { result in
            XCTAssertEqual("50 hello", result)
        }
        
        numberSignal.sendNext(50)
        textSignal.sendNext("hello")
    }
  
  
  func testThatCombineBoundWorks() {
    let numberSignal = Signal<Int>()
    let textSignal = Signal<String>()
    
    numberSignal.combineBound(textSignal).filter { number, text in
      return number != nil && text != nil
      }.map { number, string in
        return "\(number) \(string)"
      }.subscribeNext() { result in
        print(result)
    }
    
    numberSignal.sendNext(50)
    textSignal.sendNext("hello")
    textSignal.sendNext("there")
    textSignal.sendNext("how")
    numberSignal.sendNext(20)
    numberSignal.sendNext(10)
    textSignal.sendNext("hoho")
    
    //TODO: add check
    
  }
  
  
    func testThatBlockerBlocksSignal() {
        let testSignal = Signal<Int>()
        let blocker = Signal<Bool>()
        
        testSignal.blockWith(blocker).subscribeNext { _ in
            XCTFail()
        }
        
        blocker.sendNext(true)
        testSignal.sendNext(4)
    }
  
  func testThatSkipRepeatingWorks() {
    let testSignal = Signal<Int>()
    let expectedResult = [1, 2, 3, 2]
    var actualResult = [Int]()

    testSignal.skipRepeating().subscribeNext {
      actualResult.append($0)
    }
    
    testSignal.sendNext(1)
    testSignal.sendNext(2)
    testSignal.sendNext(2)
    testSignal.sendNext(3)
    testSignal.sendNext(3)
    testSignal.sendNext(2)
    
    XCTAssertEqual(expectedResult, actualResult)
    
  }
  
  func testThatPassAscendingWorks() {
    let testSignal = Signal<Int>()
    let expectedResult = [-4, 1, 3, 4]
    var actualResult = [Int]()
    
    testSignal.passAscending().subscribeNext {
      actualResult.append($0)
    }
    
    testSignal.sendNext(-4)
    testSignal.sendNext(1)
    testSignal.sendNext(3)
    testSignal.sendNext(2)
    testSignal.sendNext(2)
    testSignal.sendNext(1)
    testSignal.sendNext(0)
    testSignal.sendNext(4)
    testSignal.sendNext(-4)
    
    XCTAssertEqual(expectedResult, actualResult)
    
  }
  
  func testThatPassDescendingWorks() {
    let testSignal = Signal<Int>()
    let expectedResult = [5, 3, 1, 0, -4]
    var actualResult = [Int]()
    
    testSignal.passDescending().subscribeNext {
      actualResult.append($0)
    }
    
    testSignal.sendNext(5)
    testSignal.sendNext(5)
    testSignal.sendNext(3)
    testSignal.sendNext(1)
    testSignal.sendNext(100)
    testSignal.sendNext(1)
    testSignal.sendNext(0)
    testSignal.sendNext(4)
    testSignal.sendNext(-4)
    
    XCTAssertEqual(expectedResult, actualResult)
    
  }
  
  func testThatReduceWorksForDifferentType() {
    let testSignal = Signal<Int>()
    let expectedResult = [1, 2, 3]
    var actualResult = [Int]()
    
    testSignal.reduce { (newValue, reducedValue) -> [Int] in
      var unwrappedReduced: [Int] = reducedValue ?? [Int]()
      unwrappedReduced.append(newValue)
  
      return unwrappedReduced
      }.subscribeNext {
        actualResult = $0
        print($0)
    }
    
    testSignal.sendNext(1)
    testSignal.sendNext(2)
    testSignal.sendNext(3)
    
    XCTAssertEqual(expectedResult, actualResult)
  }
  
  func testThatReduceWorksForSameType() {
    let testSignal = Signal<Int>()
    let expectedResult = 18
    var actualResult = 0
    
    testSignal.reduce { (newValue, reducedValue) -> Int in
      var unwrappedReduced = reducedValue ?? 0
      unwrappedReduced += newValue
      
      return unwrappedReduced
      }.subscribeNext {
        actualResult = $0
        print($0)
    }
    
    testSignal.sendNext(5)
    testSignal.sendNext(6)
    testSignal.sendNext(7)
    
    XCTAssertEqual(expectedResult, actualResult)
  }
  
  func testThatZipWorks() {
    let signalA = Signal<Int>()
    let signalB = Signal<String>()
    
    var result = [String]()
    
    signalA.zip(signalB).subscribeNext {
      result.append(("\($0)\($1)"))
      }.putInto(pool)
    
    signalB.sendNext("a")
    signalA.sendNext(1)
    signalA.sendNext(2)
    signalB.sendNext("b")
    signalA.sendNext(3)
    signalB.sendNext("c")
    signalB.sendNext("d")
    signalA.sendNext(4)
    
    XCTAssertEqual(result, ["1a", "2b", "3c", "4d"])
    
  }
  
}



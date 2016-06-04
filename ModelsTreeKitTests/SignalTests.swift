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
  
  var blocker = Pipe<Bool>()
  
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
    let numberSignal = Pipe<Int>()
    let textSignal = Pipe<String>()
    
    
    var result = [String]()
    
    numberSignal.combineLatest(textSignal).filter { number, text in
      return number != nil && text != nil
      }.map { number, string in
        return "\(number!) \(string!)"
      }.subscribeNext() {
        result.append($0)
    }
    
    numberSignal.sendNext(1)
    textSignal.sendNext("a")
    textSignal.sendNext("b")
    numberSignal.sendNext(2)
    numberSignal.sendNext(3)
    
    XCTAssertEqual(["1 a", "1 b", "2 b", "3 b"], result)
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
//    let blocker = Signal<Bool>()
    
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
    let testSignal = Pipe<Int>()
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
    
    print(result)
    XCTAssertEqual(result, ["1a", "2b", "3c", "4d"])
    
  }
  
  func testThatMergeWorks() {
    let sigA = Signal<Int>()
    let sigB = Signal<Int>()
    let sigC = Signal<Int>()
    
    var summary = [Int]()
    
    let signals: [Signal<Int>] = [sigA, sigB, sigC]
    
    Signals.merge(signals).subscribeNext { summary.append($0) }
    
    sigC.sendNext(1)
    sigB.sendNext(2)
    sigA.sendNext(3)
    sigC.sendNext(4)
    sigA.sendNext(5)
    
    XCTAssertEqual(summary, [1, 2, 3, 4, 5])
  }
  
  func testThatTwoBooleanSignalsAdd() {
    let sigA = Signal<Bool>()
    let sigB = Signal<Bool>()
    
    var result = [Bool]()
    sigA.and(sigB).subscribeNext { result.append($0) }
    
    sigA.sendNext(true)
    sigB.sendNext(true)
    sigB.sendNext(false)
    
    XCTAssertEqual(result, [false, true, false])
  }
  
  func testThatThreeBooleanSignalsAdd() {
    let sigA = Signal<Bool>()
    let sigB = Signal<Bool>()
    let sigC = Signal<Bool>()
    
    var result = [Bool]()
    sigA.and(sigB).and(sigC).subscribeNext {
      result.append($0)
    }
    
    sigA.sendNext(true)
    sigB.sendNext(true)
    sigB.sendNext(false)
    sigC.sendNext(false)
    sigC.sendNext(true)
    sigB.sendNext(true)
    
    XCTAssertEqual(result, [false, false, false, false, false, true])
  }
  
  func testThatOrWorks() {
    let sigA = Signal<Bool>()
    let sigB = Signal<Bool>()
    let sigC = Signal<Bool>()
    
    var result = [Bool]()
    sigA.or(sigB).or(sigC).subscribeNext {
      result.append($0)
    }
    
    sigA.sendNext(true)
    sigB.sendNext(true)
    sigB.sendNext(false)
    sigC.sendNext(true)
    sigC.sendNext(false)
    sigA.sendNext(false)
        
    XCTAssertEqual(result, [true, true, true, true, true, false])
  }
  
  func testThatXorWorks() {
    let sigA = Signal<Bool>()
    let sigB = Signal<Bool>()
    
    var result = [Bool]()
    
    sigA.xor(sigB).subscribeNext {
      result.append($0)
    }
    
    sigA.sendNext(true)
    sigB.sendNext(true)
    sigB.sendNext(false)
    sigA.sendNext(false)
    
    XCTAssertEqual(result, [true, false, true, false])
  }
  
  func testThatNotWorks() {
    let sigA = Signal<Bool>()
    
    var result = [Bool]()
    
    sigA.not().subscribeNext {
      result.append($0)
    }
    
    sigA.sendNext(true)
    sigA.sendNext(true)
    sigA.sendNext(false)
    sigA.sendNext(false)
    
    XCTAssertEqual(result, [false, false, true, true])
  }
  
  func testThatThreeBooleanSignalsAddByOperator() {
    let sigA = Signal<Bool>()
    let sigB = Signal<Bool>()
    let sigC = Signal<Bool>()
    
    var result = [Bool]()
    
    (sigA && sigB && sigC).subscribeNext {
      result.append($0)
    }
    
    sigA.sendNext(true)
    sigB.sendNext(true)
    sigB.sendNext(false)
    sigC.sendNext(false)
    sigC.sendNext(true)
    sigB.sendNext(true)
    
    XCTAssertEqual(result, [false, false, false, false, false, true])
  }
  
  func testThatOrWorksByOperator() {
    let sigA = Signal<Bool>()
    let sigB = Signal<Bool>()
    let sigC = Signal<Bool>()
    
    var result = [Bool]()
    (sigA || sigB || sigC).subscribeNext {
      result.append($0)
    }
    
    sigA.sendNext(true)
    sigB.sendNext(true)
    sigB.sendNext(false)
    sigC.sendNext(true)
    sigC.sendNext(false)
    sigA.sendNext(false)
    
    XCTAssertEqual(result, [true, true, true, true, true, false])
  }
  
  func testThatXorWorksByOperator() {
    let sigA = Signal<Bool>()
    let sigB = Signal<Bool>()
    
    var result = [Bool]()
    
    (sigA != sigB).subscribeNext {
      result.append($0)
    }
    
    sigA.sendNext(true)
    sigB.sendNext(true)
    sigB.sendNext(false)
    sigA.sendNext(false)
    
    XCTAssertEqual(result, [true, false, true, false])
  }
  
  func testThatNotWorksByOperator() {
    let sigA = Signal<Bool>()
    
    var result = [Bool]()
    
    (!sigA).subscribeNext {
      result.append($0)
    }
    
    sigA.sendNext(true)
    sigA.sendNext(true)
    sigA.sendNext(false)
    sigA.sendNext(false)
    
    XCTAssertEqual(result, [false, false, true, true])
  }
  
  func testFilterWithValidator() {
    let sigA = Signal<String>()
    
    var result = [String]()
    
    let validator = (Validator.longerThan(5) && !Validator.contains("@")) || Validator.hasPrefix("mr. ")
    
    sigA.filterValidWith(validator).subscribeNext { result.append($0) }
    
    sigA.sendNext("aleks")
    sigA.sendNext("@aleks")
    sigA.sendNext("@aleksey")
    sigA.sendNext("aleksey")
    sigA.sendNext("mr. aleksey")
    sigA.sendNext("mr. @aleksey")
    
    XCTAssertEqual(result, ["aleksey", "mr. aleksey", "mr. @aleksey"])
  }
  
  func testObservingWithOptions() {
    let sigA = Pipe<Int>()
    
    sigA.observable().subscribeWithOptions([.New, .Old]) { new, old, initial in
      print("new: \(new), old: \(old), initial: \(initial)")
    }
    
    sigA.sendNext(7)
    sigA.sendNext(9)
    sigA.sendNext(11)
    
    //TODO: write proper test
  }
  
}



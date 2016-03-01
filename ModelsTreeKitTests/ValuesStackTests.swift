//
//  ValuesStackTests.swift
//  ModelsTreeKit
//
//  Created by aleksey on 01.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

import Foundation
import XCTest
@testable import ModelsTreeKit

class ValuesStackTests: XCTestCase {
  func testStackCanKeepValues() {

    let stack = ValuesStack<Int>()
    stack.putValue(5)
    
    XCTAssertEqual(stack.values, [5])
    
  }
  
  func testStackCanKeepOnlyOneValueByDefault() {
    
    let stack = ValuesStack<Int>()
    stack.putValue(5)
    stack.putValue(2)
    
    XCTAssertEqual(stack.values, [2])
    
  }
  
  func testEmptyStackReturnsNilValue() {
    
    let stack = ValuesStack<Int>()
    
    XCTAssertNil(stack.takeValue())
    
  }
  
  func testThatTakeValueRemovesItFromStack() {
    
    let stack = ValuesStack<Int>()
    stack.putValue(4)
    
    XCTAssertEqual(4, stack.takeValue())
    XCTAssertNil(stack.takeValue())
    
  }
  
  func testThatTopValueDoesntChangeStack() {
    let stack = ValuesStack<Int>()
    stack.putValue(5)
    XCTAssertEqual(5, stack.topValue)
    XCTAssertEqual(5, stack.topValue)

  }
  
  func testThatStackCapacityCanBeIncreased() {
    let stack = ValuesStack<Int>(capacity: 5)

    stack.putValue(5)
    stack.putValue(6)
    stack.putValue(7)
    stack.putValue(20)
    stack.putValue(30)
    XCTAssertEqual([5, 6, 7, 20, 30], stack.values)
  }
  
  func testThatStackPopsOutOldestValues() {
    let stack = ValuesStack<Int>(capacity: 5)
    stack.putValue(5)
    stack.putValue(6)
    stack.putValue(7)
    stack.putValue(20)
    stack.putValue(30)
    stack.putValue(50)
    stack.putValue(100)
    XCTAssertEqual([7, 20, 30, 50, 100], stack.values)
  }
  
  func testThatZeroCapacityMakesStackInfinite() {
    let stack = ValuesStack<Int>()
    stack.capacity = 0
    stack.putValue(5)
    stack.putValue(6)
    stack.putValue(7)
    stack.putValue(20)
    stack.putValue(30)
    stack.putValue(50)
    stack.putValue(100)
    XCTAssertEqual([5, 6, 7, 20, 30, 50, 100], stack.values)
  }

}

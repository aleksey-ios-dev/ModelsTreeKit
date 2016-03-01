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
    stack.put(5)
    
    XCTAssertEqual(stack.values, [5])
    
  }
  
  func testStackCanKeepOnlyOneValueByDefault() {
    
    let stack = ValuesStack<Int>()
    stack.put(5)
    stack.put(2)
    
    XCTAssertEqual(stack.values, [2])
    
  }
  
  func testEmptyStackReturnsNilValue() {
    
    let stack = ValuesStack<Int>()
    
    XCTAssertNil(stack.takeFromTop())
    
  }
  
  func testThatTakeValueRemovesItFromStack() {
    
    let stack = ValuesStack<Int>()
    stack.put(4)
    
    XCTAssertEqual(4, stack.takeFromTop())
    XCTAssertNil(stack.takeFromTop())
    
  }
  
  func testThatTopValueDoesntChangeStack() {
    let stack = ValuesStack<Int>()
    stack.put(5)
    XCTAssertEqual(5, stack.topValue)
    XCTAssertEqual(5, stack.topValue)

  }
  
  func testThatStackCapacityCanBeIncreased() {
    let stack = ValuesStack<Int>(capacity: 5)

    stack.put(5)
    stack.put(6)
    stack.put(7)
    stack.put(20)
    stack.put(30)
    XCTAssertEqual([5, 6, 7, 20, 30], stack.values)
  }
  
  func testThatStackPopsOutOldestValues() {
    let stack = ValuesStack<Int>(capacity: 5)
    stack.put(5)
    stack.put(6)
    stack.put(7)
    stack.put(20)
    stack.put(30)
    stack.put(50)
    stack.put(100)
    XCTAssertEqual([7, 20, 30, 50, 100], stack.values)
  }
  
  func testThatZeroCapacityMakesStackInfinite() {
    let stack = ValuesStack<Int>()
    stack.capacity = 0
    stack.put(5)
    stack.put(6)
    stack.put(7)
    stack.put(20)
    stack.put(30)
    stack.put(50)
    stack.put(100)
    XCTAssertEqual([5, 6, 7, 20, 30, 50, 100], stack.values)
  }

}

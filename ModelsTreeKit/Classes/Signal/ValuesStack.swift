//
//  ValuesStack.swift
//  ModelsTreeKit
//
//  Created by aleksey on 01.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

public class ValuesStack<T> {
  
  var capacity: Int
  
  var locked = false
  var values = [T]()
  
  public var topValue: T? {
    return values.last
  }
  
  public var bottomValue: T? {
    return values.first
  }
  
  public init(capacity: Int = 1) {
    self.capacity = capacity
  }
  
  public func put(value: T?) {
    guard !locked else { return }
    guard let value = value else { return }
    values.append(value)    
    if values.count > capacity && capacity != 0 { values.removeFirst() }
  }
  
  func takeFromTop() -> T? {
    guard !locked else { return values.last }
    let value = values.last
    
    if !values.isEmpty { values.removeLast() }
    
    return value
  }
  
  func takeFromBottom() -> T? {
    guard !locked else { return values.first }
    let value = values.first
    if !values.isEmpty { values.removeFirst() }
    
    return value
  }
  
  public func drain() {
    values = []
  }
  
}
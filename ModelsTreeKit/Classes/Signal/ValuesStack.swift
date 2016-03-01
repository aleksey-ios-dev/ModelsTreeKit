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
  
  var values = [T]()
  
  public var topValue: T? {
    return values.last
  }
  
  public init(capacity: Int = 1) {
    self.capacity = capacity
  }
  
  public func putValue(value: T?) {
    guard let value = value else { return }
    values.append(value)    
    if values.count > capacity && capacity != 0 { values.removeFirst() }
  }
  
  func takeValue() -> T? {
    let value = values.last
    
    if !values.isEmpty { values.removeLast() }
    
    return value
  }
  
  public func drain() {
    values = []
  }
  
}
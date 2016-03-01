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
  
  var topValue: T? {
    return values.last
  }
  
  init(capacity: Int = 1) {
    self.capacity = capacity
  }
  
  func putValue(value: T) {
    values.append(value)    
    if values.count > capacity && capacity != 0 { values.removeFirst() }
  }
  
  func takeValue() -> T? {
    let value = values.last
    
    if !values.isEmpty { values.removeLast() }
    
    return value
  }
  
}
//
//  Signal+Conversion.swift
//  ModelsTreeKit
//
//  Created by aleksey on 04.06.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

public extension Signal {
  
  public func observable() -> Observable<T> {
    let nextSignal = Observable<T>()
    subscribeNext { [weak nextSignal] in nextSignal?.sendNext($0) }.putInto(nextSignal.pool)
    chainSignal(nextSignal)
    if let value = self.value { nextSignal.sendNext(value) }
    
    return nextSignal
  }
  
  public func pipe() -> Pipe<T> {
    let nextSignal = Pipe<T>()
    subscribeNext { [weak nextSignal] in nextSignal?.sendNext($0) }.putInto(nextSignal.pool)
    chainSignal(nextSignal)
    
    if let value = self.value { nextSignal.sendNext(value) }
    
    return nextSignal
  }
  
}
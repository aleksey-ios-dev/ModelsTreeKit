//
//  Signal+Equatable.swift
//  ModelsTreeKit
//
//  Created by aleksey on 03.06.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension Signal where T: Equatable {
  
  //Stops the value from being passed more than once
  
  //BUG: locks propagation of initial value
  public func skipRepeating() -> Signal<T> {
    
    var nextSignal: Signal<T>!
    if let observableSelf = self as? Observable<T> {
        nextSignal = Observable<T>(observableSelf.value)
    }
    else { nextSignal = Pipe<T>() }

    observable().subscribeWithOptions([.New, .Old]) { (new, old, initial) in
      if let new = new, new != old {
        nextSignal.sendNext(new)
      }
    }.putInto(pool)
    
    return nextSignal
  }
  
}

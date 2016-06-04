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
    let persistentSelf = observable()
    return persistentSelf.filter { [weak persistentSelf] newValue in return newValue != persistentSelf?.value }
  }
  
}
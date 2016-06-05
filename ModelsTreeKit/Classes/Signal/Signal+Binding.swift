//
//  Signal+Binding.swift
//  ModelsTreeKit
//
//  Created by aleksey on 04.06.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

public extension Signal {
  
  //TODO: implement takeUntil, take until deinit signal
  
  public func bindTo(keyPath keyPath: String, of object: NSObject) {
    subscribeNext { [weak object] in
      if let value = $0 as? AnyObject, let object = object {
        object.setValue(value, forKey: keyPath)
      }
    }
  }
  
  public func bindTo(observable: Observable<T>) {
    subscribeNext { [weak observable] in
      guard let observable = observable else { return }
      observable.value = $0
    }.putInto(observable.pool)
  }
}
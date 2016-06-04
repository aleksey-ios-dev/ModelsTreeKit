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
    subscribeNext { [unowned object] in
      if let value = $0 as? AnyObject {
        object.setValue(value, forKey: keyPath)
      }
    }
  }
}
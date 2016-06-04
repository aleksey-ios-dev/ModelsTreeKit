//
//  Signal.swift
//  SessionSwift
//
//  Created by aleksey on 14.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

class DeinitNotifier: NSObject {
  
  var signal = Pipe<Void>()
  
  deinit {
    signal.sendCompleted()
  }
  
}
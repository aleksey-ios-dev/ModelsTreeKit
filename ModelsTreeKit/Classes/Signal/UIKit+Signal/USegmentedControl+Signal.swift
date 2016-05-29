//
//  USegmentedControl+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UISegmentedControl {
  
  public var selectedSegmentIndexSignal: Signal<Int> {
    get { return signalForControlEvents(.ValueChanged).map { ($0 as! UISegmentedControl).selectedSegmentIndex } }
  }
  
}


//
//  UISlider+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UISlider {
  
  public var valueChangeSignal: Signal<Float> {
    get { return signalEmitter.signalForControlEvents(.ValueChanged).map { ($0.0 as! UISlider).value } }
  }
  
  public var reachMaximumSignal: Signal<Bool> {
    get {
      return valueChangeSignal.map { _ in return true }
    }
  }
  
  public var reachMinimumSignal: Signal<Bool> {
    get {
      return valueChangeSignal.map { [weak self] in self?.minimumValue == $0 }.skipRepeating()
    }
  }
  
}
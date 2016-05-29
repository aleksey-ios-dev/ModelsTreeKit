//
//  UISlider+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UISlider {
  
  public var valueSignal: Signal<Float> {
    get { return signalForControlEvents(.ValueChanged).map { ($0 as! UISlider).value }.skipRepeating() }
  }
  
  public var reachMaximumSignal: Signal<Bool> {
    get {
      return valueSignal.filter { [weak self] in
        return self!.maximumValue == $0
      }.map { _ in return true}
    }
  }
  
  public var reachMinimumSignal: Signal<Bool> {
    get {
      return valueSignal.filter { [weak self] in
        return self!.minimumValue == $0
        }.map { _ in return true}
    }
  }
  
}
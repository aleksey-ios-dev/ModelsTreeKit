//
//  UISwitch+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UISwitch {
  public var onSignal: Signal<Bool> {
    get { return signalEmitter.signalForControlEvents(.ValueChanged).map { ($0 as! UISwitch).on } }
  }
}
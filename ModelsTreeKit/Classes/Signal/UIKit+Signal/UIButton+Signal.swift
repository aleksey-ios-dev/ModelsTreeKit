//
//  UIButton+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 13.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UIButton {
  
  public var selectionSignal: Signal<Void> {
    get { return signalForControlEvents(.TouchUpInside).map { _ in return Void() } }
  }

}
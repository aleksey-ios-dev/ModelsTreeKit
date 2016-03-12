//
//  UITextField+Signal.swift
//  SessionSwift
//
//  Created by aleksey on 24.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import UIKit

extension UITextField {
  
  public var textSignal: Signal<String> {
    get { return signalEmitter.signalForControlEvents(.EditingChanged).map { ($0 as! UITextField).text! } }
  }
  
}

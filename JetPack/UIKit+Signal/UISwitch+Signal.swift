//
//  UISwitch+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import UIKit

extension UISwitch {
  
  public var onSignal: Observable<Bool> {
    get {
      let observable = Observable<Bool>(isOn)
      signalForControlEvents(.valueChanged).map { ($0 as! UISwitch).isOn }.bind(to: observable)
      
      return observable
    }
  }
  
}

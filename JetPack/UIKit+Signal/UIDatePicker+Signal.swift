//
//  UIDatePicker+Signal.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 19.10.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import UIKit

extension UIDatePicker {
  
  public var dateSignal: Observable<Date> {
    get {
      let observable = Observable<Date>(date)
      signalForControlEvents(.valueChanged).map { ($0 as! UIDatePicker).date }.bind(to: observable)
      
      return observable
    }
  }
  
}

//
//  UIControl+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UIControl {
  
  public func signalForControlEvents(events: UIControlEvents) -> Signal<UIControl> {
    return signalEmitter.signalForControlEvents(events)
  }
  
}

class ControlSignalEmitter: NSObject {
  
  private static var EmitterHandler: Int = 0
  private weak var control: UIControl!
  private var signalsMap = [UInt: Signal<UIControl>]()
  
  init(control: UIControl) {
    self.control = control
    super.init()
  }
  
  func signalForControlEvents(events: UIControlEvents) -> Signal<UIControl> {
    //REWRITE WITH MERGE
    
    
    let correspondingSignal = signalsMap[events.rawValue] ?? Signal<UIControl>(value: control, transient: true)
    signalsMap[events.rawValue] = correspondingSignal
    
    
    if events.contains(.ValueChanged) {
      control.addTarget(self, action: "handleValueChanged:", forControlEvents: .ValueChanged)
    }
    
    if events.contains(.EditingChanged) {
      control.addTarget(self, action: "handleEditingChanged:", forControlEvents: .EditingChanged)
    }
    
    return correspondingSignal
  }
  
  @objc
  func handleValueChanged(control: UIControl) {
    signalsMap[UIControlEvents.ValueChanged.rawValue]?.sendNext(control)
  }
  
  @objc
  func handleEditingChanged(control: UIControl) {
    signalsMap[UIControlEvents.EditingChanged.rawValue]?.sendNext(control)
  }
}

extension UIControl {
  
  var signalEmitter: ControlSignalEmitter {
    get {
      var emitter = objc_getAssociatedObject(self, &ControlSignalEmitter.EmitterHandler) as? ControlSignalEmitter
      if (emitter == nil) {
        emitter = ControlSignalEmitter(control: self)
        objc_setAssociatedObject(self, &ControlSignalEmitter.EmitterHandler, emitter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
      
      return emitter!
    }
  }
  
}
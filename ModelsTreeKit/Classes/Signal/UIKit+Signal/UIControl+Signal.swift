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
    
    initializeSignalsMap()
  }
  
  func initializeSignalsMap() {
    
    //Hot signals
    signalsMap[UIControlEvents.ValueChanged.rawValue] = Signal<UIControl>(value: control)
    signalsMap[UIControlEvents.EditingChanged.rawValue] = Signal<UIControl>(value: control)
    
    //Cold signals
    signalsMap[UIControlEvents.EditingDidEnd.rawValue] = Signal<UIControl>()
    signalsMap[UIControlEvents.EditingDidEndOnExit.rawValue] = Signal<UIControl>()
    signalsMap[UIControlEvents.EditingDidEndOnExit.rawValue] = Signal<UIControl>()
  
  }
  
  func signalForControlEvents(events: UIControlEvents) -> Signal<UIControl> {
    var correspondingSignals = [Signal<UIControl>]()
    
    for (key, signal) in signalsMap {
      if events.contains(UIControlEvents(rawValue: key)) {
        correspondingSignals.append(signal)
      }
    }

    if events.contains(.ValueChanged) {
      control.addTarget(self, action: "valueChanged:", forControlEvents: .ValueChanged)
    }

    if events.contains(.EditingChanged) {
      control.addTarget(self, action: "editingChanged:", forControlEvents: .EditingChanged)
    }
    
    if events.contains(.EditingDidEnd) {
      control.addTarget(self, action: "editingDidEnd:", forControlEvents: .EditingDidEnd)
    }
    
    if events.contains(.EditingDidEndOnExit) {
      control.addTarget(self, action: "editingDidEndOnExit:", forControlEvents: .EditingDidEndOnExit)
    }
    
    if events.contains(.TouchUpInside) {
      control.addTarget(self, action: "touchUpInside:", forControlEvents: .TouchUpInside)
    }
    
    return Signals.merge(correspondingSignals)
  }
  
  @objc
  func valueChanged(control: UIControl) {
    signalsMap[UIControlEvents.ValueChanged.rawValue]?.sendNext(control)
  }
  
  @objc
  func editingChanged(control: UIControl) {
    signalsMap[UIControlEvents.EditingChanged.rawValue]?.sendNext(control)
  }
  
  @objc
  func editingDidEnd(control: UIControl) {
    signalsMap[UIControlEvents.EditingDidEnd.rawValue]?.sendNext(control)
  }
  
  @objc
  func editingDidEndOnExit(control: UIControl) {
    signalsMap[UIControlEvents.EditingDidEndOnExit.rawValue]?.sendNext(control)
  }
  
  @objc
  func touchUpInside(control: UIControl) {
    signalsMap[UIControlEvents.TouchUpInside.rawValue]?.sendNext(control)
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
//
//  UIControl+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UIControl {
  
  public func signalForControlEvents(events: UIControlEvents) -> Signal<(UIControl, UIControlEvents)> {
    return signalEmitter.signalForControlEvents(events)
  }
  
}

class ControlSignalEmitter: NSObject {
  
  private static var EmitterHandler: Int = 0
  private weak var control: UIControl!
  private var signalsMap = [UInt: Signal<(UIControl, UIControlEvents)>]()
  
  init(control: UIControl) {
    self.control = control
    super.init()
    print("create emitter\(self)")

  }
  
  func signalForControlEvents(events: UIControlEvents) -> Signal<(UIControl, UIControlEvents)> {
    if !signalsMap.keys.contains(events.rawValue) {
      control.addTarget(self, action: "handleControlEvent:controlEvent:", forControlEvents: events)
    }
  
    let correspondingSignal = signalsMap[events.rawValue] ?? Signal<(UIControl, UIControlEvents)>()
    signalsMap[events.rawValue] = correspondingSignal
    
    return correspondingSignal
  }
  
  @objc
  func handleControlEvent(control: UIControl, controlEvent: UIEvent) {
    guard controlEvent.type.rawValue != 0 else {
      signalsMap.values.forEach { $0.sendNext((control, controlEvent.type)) }
      return
    }
    
    signalsMap.keys.forEach { events in
      if controlEvent.type.contains(UIControlEvents(rawValue: events)) {
        signalsMap[events]?.sendNext(control, controlEvent.type)
      }
    }
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
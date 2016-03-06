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
  
  private static var EmitterHandler: UInt8 = 0
  private weak var control: UIControl!
  private var signalsMap = [UInt: [Signal<(UIControl, UIControlEvents)>]]()
  
  init(control: UIControl) {
    self.control = control
    super.init()
  }
  
  func signalForControlEvents(events: UIControlEvents) -> Signal<(UIControl, UIControlEvents)> {
    control.addTarget(self, action: "handleControlEvent:controlEvent:", forControlEvents: events)

    let signal = Signal<(UIControl, UIControlEvents)>()
    var correspondingSignalsArray = signalsMap[events.rawValue] ?? []
    correspondingSignalsArray.append(signal)
    signalsMap[events.rawValue] = correspondingSignalsArray
    return signal
  }
  
  @objc
  func handleControlEvent(control: UIControl, controlEvent: UIControlEvents) {
//    guard controlEvent.rawValue != 0 else {
//      signalsMap.values.forEach { $0.forEach { $0.sendNext((control, controlEvent)) } }
//      return
//    }
    
    signalsMap.keys.forEach { events in
      if controlEvent.contains(UIControlEvents(rawValue: events)) {
        signalsMap[events]?.forEach { $0.sendNext(control, controlEvent) }
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
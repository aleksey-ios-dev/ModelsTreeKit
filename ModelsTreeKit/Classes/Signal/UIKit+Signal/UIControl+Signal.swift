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
  private let controlProxy = ControlProxy(object: "")
  
  init(control: UIControl) {
    self.control = control
    super.init()
    
    initializeSignalsMap()
  }
  
  func initializeSignalsMap() {
    
    for (eventRawValue, _) in eventsList {
      signalsMap[eventRawValue] = Signal<UIControl>()
    }
  
    for (eventRawValue, selectorString) in eventsList {
      let signal = signalsMap[eventRawValue]
      controlProxy.registerBlock({ [weak signal, unowned self] in
        signal?.sendNext(self.control)
        }, forKey: selectorString)
      control.addTarget(self.controlProxy, action: NSSelectorFromString(selectorString), forControlEvents: UIControlEvents(rawValue: eventRawValue))
    }
  
  }
  
  func signalForControlEvents(events: UIControlEvents) -> Signal<UIControl> {
    var correspondingSignals = [Signal<UIControl>]()
    
    for event in eventsList.keys {
      if events.contains(UIControlEvents(rawValue: event)) {
        correspondingSignals.append(signalsMap[event]!)
      }
    }
    
    return Signals.merge(correspondingSignals)
  }
  
  private var eventsList: [UInt: String] = [
    UIControlEvents.EditingChanged.rawValue: "editingChanged",
    UIControlEvents.ValueChanged.rawValue: "valueChanged",
    UIControlEvents.EditingDidEnd.rawValue: "editingDidEnd",
    UIControlEvents.EditingDidEndOnExit.rawValue: "EditingDidEndOnExit",
    UIControlEvents.TouchUpInside.rawValue: "touchUpInside"
  ]

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
//
//  UIStepper+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UIStepper {
//  public var valueChangeSignal: Signal<Double> { get { return signalEmitter.valueChangeSignal } }
//  public var reachMinimumSignal: Signal<Bool> { get { return signalEmitter.reachMinimumSignal } }
//  public var reachMaximumSignal: Signal<Bool> { get { return signalEmitter.reachMaximumSignal } }
}

//private class StepperSignalEmitter: NSObject {
//  private static var EmitterHandler: UInt8 = 0
//  let valueChangeSignal: Signal<Double>!
//  let reachMinimumSignal: Signal<Bool>!
//  let reachMaximumSignal: Signal<Bool>!
//  private weak var stepper: UIStepper!
//  
//  init(stepper: UIStepper) {
//    self.stepper = stepper
//    valueChangeSignal = Signal(value: stepper.value)
//    reachMaximumSignal = valueChangeSignal.map { [weak stepper] in $0 == stepper?.maximumValue }.skipRepeating()
//    reachMinimumSignal = valueChangeSignal.map { [weak stepper] in $0 == stepper?.minimumValue }.skipRepeating()
//    
//    super.init()
//    
//    stepper.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
//  }
//  
//  @objc
//  func valueDidChange(slider: UISlider) {
//    valueChangeSignal.sendNext(stepper.value)
//  }
//  
//}

//private extension UIStepper {
//  var signalEmitter: StepperSignalEmitter {
//    get {
//      var emitter = objc_getAssociatedObject(self, &StepperSignalEmitter.EmitterHandler) as? StepperSignalEmitter
//      if (emitter == nil) {
//        emitter = StepperSignalEmitter(stepper: self)
//        objc_setAssociatedObject(self, &StepperSignalEmitter.EmitterHandler, emitter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//      }
//      
//      return emitter!
//    }
//  }
//}
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
  public var textSignal: Signal<String> { get { return Signal<String>() } }
  public var willReturnSignal: Signal<Void> { get { return Signal<Void>() } }

//  public var textSignal: Signal<String> { get { return signalEmitter.textSignal } }
//  public var willReturnSignal: Signal<Void> { get { return signalEmitter.willReturnSignal } }
}

private class TextFieldSignalEmitter: NSObject, UITextFieldDelegate {
  private static var EmitterHandler: UInt8 = 0
  let textSignal: Signal<String>!
  let willReturnSignal = Signal<Void>()
  private(set) weak var textField: UITextField!
  
  init(textField: UITextField) {
    self.textField = textField
    textSignal = Signal(value: textField.text)
    
    super.init()
    
    textField.delegate = self
    
    textField.addTarget(self, action: "textDidChange:", forControlEvents: .EditingChanged)
  }
  
  @objc
  func textDidChange(textField: UITextField) {
    textSignal.sendNext(textField.text!)
  }
  
  @objc
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    willReturnSignal.sendNext()
    return true
  }
}

//private extension UITextField {
//  var signalEmitter: TextFieldSignalEmitter {
//    get {
//      var emitter = objc_getAssociatedObject(self, &TextFieldSignalEmitter.EmitterHandler) as? TextFieldSignalEmitter
//      if (emitter == nil) {
//        emitter = TextFieldSignalEmitter(textField: self)
//        objc_setAssociatedObject(self, &TextFieldSignalEmitter.EmitterHandler, emitter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//      }
//      
//      return emitter!
//    }
//  }
//}

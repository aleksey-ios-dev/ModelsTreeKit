//
//  UITextField+Signal.swift
//  SessionSwift
//
//  Created by aleksey on 24.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import UIKit

extension UITextField {
  
  public var textSignal: Observable<String> {
    let textSignal = signalForControlEvents(.allEditingEvents).map {
        ($0 as! UITextField).text ?? ""
        }.observable()
    textSignal.value = text ?? ""
    
    return textSignal.skipRepeating().observable()
  }
  
  public var editingSignal: Observable<Bool> {
    let observable = Signals.merge([editingBeginSignal.map { true }, editingEndSignal.map { false }]).observable()
    observable.value = isEditing
    
    return observable
  }
  
  public var editingBeginSignal: Pipe<Void> {
    return signalForControlEvents(.editingDidBegin).map { _ in return Void() } as! Pipe<Void>
  }
  
  public var editingEndSignal: Pipe<Void> {
    return signalForControlEvents(.editingDidEnd).map { _ in return Void() } as! Pipe<Void>
  }
  
  public var returnSignal: Pipe<Void> {
    return signalForControlEvents([.editingDidEndOnExit]).map { _ in return Void() } as! Pipe<Void>
  }
  
}

private class TextFieldDelegate: NSObject, UITextFieldDelegate {
  
  let clearSignal = Pipe<Void>()
  
  static var DelegateHandler: Int = 0
  
  @objc fileprivate func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    return true
  }
  
  @objc fileprivate func textFieldShouldClear(_ textField: UITextField) -> Bool {
    DispatchQueue.main.async { self.clearSignal.sendNext() }
    
    return true
  }
  
}

private extension UITextField {
  
  var sig_delegate: TextFieldDelegate {
    var delegate = objc_getAssociatedObject(self, &TextFieldDelegate.DelegateHandler) as? TextFieldDelegate
    if (delegate == nil) {
      delegate = TextFieldDelegate()
      self.delegate = delegate
      objc_setAssociatedObject(self, &TextFieldDelegate.DelegateHandler, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    return delegate!
  }
  
}

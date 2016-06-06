//
//  Signal+KVO.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.06.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

private class KeyValueObserver: NSObject {
  
  typealias ObservingAction = Any? -> Void
  
  private weak var object: NSObject!
  private var blocks = [String: ObservingAction]()
  private var signals = [String: Any]()
  private var context: Int = 0
  
  init(object: NSObject) {
    self.object = object
  }
  
  private func _signalForKeyPath<T>(keyPath: String) -> Observable<T?> {
    var signal = signals[keyPath]
    if signal == nil {
      signal = Observable<T?>()
      signals[keyPath] = signal
      startObservingKey(keyPath)
      
      blocks[keyPath] = { value in
        let castedSignal = signal as! Observable<T?>
        if let castedValue = value as? T {
          castedSignal.value = castedValue
        }
        else {
          castedSignal.value = nil
        }
      }
    }
    
    return signal as! Observable<T?>
  }
  
  private func startObservingKey(key: String) {
    object.addObserver(self, forKeyPath: key, options: [.New, .Initial], context: &context)
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if context != &self.context { return }
    
    guard let keyPath = keyPath, let change = change else { return }
    
    if let value = change[NSKeyValueChangeNewKey] {
      blocks[keyPath]?(value)
    }
  }
  
}

extension NSObject {
  
  private struct AssociatedKeys {
    static var KeyValueObserverKey = "KeyValueObserverKey"
  }
  
  public func signalForKeyPath<T>(key: String) -> Observable<T?> {
    return keyValueObserver._signalForKeyPath(key)
  }
  
  private var keyValueObserver: KeyValueObserver {
    get {
      var wrapper = objc_getAssociatedObject(self, &AssociatedKeys.KeyValueObserverKey) as? KeyValueObserver
      
      if (wrapper == nil) {
        wrapper = KeyValueObserver(object: self)
        objc_setAssociatedObject(self, &AssociatedKeys.KeyValueObserverKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
      
      return wrapper!
    }
  }
  
}
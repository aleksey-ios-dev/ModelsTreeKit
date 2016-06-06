//
//  Signal+KVO.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.06.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

class KeyValueObserver: NSObject {
  
  private weak var object: NSObject!
  
  typealias ActionBlock = Any? -> Void
  private var blocks = [String: ActionBlock]()
  private var signals = [String: Any]()
  
  init(object: NSObject) {
    self.object = object
  }
  
  func _signalForKeyPath<T>(keyPath: String) -> Observable<T> {
    var signal = signals[keyPath]
    if signal == nil {
      signal = Observable<T>()
      signals[keyPath] = signal
      startObservingKey(keyPath)
      
      blocks[keyPath] = { value in
        guard let castedValue = value as? T else { return } //TODO: handle nil casek
        let castedSignal = signal as! Observable<T>
        castedSignal.value = castedValue
      }
    }
    
    return signal as! Observable<T>
  }
  
  private func startObservingKey(key: String) {
    object.addObserver(self, forKeyPath: key, options: [.New], context: nil) //TODO: provide context
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    guard let keyPath = keyPath else { return }
    
    let value = change![NSKeyValueChangeNewKey]
    blocks[keyPath]?(value)

  }
  
}


extension NSObject {
  
  private struct AssociatedKeys {
    static var KeyValueObserverKey = "KeyValueObserverKey"
  }
  
  public func signalForKeyPath<T>(key: String) -> Observable<T> {
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
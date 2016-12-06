//
//  Disposable.swift
//  SessionSwift
//
//  Created by aleksey on 25.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

protocol Invocable: class {
  
  func invoke(_ data: Any) -> Void
  func invokeState(_ data: Bool) -> Void
  
}

class Subscription<U> : Invocable, Disposable {
  
  var handler: ((U) -> Void)?
  var stateHandler: ((Bool) -> Void)?
  
  private var signal: Signal<U>
  private var deliversOnMainThread = false
  private var autodisposes = false
  
  init(handler: ((U) -> Void)?, signal: Signal<U>) {
    self.handler = handler
    self.signal = signal;
  }
  
  func invoke(_ data: Any) -> Void {
    if deliversOnMainThread {
      DispatchQueue.main.async { [weak self] in
        self?.handler?(data as! U)
      }
    } else {
      handler?(data as! U)
    }
    if autodisposes { dispose() }
  }
  
  func invokeState(_ data: Bool) -> Void {
    if deliversOnMainThread {
      DispatchQueue.main.async { [weak self] in
        self?.stateHandler?(data)
      }
    } else {
      stateHandler?(data)
    }
  }
  
  func dispose() {
    signal.nextHandlers = signal.nextHandlers.filter { $0 !== self }
    signal.completedHandlers = signal.completedHandlers.filter { $0 !== self }
    handler = nil
  }
  
  @discardableResult
  func deliverOnMainThread() -> Disposable {
    deliversOnMainThread = true
    
    return self
  }
  
  @discardableResult
  func autodispose() -> Disposable {
    autodisposes = true
    
    return self
  }
  
  @discardableResult
  func putInto(_ pool: AutodisposePool) -> Disposable {
    pool.add(self)
    
    return self
  }
  
  @discardableResult
  func takeUntil(_ signal: Pipe<Void>) -> Disposable {
    signal.subscribeNext { [weak self] in
      self?.dispose()
    }.putInto(self.signal.pool)

    return self
  }
  
  func ownedBy(_ object: DeinitObservable) -> Disposable {
    return takeUntil(object.deinitSignal)
  }
  
}

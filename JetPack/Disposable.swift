//
//  Disposable.swift
//  ModelsTreeKit
//
//  Created by aleksey on 05.06.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

public protocol Disposable: class {
  
  func dispose()
  @discardableResult func deliverOnMainThread() -> Disposable
  @discardableResult func autodispose() -> Disposable
  @discardableResult func putInto(_ pool: AutodisposePool) -> Disposable
  @discardableResult func takeUntil(_ signal: Pipe<Void>) -> Disposable
  @discardableResult func ownedBy(_ object: DeinitObservable) -> Disposable
  
}

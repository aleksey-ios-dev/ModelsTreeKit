//
//  Signal.swift
//  SessionSwift
//
//  Created by aleksey on 14.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public struct Signals {
  static func merge<U>(signals: [Signal<U>]) -> Signal<U> {
    let nextSignal = Signal<U>()
    
        signals.forEach { signal in
          signal.subscribeNext { [weak nextSignal] in nextSignal?.sendNext($0)
            }.putInto(nextSignal.pool)
        }
    
    return nextSignal
  }
}

public final class ValueKeepingSignal<T>: Signal<T> {

  public init(value: T? = nil) {
    super.init()
    self.value = value
  }
  
  public override func sendNext(value: T) {
    super.sendNext(value)
    self.value = value
  }
  
  public override func subscribeNext(handler: SignalHandler) -> Disposable {
    let subscription = super.subscribeNext(handler) as! Subscription<T>
    if let value = value { subscription.handler?(value) }
    
    return subscription
  }
  
}

public class Signal<T> {
  public var hashValue = NSProcessInfo.processInfo().globallyUniqueString.hash
  
  public typealias SignalHandler = T -> Void
  public typealias StateHandler = Bool -> Void
  
  var value: T?

  var nextHandlers = [Invocable]()
  var completedHandlers = [Invocable]()
  
  //Destructor is executed before the signal's deallocation. A good place to cancel your network operation.

  var destructor: (Void -> Void)?
  
  private var pool = AutodisposePool()
  
  deinit {
    destructor?()
    pool.drain()
  }
  
  public init() {}
  
  public func sendNext(newValue: T) {
    nextHandlers.forEach { $0.invoke(newValue) }
  }
  
  public func sendCompleted() {
    completedHandlers.forEach { $0.invokeState(true) }
  }
  
  //Adds handler to signal and returns subscription
  
  public func subscribeNext(handler: SignalHandler) -> Disposable {
    let wrapper = Subscription(handler: handler, signal: self)
    nextHandlers.append(wrapper)
    
    return wrapper
  }
  
  public func subscribeCompleted(handler: StateHandler) -> Disposable {
    let wrapper = Subscription(handler: nil, signal: self)
    wrapper.stateHandler = handler
    completedHandlers.append(wrapper)
    
    return wrapper
  }
  
  private func chainSignal<U>(nextSignal: Signal<U>) -> Signal<U> {
    subscribeCompleted { [weak nextSignal] _ in nextSignal?.sendCompleted() }.putInto(nextSignal.pool)
    
    return nextSignal
  }
  
  //Transforms value, can change passed value type
  
  public func map<U>(handler: T -> U) -> Signal<U> {
    var nextSignal: Signal<U>!
    if self is ValueKeepingSignal { nextSignal = ValueKeepingSignal<U>() }
    else { nextSignal = Signal<U>() }
    subscribeNext { [weak nextSignal] in nextSignal?.sendNext(handler($0)) }.putInto(nextSignal.pool)
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  private func persistentMap() -> ValueKeepingSignal<T> {
    let nextSignal = ValueKeepingSignal<T>()
    subscribeNext { [weak nextSignal] in nextSignal?.sendNext($0) }.putInto(nextSignal.pool)
    chainSignal(nextSignal)
    if let value = self.value { nextSignal.sendNext(value) }
    
    return nextSignal
  }
  
  private func transientMap() -> Signal<T> {
    let nextSignal = Signal<T>()
    subscribeNext { [weak nextSignal] in nextSignal?.sendNext($0) }.putInto(nextSignal.pool)
    chainSignal(nextSignal)
    
    if let value = self.value { nextSignal.sendNext(value) }
    
    return nextSignal
  }
  
  //Adds a condition for sending next value, doesn't change passed value type
  
  public func filter(handler: T -> Bool) -> Signal<T> {
    var nextSignal: Signal<T>!
    if self is ValueKeepingSignal { nextSignal = ValueKeepingSignal<T>() }
    else { nextSignal = Signal<T>() }
    subscribeNext { [weak nextSignal] in
      if handler($0) { nextSignal?.sendNext($0) }
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Applies passed values to the cumulative reduced value
  
  public func reduce<U>(handler: (newValue: T, reducedValue: U?) -> U) -> Signal<U> {
    let nextSignal = ValueKeepingSignal<U>()
    subscribeNext { [weak nextSignal] in
      nextSignal?.sendNext(handler(newValue: $0, reducedValue: nextSignal?.value))
    }.putInto(nextSignal.pool)

    chainSignal(nextSignal)

    return nextSignal
  }
  
  //Sends combined value when any of signals fire
  
  private func distinctLatest<U>(otherSignal: Signal<U>) -> Signal<(T?, U?)> {
    let transientSelf = transientMap()
    let transientOther = otherSignal.transientMap()
    
    let nextSignal = ValueKeepingSignal<(T?, U?)>()
    
    transientOther.subscribeNext { [weak transientSelf, weak nextSignal] in
      guard let _self = transientSelf, let nextSignal = nextSignal else { return }
      nextSignal.sendNext((_self.value, $0))
    }.putInto(nextSignal.pool)
    
    transientSelf.subscribeNext { [weak transientOther, weak nextSignal] in
      guard let otherSignal = transientOther, let nextSignal = nextSignal else { return }
      nextSignal.sendNext(($0, otherSignal.value))
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  public func combineLatest<U>(otherSignal: Signal<U>) -> Signal<(T?, U?)> {
    let persistentSelf = persistentMap()
    let persistentOther = otherSignal.persistentMap()
    
    let nextSignal = ValueKeepingSignal<(T?, U?)>()
    
    persistentOther.subscribeNext { [weak persistentSelf, weak nextSignal] in
      guard let _self = persistentSelf, let nextSignal = nextSignal else { return }
      nextSignal.sendNext((_self.value, $0))
      }.putInto(nextSignal.pool)
    
    persistentSelf.subscribeNext { [weak persistentOther, weak nextSignal] in
      guard let otherSignal = persistentOther, let nextSignal = nextSignal else { return }
      nextSignal.sendNext(($0, otherSignal.value))
      }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Sends combined value when any of signals fires and both signals have last passed value
  
  public func combineNoNull<U>(otherSignal: Signal<U>) -> Signal<(T, U)> {
    return combineLatest(otherSignal).filter { $0 != nil && $1 != nil }.map { ($0!, $1!) }
  }
  
  //Sends combined value every time when both signals fire at least once
  
  public func combineBound<U>(otherSignal: Signal<U>) -> Signal<(T, U)> {
    let nextSignal = combineLatest(otherSignal).reduce { (newValue, reducedValue) -> ((T? , T?), (U?, U?)) in

      var reducedSelfValue: T? = reducedValue?.0.1
      var reducedOtherValue: U? = reducedValue?.1.1

      if let newSelfValue = newValue.0 { reducedSelfValue = newSelfValue }
      if let newOtherValue = newValue.1 { reducedOtherValue = newOtherValue }
      if let reducedSelfValue = reducedSelfValue, let reducedOtherValue = reducedOtherValue {
          return ((reducedSelfValue, nil), (reducedOtherValue, nil))
      } else {
        return ((nil, reducedValue?.0.1), (nil, reducedValue?.1.1))
      }
      
      }.map { ($0.0.0, $0.1.0)
      }.filter { $0.0 != nil && 0.1 != nil
      }.map { ($0.0!, $0.1!) }
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Zip
  
  public func zip<U>(otherSignal: Signal<U>) -> Signal<(T, U)> {
    let nextSignal = distinctLatest(otherSignal).reduce { (newValue, reducedValue) -> ((T?, [T]), (U?, [U])) in
      let newSelfValue = newValue.0
      let newOtherValue = newValue.1

      var reducedSelf = reducedValue?.0.1
      if reducedSelf == nil { reducedSelf = [T]() }
      
      var reducedOther = reducedValue?.1.1
      if reducedOther == nil { reducedOther = [U]() }
      
      if let newSelfValue = newSelfValue { reducedSelf?.append(newSelfValue) }
      if let newOtherValue = newOtherValue { reducedOther?.append(newOtherValue) }
      
      var zippedSelfValue: T? = nil
      var zippedOtherValue: U? = nil

      if !reducedSelf!.isEmpty && !reducedOther!.isEmpty {
        zippedSelfValue = reducedSelf!.first
        zippedOtherValue = reducedOther!.first
        reducedSelf!.removeFirst()
        reducedOther!.removeFirst()
      }
      
      return ((zippedSelfValue, reducedSelf!), (zippedOtherValue, reducedOther!))
      }.map { ($0.0.0, $0.1.0)
      }.filter { $0.0 != nil && 0.1 != nil
      }.map { ($0.0!, $0.1!)
    }
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Adds blocking signal. false - blocks, true - passes
  
  public func blockWith(blocker: Signal<Bool>) -> Signal<T> {
    let persistentBlocker = blocker.persistentMap()
    return filter { newValue in
      
      guard let _ = persistentBlocker.value else {
        return true
      }
      return persistentBlocker.value == false
    }
  }
  
  //Splits signal into two
  
  public func split<U, V>(splitter: T -> (a: U, b: V)) -> (a: Signal<U>, b: Signal<V>) {
    let signalA = Signal<U>()
    let signalB = Signal<V>()
    
    subscribeNext { [weak signalA] in signalA?.sendNext(splitter($0).a) }.putInto(signalA.pool)
    subscribeNext { [weak signalB] in signalB?.sendNext(splitter($0).b) }.putInto(signalB.pool)
    
    chainSignal(signalA)
    chainSignal(signalB)
    
    return (signalA, signalB)
  }
  
}

extension Signal where T: Equatable {
  
  //Stops the value from being passed more than once
  
  //BUG: locks propagation of initial value
  public func skipRepeating() -> Signal<T> {
    let persistentSelf = persistentMap()
    return persistentSelf.filter { [weak persistentSelf] newValue in return newValue != persistentSelf?.value }
  }
  
}

extension Signal where T: Comparable {
  
  //Pass values only in ascending order
  
  public func passAscending() -> Signal<T> {
    let nextSignal = ValueKeepingSignal<T>()
    
    subscribeNext { [weak nextSignal] newValue in
      if nextSignal?.value == nil || nextSignal?.value < newValue {
        nextSignal?.sendNext(newValue)
      }
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Pass values only in descending order
  
  public func passDescending() -> Signal<T> {
    let nextSignal = ValueKeepingSignal<T>()
    subscribeNext { [weak nextSignal] newValue in
      if nextSignal?.value == nil || nextSignal?.value > newValue {
        nextSignal?.sendNext(newValue)
      }
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
}

extension Signal: Hashable, Equatable {
}

public func ==<T>(lhs: Signal<T>, rhs: Signal<T>) -> Bool {
  return lhs.hashValue == rhs.hashValue
}


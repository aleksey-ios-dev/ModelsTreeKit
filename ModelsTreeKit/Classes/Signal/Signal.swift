//
//  Signal.swift
//  SessionSwift
//
//  Created by aleksey on 14.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public final class Signal<T> {
  public typealias SignalHandler = T -> Void
  public typealias StateHandler = Bool -> Void
  
//  var stack = ValuesStack<T>()
  var value: T?

  var nextHandlers = [Invocable]()
  var completedHandlers = [Invocable]()
  
  //Destructor is executed before the signal's deallocation. A good place to cancel your network operation.
  
  var destructor: (Void -> Void)?
  
  private var pool = AutodisposePool()
  private(set) var blocked = false
  
  deinit {
    destructor?()
    pool.drain()
  }
  
  public init() {
  }
  
  public init(value: T?) {
    self.value = value
  }
  
  public func sendNext(data: T) {
    if blocked { return }
    
    nextHandlers.forEach { $0.invoke(data) }
    
    if !transient { value = data }
  }
  
  public func sendCompleted() {
    if blocked {
      return
    }
    
    for handler in completedHandlers {
      handler.invokeState(true)
    }
    
    block()
  }
  
  //Adds handler to signal and returns subscription
  
  public func subscribeNext(handler: SignalHandler) -> Disposable {
    let wrapper = Subscription(handler: handler, signal: self)
    
    nextHandlers.append(wrapper)
    
    if let value = value {
      wrapper.handler?(value)
    }
    
    return wrapper
  }
  
  public func subscribeCompleted(handler: StateHandler) -> Disposable {
    let wrapper = Subscription(handler: nil, signal: self)
    wrapper.stateHandler = handler
    completedHandlers.append(wrapper)
    
    return wrapper
  }
  
  private func chainSignal<U>(nextSignal: Signal<U>) -> Signal<U> {
    subscribeCompleted { [weak nextSignal] _ in
      nextSignal?.sendCompleted()
    }.putInto(nextSignal.pool)
    
    return nextSignal
  }
  
  //Transforms value, can change passed value type
  
  public func map<U>(handler: T -> U) -> Signal<U> {
    let nextSignal = Signal<U>()
    
    subscribeNext { [weak nextSignal] in
      nextSignal?.sendNext(handler($0))
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Adds a condition for sending next value, doesn't change passed value type
  
  public func filter(handler: T -> Bool) -> Signal<T> {
    let nextSignal = Signal<T>()
    subscribeNext { [weak nextSignal] in
      if handler($0) {
        nextSignal?.sendNext($0)
      }
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Applies passed values to the cumulative reduced value
  
  public func reduce<U>(handler: (newValue: T, reducedValue: U?) -> U) -> Signal<U> {
    let nextSignal = Signal<U>()
    subscribeNext { [weak nextSignal] in
      nextSignal?.sendNext(handler(newValue: $0, reducedValue: nextSignal?.value))
    }.putInto(nextSignal.pool)

    chainSignal(nextSignal)

    return nextSignal
  }
  
  //Sends combined value when any of signals fire
  
  public func combineLatest<U>(otherSignal: Signal<U>) -> Signal<(T?, U?)> {
    let nextSignal = Signal<(T?, U?)>()
    
    otherSignal.subscribeNext { [weak self, weak nextSignal] in
      guard let strongSelf = self, let nextSignal = nextSignal else {
        return
      }
      nextSignal.sendNext((strongSelf.value, $0))
    }.putInto(nextSignal.pool)
    
    subscribeNext { [weak otherSignal, weak nextSignal] in
      guard let otherSignal = otherSignal, let nextSignal = nextSignal else {
        return
      }
      nextSignal.sendNext(($0, otherSignal.value))
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Sends combined value when any of signals fires and both signals have last passed value
  
  public func combineNoNull<U>(otherSignal: Signal<U>) -> Signal<(T, U)> {
    let nextSignal = Signal<(T, U)>()
    
    otherSignal.subscribeNext { [weak self, weak nextSignal] in
      guard let strongSelf = self, let nextSignal = nextSignal else {
        return
      }
      if let lastValue = strongSelf.value {
        nextSignal.sendNext((lastValue, $0))
      }
      
    }.putInto(nextSignal.pool)
    
    subscribeNext { [weak otherSignal, weak nextSignal] in
      guard let otherSignal = otherSignal, let nextSignal = nextSignal else {
        return
      }
      if let otherSignalValue = otherSignal.value {
        nextSignal.sendNext(($0, otherSignalValue))
      }
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Sends combined value every time when both signals fire at least once
  
  public func combineBound<U>(otherSignal: Signal<U>) -> Signal<(T, U)> {
    let nextSignal = Signal<(T, U)>()
    
    otherSignal.subscribeNext { [weak self, weak nextSignal, weak otherSignal] in
      guard let strongSelf = self, let nextSignal = nextSignal, let otherSignal = otherSignal else {
        return
      }
      if let lastValue = strongSelf.value {
        nextSignal.sendNext((lastValue, $0))
        //TODO: BAD!!!
        strongSelf.value = nil
        otherSignal.value = nil
      }
    }.putInto(nextSignal.pool)
    
    subscribeNext { [weak self] in
      if let otherSignalValue = otherSignal.value {
        nextSignal.sendNext(($0, otherSignalValue))
        self?.value = nil //BAD
        otherSignal.value = nil //BAD
      }
    }.putInto(otherSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
  //Zip
  
  public func zip<U>(otherSignal: Signal<U>) -> Signal<(T, U)> {
    let transientSelf = self.map { $0 }.makeTransient()
    let transientOther = otherSignal.map { $0 }.makeTransient()

    return transientSelf.combineLatest(transientOther).reduce { (newValue, reducedValue) -> ((T?, [T]), (U?, [U])) in
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
      }.map { return ($0.0.0, $0.1.0)
      }.filter { return $0.0 != nil && 0.1 != nil
      }.map { return ($0.0!, $0.1!)
    }
  }

  //Adds blocking signal
  
  public func blockWith(blocker: Signal<Bool>) -> Signal<T> {
    //TODO: BAD!!!
    blocker.subscribeNext { [weak self] blocked in
      self?.blocked = blocked
    }.putInto(pool)
    
    return self
  }
  
  //Splits signal into two
  
  public func split<U, V>(splitter: T -> (a: U, b: V)) -> (a: Signal<U>, b: Signal<V>) {
    let signalA = Signal<U>()
    let signalB = Signal<V>()
    
    subscribeNext {[weak signalA] in
      signalA?.sendNext(splitter($0).a)
      }.putInto(signalA.pool)
    
    subscribeNext {[weak signalB] in
      signalB?.sendNext(splitter($0).b)
      }.putInto(signalB.pool)
    
    chainSignal(signalA)
    chainSignal(signalB)
    
    return (signalA, signalB)
  }
  
  //Blocking
  
  public func block() {
    blocked = true
  }
  
  public func unblock() {
    blocked = false
  }
  
  //
  
  var transient = false
  
  func makeTransient() -> Signal<T> {
    transient = true
    return self
  }
  
}

extension Signal where T: Equatable {
  
  //Stops the value from being passed more than once
  
  public func skipRepeating() -> Signal<T> {
    return self.filter { [weak self] newValue in
      return newValue != self?.value
    }
  }
  
}

extension Signal where T: Comparable {
  
  //Pass values only in ascending order
  
  public func passAscending() -> Signal<T> {
    let nextSignal = Signal<T>()
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
    let nextSignal = Signal<T>()
    subscribeNext { [weak nextSignal] newValue in
      if nextSignal?.value == nil || nextSignal?.value > newValue {
        nextSignal?.sendNext(newValue)
      }
    }.putInto(nextSignal.pool)
    
    chainSignal(nextSignal)
    
    return nextSignal
  }
  
}

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
    
    weak var operation: NSOperation?
    
    var pool = AutodisposePool()
    
    private(set) var blocked = false
    
    var lastValue: T?
    var nextHandlers = [Invocable]()
    var completedHandlers = [Invocable]()
    
    deinit {
        operation?.cancel()
        pool.drain()
    }
    
    public init() {
    }
    
    public init(value: T?) {
        lastValue = value
    }
    
    public func sendNext(data: T) {
        if blocked {
            return
        }
        
        lastValue = data
        
        for handler in nextHandlers {
            handler.invoke(data)
        }
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

        if let lastValue = lastValue {
            wrapper.handler?(lastValue)
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
        subscribeCompleted { [weak nextSignal] o in
            nextSignal?.sendCompleted()
        }.putInto(nextSignal.pool)
        
        return nextSignal
    }
    
    //Transforms value, can change passed value type

    public func map<U>(handler: T -> U) -> Signal<U> {
        let nextSignal = Signal<U>()
        
        subscribeNext {[weak nextSignal] o in
            nextSignal?.sendNext(handler(o))
        }.putInto(nextSignal.pool)

        chainSignal(nextSignal)
        
        return nextSignal
    }
    
    //Adds a condition for sending next value, doesn't change passed value type
    
    public func filter(handler: T -> Bool) -> Signal<T> {
        let nextSignal = Signal<T>()
        subscribeNext {[weak nextSignal] o in
                if handler(o) {
                    nextSignal?.sendNext(o)
                }
        }.putInto(nextSignal.pool)
        
        chainSignal(nextSignal)
        
        return nextSignal
    }
    
    //Sends combined value when any of signals fire
    
    public func combineLatest<U>(otherSignal: Signal<U>) -> Signal<(T?, U?)> {
        let nextSignal = Signal<(T?, U?)>()
        
        otherSignal.subscribeNext { [weak self, weak nextSignal] o in
            guard let strongSelf = self, let nextSignal = nextSignal else {
                return
            }
            
            nextSignal.sendNext((strongSelf.lastValue, o))
        }.putInto(nextSignal.pool)

        subscribeNext { [weak otherSignal, weak nextSignal] o in
            guard let otherSignal = otherSignal, let nextSignal = nextSignal else {
                return
            }
            
            nextSignal.sendNext((o, otherSignal.lastValue))
        }.putInto(nextSignal.pool)
        
        chainSignal(nextSignal)
        
        return nextSignal
    }
    
    //Sends combined value when any of signals fires and both signals have last passed value
    
    public func combineNoNull<U>(otherSignal: Signal<U>) -> Signal<(T, U)> {
        let nextSignal = Signal<(T, U)>()
        
        otherSignal.subscribeNext { [weak self, weak nextSignal] o in
            guard let strongSelf = self, let nextSignal = nextSignal else {
                return
            }
            
            if let lastValue = strongSelf.lastValue {
                nextSignal.sendNext((lastValue, o))
            }
            
        }.putInto(nextSignal.pool)
        
        subscribeNext { [weak otherSignal, weak nextSignal] o in
            guard let otherSignal = otherSignal, let nextSignal = nextSignal else {
                return
            }
            
            if let otherSignalValue = otherSignal.lastValue {
                nextSignal.sendNext((o, otherSignalValue))
            }
        }.putInto(nextSignal.pool)
        
        chainSignal(nextSignal)
        
        return nextSignal
    }
    
    //Sends combined value every time when both signals fire at least once
    
    public func combineBound<U>(otherSignal: Signal<U>) -> Signal<(T, U)> {
        let nextSignal = Signal<(T, U)>()
        
        otherSignal.subscribeNext { [weak self, weak nextSignal, weak otherSignal] o in
            guard let strongSelf = self, let nextSignal = nextSignal, let otherSignal = otherSignal else {
                return
            }

            if let lastValue = strongSelf.lastValue {
                nextSignal.sendNext((lastValue, o))
                strongSelf.lastValue = nil
                otherSignal.lastValue = nil
            }
        }.putInto(nextSignal.pool)

        subscribeNext { [weak self] o in
            if let otherSignalValue = otherSignal.lastValue {
                nextSignal.sendNext((o, otherSignalValue))
                self?.lastValue = nil
                otherSignal.lastValue = nil
            }
        }.putInto(otherSignal.pool)
        
        chainSignal(nextSignal)

        return nextSignal
    }
    
    //Adds blocking signal
    
    public func blockWith(blocker: Signal<Bool>) -> Signal<T> {
        blocker.subscribeNext { [weak self] blocked in
            self?.blocked = blocked
        }.putInto(pool)
        
        return self
    }
    
    //Splits signal into two
    
    public func split<U, V>(splitter: T -> (a: U, b: V)) -> (a: Signal<U>, b: Signal<V>) {
        let signalA = Signal<U>()
        let signalB = Signal<V>()

        subscribeNext {[weak signalA] o in
            signalA?.sendNext(splitter(o).a)
        }.putInto(signalA.pool)

        subscribeNext {[weak signalB] o in
            signalB?.sendNext(splitter(o).b)
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
}
//
//  Model.swift
//  SessionSwift
//
//  Created by aleksey on 10.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class Model {
  
  public private(set) weak var parent: Model?
  
  public let pushChildSignal = Signal<Model>()
  public let errorSignal = Signal<Error>()
  public let pool = AutodisposePool()
  
  private let hash = NSProcessInfo.processInfo().globallyUniqueString
  
  public init(parent: Model?) {
    self.parent = parent
    parent?.addChild(self)
  }
  
  //Connection with representation
  
  public func applyRepresentation(representation: DeinitObservable) {
    representation.deinitSignal.subscribeCompleted { [weak self] _ in
      self?.parent?.removeChild(self!)
    }.putInto(pool)
  }
  
  //Child models
  
  private lazy var childModelsSet = Set<Model>()
  
  final func childModels() -> Set<Model> {
    return childModelsSet
  }
  
  final func addChild(childModel: Model) {
    childModelsSet.insert(childModel)
  }
  
  final func removeChild(childModel: Model) {
    childModelsSet.remove(childModel)
  }
  
  public final func removeFromParent() {
    parent?.removeChild(self)
  }
  
  //Session Helpers
  
  public final func session() -> Session? {
    if let session = parent as? Session { return session }
    else { return parent?.session() }
  }
  
  //Bubble Notifications
  
  //TODO: extensions

  private var registeredBubbles = Set<Bubble>()
  
  public final func registerForBubbleNotification(bubble: Bubble) {
    registeredBubbles.insert(bubble)
  }
  
  public final func unregisterFromBubbleNotification(bubble: Bubble) {
    registeredBubbles.remove(bubble)
  }
  
  public final func isRegisteredForBubbleNotification(bubble: Bubble) -> Bool {
    return registeredBubbles.contains(bubble)
  }
  
  public func raiseBubbleNotification(bubble: Bubble, sender: Model) {
    if isRegisteredForBubbleNotification(bubble) {
      handleBubbleNotification(bubble, sender: sender)
    } else {
      parent?.raiseBubbleNotification(bubble, sender: sender)
    }
  }
  
  public func handleBubbleNotification(bubble: Bubble, sender: Model) {
    //Implemented by subclasses
  }
  
  //Errors
  
  //TODO: extensions
  private var registeredErrors = Set<Error>()
  
  public final func registerForError(error: Error) {
    registeredErrors.insert(error)
  }
  
  public final func registerForErrorCodes(codes: [ErrorCode], inDomain domain: ErrorDomain) {
    for code in codes {
      registerForError(Error(domain: domain, code: code))
    }
  }
  
  public final func unregisterFromError(error: Error) {
    registeredErrors.remove(error)
  }
  
  public final func isRegisteredForError(error: Error) -> Bool {
    return registeredErrors.contains(error)
  }
  
  public func raiseError(error: Error) {
    if isRegisteredForError(error) { errorSignal.sendNext(error) }
    else { parent?.raiseError(error) }
  }
  
  //Global events
  
  private var eventHandlerWrappers = [SessionEventWrapper]()
  
  final func registerForEvent(event: SessionEvent, handler: EventHandler) {
    unregisterFromEvent(event)
    eventHandlerWrappers.append(SessionEventWrapper(event: event, handler: handler))
  }
  
  final func unregisterFromEvent(event: SessionEvent) {
    eventHandlerWrappers = eventHandlerWrappers.filter {$0.event != event}
  }
  
  final func raiseSessionEvent(event: SessionEvent, withObject object: Any?) {
    session()?.propagateEvent(event, withObject: object)
  }
  
  private func propagateEvent(event: SessionEvent, withObject object: Any?) {
    for wrapper in eventHandlerWrappers {
      if wrapper.event == event {
        wrapper.handler(object: object)
      }
    }
    
    childModels().forEach { $0.propagateEvent(event, withObject: object) }
    
    for child in childModels() {
      child.propagateEvent(event, withObject: object)
    }
  }
}

extension Model: Hashable, Equatable {
  public var hashValue: Int {
    get {
      return hash.hash
    }
  }
}

public func ==(lhs: Model, rhs: Model) -> Bool {
  return lhs.hash == rhs.hash
}

extension Model {
  public final func printSubtree() {
    print("\n")
    printTreeLevel(0)
    print("\n")
  }
  
  public final func printSessionTree() {
    session()?.printSubtree()
  }
  
  private func printTreeLevel(level: Int) {
    var output = "|"
    let indent = "  |"
    
    for _ in 0..<level {
      output += indent
    }
    
    output += "\(self)"
    print(output)
    
    for child in childModels() {
      child.printTreeLevel(level + 1)
    }
  }
}

typealias EventHandler = (object: Any?) -> (Void)

private class SessionEventWrapper {
  var event: SessionEvent
  var handler: EventHandler
  
  init (event: SessionEvent, handler: EventHandler) {
    self.event = event
    self.handler = handler
  }
}

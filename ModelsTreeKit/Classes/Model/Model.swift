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
  
  public let pushChildSignal = Signal<Model>(transient: true)
  public let wantsRemoveChildSignal = Signal<Model>(transient: true)
  public let errorSignal = Signal<Error>()
  public let pool = AutodisposePool()
  
  private let hash = NSProcessInfo.processInfo().globallyUniqueString
  
  deinit {
    representationDeinitDisposable?.dispose()
  }
  
  public init(parent: Model?) {
    self.parent = parent
    parent?.addChild(self)
  }
  
  //Connection with representation
  
  private weak var representationDeinitDisposable: Disposable?
  
  public func applyRepresentation(representation: DeinitObservable) {
    representationDeinitDisposable = representation.deinitSignal.subscribeCompleted { [weak self] _ in
      self?.parent?.removeChild(self!)
    }.autodispose()
  }
  
  //Lifecycle
  
  public func sessionWillClose() {
    childModels().forEach { $0.sessionWillClose() }
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
  
  public func removeFromParent() {
    parent?.removeChild(self)
  }
  
  //Session Helpers
  
  public final func session() -> Session? {
    if let session = parent as? Session { return session }
    else { return parent?.session() }
  }
  
  //Bubble Notifications
  
  //TODO: extensions

  private var registeredBubbles = Set<BubbleNotification>()
  
  public final func registerForBubbleNotification(bubble: BubbleNotification) {
    registeredBubbles.insert(bubble)
  }
  
  public final func unregisterFromBubbleNotification(bubble: BubbleNotification) {
    registeredBubbles.remove(bubble)
  }
  
  public final func isRegisteredForBubbleNotification(bubble: BubbleNotification) -> Bool {
    return registeredBubbles.contains(bubble)
  }
  
  public func raiseBubbleNotification(bubble: BubbleNotification, sender: Model) {
    if isRegisteredForBubbleNotification(bubble) {
      handleBubbleNotification(bubble, sender: sender)
    } else {
      parent?.raiseBubbleNotification(bubble, sender: sender)
    }
  }
  
  public func handleBubbleNotification(bubble: BubbleNotification, sender: Model) {
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
    if isRegisteredForError(error) { handleError(error) }
    else { parent?.raiseError(error) }
  }
  
  //Override to achieve custom behavior
  
  public func handleError(error: Error) {
    errorSignal.sendNext(error)
  }
  
  //Global events
  
  private var registeredGlobalEvents = Set<Int>()
  
  public final func registerForEvent(name: SessionEventName) {
    registeredGlobalEvents.insert(name.rawValue.hash)
  }
  
  public final func unregisterFromEvent(name: SessionEventName) {
    registeredGlobalEvents.remove(name.rawValue.hash)
  }
  
  public final func isRegisteredForEvent(name: SessionEventName) -> Bool {
    return registeredGlobalEvents.contains(name.rawValue.hash)
  }
  
  public final func raiseSessionEvent(
    name: SessionEventName,
    withObject object: Any? = nil,
    userInfo: [String: Any] = [:]) {
    let event = SessionEvent(name: name, object: object, userInfo: userInfo)
    session()?.propagateEvent(event)
  }
  
  public func handleSessionEvent(event: SessionEvent) {}
  
  private func propagateEvent(event: SessionEvent) {
    if isRegisteredForEvent(event.name) { handleSessionEvent(event) }
    childModels().forEach { $0.propagateEvent(event) }
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
  public enum PrintParams {
    case HasRepresentation
  }
  
  public final func printSubtree(params: [PrintParams] = []) {
    print("\n")
    printTreeLevel(0, params: params)
    print("\n")
  }
  
  public final func printSessionTree(withParams params: [PrintParams] = []) {
    session()?.printSubtree(params)
  }
  
  private func printTreeLevel(level: Int, params: [PrintParams] = []) {
    var output = "|"
    let indent = "  |"
    
    for _ in 0..<level {
      output += indent
    }
    
    output += "\(String(self).componentsSeparatedByString(".").last!)"
    
    if params.contains(.HasRepresentation) && representationDeinitDisposable != nil {
      output += " (R)"
    }
    print(output)
    
    childModels().forEach { $0.printTreeLevel(level + 1, params:  params) }
  }
}

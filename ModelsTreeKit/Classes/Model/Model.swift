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
  public let wantsRemoveChildSignal = Signal<Model>()
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

  private var registeredBubbles = Set<String>()
  
  public final func registerForBubbleNotification(name: BubbleNotificationName, inDomain domain: String) {
    registeredBubbles.insert(domain + "." + name.rawValue)
  }
  
  public final func unregisterFromBubbleNotification(name: BubbleNotificationName, inDomain domain: String) {
    registeredBubbles.remove(domain + "." + name.rawValue)
  }
  
  public final func isRegisteredForBubbleNotification(name: BubbleNotificationName, inDomain domain: String) -> Bool {
    return registeredBubbles.contains(domain + "." + name.rawValue)
  }
  
  public func raiseBubbleNotification(name: BubbleNotificationName, domain: String, withObject object: Any? = nil, sender: Model) {
    if isRegisteredForBubbleNotification(name, inDomain: domain) {
      handleBubbleNotification(BubbleNotification(name: name, domain: domain, object: object), sender: sender)
    } else {
      parent?.raiseBubbleNotification(name, domain: domain, withObject: object, sender: sender)
    }
  }
  
  public func handleBubbleNotification(bubble: BubbleNotification, sender: Model) {}
  
  //Errors
  
  //TODO: extensions
  private var registeredErrors = [String: Set<Int>]()
  
  public final func registerForError(code: ErrorCode, inDomain domain: ErrorDomain) {
    var allCodes = registeredErrors[domain.rawValue] ?? []
    allCodes.insert(code.rawValue)
    registeredErrors[domain.rawValue] = allCodes
  }
  
  public final func registerForErrorCodes(codes: [ErrorCode], inDomain domain: ErrorDomain) {
    var allCodes = registeredErrors[domain.rawValue] ?? []
    let mappedCodes = codes.map { $0.rawValue }
    mappedCodes.forEach { allCodes.insert($0) }
    registeredErrors[domain.rawValue] = allCodes
  }
  
  public final func unregisterFromError(code code: ErrorCode, inDomain domain: ErrorDomain) {
    if let codes = registeredErrors[domain.rawValue] {
      var filteredCodes = codes
      filteredCodes.remove(code.rawValue)
      registeredErrors[domain.rawValue] = filteredCodes
    }
  }
  
  public final func isRegisteredForError(error: Error) -> Bool {
    guard let codes = registeredErrors[error.domain.rawValue] else { return false }
    return codes.contains(error.code.rawValue)
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
  
  private var registeredGlobalEvents = Set<String>()
  
  public final func registerForEvent(name: GlobalEventName) {
    registeredGlobalEvents.insert(name.rawValue)
  }
  
  public final func unregisterFromEvent(name: GlobalEventName) {
    registeredGlobalEvents.remove(name.rawValue)
  }
  
  public final func isRegisteredForEvent(name: GlobalEventName) -> Bool {
    return registeredGlobalEvents.contains(name.rawValue)
  }
  
  public final func raiseGlobalEvent(
    name: GlobalEventName,
    withObject object: Any? = nil,
    userInfo: [String: Any] = [:]) {
    let event = GlobalEvent(name: name, object: object, userInfo: userInfo)
    session()?.propagateEvent(event)
  }
  
  public func handleSessionEvent(event: GlobalEvent) {}
  
  private func propagateEvent(event: GlobalEvent) {
    if isRegisteredForEvent(event.name) { handleSessionEvent(event) }
    childModels().forEach { $0.propagateEvent(event) }
  }
  
}

extension Model: Hashable, Equatable {
  
  public var hashValue: Int { get { return hash.hash } }
  
}

public func ==(lhs: Model, rhs: Model) -> Bool {
  return lhs.hash == rhs.hash
}

extension Model {
  
  public enum TreeInfoOptions {
    case Representation
    case GlobalEvents
    case BubbleNotifications
    case Errors
    case ErrorsVerbous
  }
  
  public final func printSubtree(params: [TreeInfoOptions] = []) {
    print("\n")
    printTreeLevel(0, params: params)
    print("\n")
  }
  
  public final func printSessionTree(withOptions params: [TreeInfoOptions] = []) {
    session()?.printSubtree(params)
  }
  
  private func printTreeLevel(level: Int, params: [TreeInfoOptions] = []) {
    var output = "|"
    let indent = "  |"
    
    for _ in 0..<level {
      output += indent
    }
    
    output += "\(String(self).componentsSeparatedByString(".").last!)"
    
    if params.contains(.Representation) && representationDeinitDisposable != nil {
      output += "  | (R)"
    }
    
    if params.contains(.GlobalEvents) && !registeredGlobalEvents.isEmpty {
      output += "  | (E):"
      registeredGlobalEvents.forEach { output += " \($0)" }
    }
    
    if params.contains(.BubbleNotifications) && !registeredBubbles.isEmpty {
      output += "  | (B):"
      registeredBubbles.forEach { output += " \($0)" }
    }
    
    if params.contains(.ErrorsVerbous) && !registeredErrors.isEmpty {
      output += "  | (Err): "
      for (domain, codes) in registeredErrors {
        codes.forEach { output += "[\(NSLocalizedString("\(domain).\($0)", comment: ""))] " }
      }
    } else if params.contains(.Errors) && !registeredErrors.isEmpty {
      output += "  | (Err): "
      for (domain, codes) in registeredErrors {
        output += "\(domain) > "
        codes.forEach { output += "\($0) " }
      }
    }

    print(output)
    
    childModels().forEach { $0.printTreeLevel(level + 1, params:  params) }
  }
  
}

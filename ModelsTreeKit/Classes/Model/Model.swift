//
//  Model.swift
//  SessionSwift
//
//  Created by aleksey on 10.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

extension Model: DeinitObservable { }

public class Model {
  
  public private(set) weak var parent: Model!
  
  public let pushChildSignal = Pipe<Model>()
  public let wantsRemoveChildSignal = Pipe<Model>()
  public let errorSignal = Pipe<Error>()
  public let pool = AutodisposePool()
  public let deinitSignal = Pipe<Void>()
  
  fileprivate let hash = ProcessInfo.processInfo.globallyUniqueString
  fileprivate let timeStamp = NSDate()
  
  deinit {
    deinitSignal.sendNext(newValue: ())
    representationDeinitDisposable?.dispose()
  }
  
  public init(parent: Model?) {
    self.parent = parent
    parent?.addChild(childModel: self)
  }
  
  //Connection with representation
  
  fileprivate weak var representationDeinitDisposable: Disposable?
  
  public func applyRepresentation(representation: DeinitObservable) {
    representationDeinitDisposable = representation.deinitSignal.subscribeNext { [weak self] _ in
      self?.parent?.removeChild(childModel: self!)
    }.autodispose()
  }
  
  //Lifecycle
  
  public func sessionWillClose() {
    childModels.forEach { $0.sessionWillClose() }
  }
  
  //Child models
  
  private(set) lazy var childModels = Set<Model>()
  
  final func addChild(childModel: Model) {
    childModels.insert(childModel)
  }
  
  final func removeChild(childModel: Model) {
    childModels.remove(childModel)
  }
  
  public func removeFromParent() {
    parent?.removeChild(childModel: self)
  }
  
  //Session Helpers
  
  public final var session: Session {
    get {
      if let session = parent as? Session {
        return session
      } else {
        return parent.session
      }
    }
  }
  
  //Bubble Notifications
  
  fileprivate var registeredBubbles = Set<String>()
  
  public final func register(for bubbleNotification: BubbleNotificationName) {
    registeredBubbles.insert(type(of: bubbleNotification).domain + "." + bubbleNotification.rawValue)
    pushChildSignal.sendNext(newValue: self)
  }
  
  public final func unregister(from bubbleNotification: BubbleNotificationName) {
    registeredBubbles.remove(type(of: bubbleNotification).domain + "." + bubbleNotification.rawValue)
  }
  
  public final func isRegistered(for bubbleNotification: BubbleNotificationName) -> Bool {
    return registeredBubbles.contains(type(of: bubbleNotification).domain + "." + bubbleNotification.rawValue)
  }
  
  public func raise(bubbleNotification: BubbleNotificationName, withObject object: Any? = nil) {
    _raise(bubbleNotification: bubbleNotification, withObject: object, sender: self)
  }
  
  public func _raise(bubbleNotification: BubbleNotificationName, withObject object: Any? = nil, sender: Model) {
    if isRegistered(for: bubbleNotification) {
      handle(bubbleNotification: BubbleNotification(name: bubbleNotification, object: object), sender: sender)
    } else {
      parent?._raise(bubbleNotification: bubbleNotification, withObject: object, sender: sender)
    }
  }
  
  public func handle(bubbleNotification: BubbleNotification, sender: Model) {}
  
  //Errors
  
  //TODO: extensions
  fileprivate var registeredErrors = [String: Set<Int>]()
  
  public final func register(for error: ErrorCode) {
    var allCodes = registeredErrors[type(of: error).domain] ?? []
    allCodes.insert(error.rawValue)
    registeredErrors[type(of: error).domain] = allCodes
  }
  
  public final func register<T>(for errorCodes: [T]) where T: ErrorCode {
    var allCodes = registeredErrors[T.domain] ?? []
    let mappedCodes = errorCodes.map { $0.rawValue }
    mappedCodes.forEach { allCodes.insert($0) }
    registeredErrors[T.domain] = allCodes
  }
  
  public final func unregister(from error: ErrorCode) {

    if let codes = registeredErrors[type(of: error).domain] {
      var filteredCodes = codes
      filteredCodes.remove(error.rawValue)
      registeredErrors[type(of: error).domain] = filteredCodes
    }
  }
  
  public final func isRegistered(for error: ModelTreeError) -> Bool {
    guard let codes = registeredErrors[error.domain] else { return false }
    return codes.contains(error.code.rawValue)
  }
  
  public func raise(error: ModelTreeError) {
    if isRegistered(for: error) {
      handle(error: error)
    } else {
      parent?.raise(error: error)
    }
  }
  
  //Override to achieve custom behavior
  
  public func handle(error: ModelTreeError) {
    errorSignal.sendNext(newValue: error)
  }
  
  //Global events
  
  fileprivate var registeredGlobalEvents = Set<String>()
  
  public final func register(for globalEvent: GlobalEventName) {
    registeredGlobalEvents.insert(globalEvent.rawValue)
  }
  
  public final func unregister(from globalEvent: GlobalEventName) {
    registeredGlobalEvents.remove(globalEvent.rawValue)
  }
  
  public final func isRegistered(for globalEvent: GlobalEventName) -> Bool {
    return registeredGlobalEvents.contains(globalEvent.rawValue)
  }
  
  public final func raise(
    globalEvent: GlobalEventName,
    withObject object: Any? = nil,
    userInfo: [String: Any] = [:]) {
    let event = GlobalEvent(name: globalEvent, object: object, userInfo: userInfo)
    session.propagate(globalEvent: event)
  }
  
  private func propagate(globalEvent: GlobalEvent) {
    if isRegistered(for: globalEvent.name) {
      handle(globalEvent: globalEvent)
    }
    childModels.forEach { $0.propagate(globalEvent: globalEvent) }
  }
  
  public func handle(globalEvent: GlobalEvent) {}
  
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
    printTreeLevel(level: 0, params: params)
    print("\n")
  }
  
  public final func printSessionTree(withOptions params: [TreeInfoOptions] = []) {
    session.printSubtree(params: params)
  }
  
  private func printTreeLevel(level: Int, params: [TreeInfoOptions] = []) {
    var output = "|"
    let indent = "  |"
    
    for _ in 0..<level {
      output += indent
    }

    output += "\(String(describing: self).components(separatedBy: ".").last!)"
    
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
    
    childModels.sorted { return $0.timeStamp.compare($1.timeStamp as Date) == .orderedAscending }.forEach { $0.printTreeLevel(level: level + 1, params:  params) }

  }
  
}

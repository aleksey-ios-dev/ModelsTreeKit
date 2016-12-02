//
//  Model.swift
//  SessionSwift
//
//  Created by aleksey on 10.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

extension Model: DeinitObservable { }

open class Model {
  
  public private(set) weak var parent: Model!
  
  public let pushChildSignal = Pipe<Model>()
  public let wantsRemoveChildSignal = Pipe<Model>()
  public let errorSignal = Pipe<ModelsTreeError>()
  public let pool = AutodisposePool()
  public let deinitSignal = Pipe<Void>()
  
  fileprivate let hash = ProcessInfo.processInfo.globallyUniqueString
  fileprivate let timeStamp = Date()
  
  deinit {
    deinitSignal.sendNext()
    representationDeinitDisposable?.dispose()
  }
  
  public required init(parent: Model?) {
    self.parent = parent
    parent?.addChild(self)
  }
  
  //Connection with representation
  
  fileprivate weak var representationDeinitDisposable: Disposable?
  
  public func applyRepresentation(_ representation: DeinitObservable) {
    representationDeinitDisposable = representation.deinitSignal.subscribeNext { [weak self] _ in
      self?.parent?.removeChild(self!)
      }.autodispose()
  }
  
  //Lifecycle
  
  open func sessionWillClose() {
    childModels.forEach { $0.sessionWillClose() }
  }
  
  //Child models
  
  public private(set) lazy var childModels = Set<Model>()
  
  final func addChild(_ childModel: Model) {
    childModels.insert(childModel)
  }
  
  final func removeChild(_ childModel: Model) {
    childModels.remove(childModel)
  }
  
  public func removeFromParent() {
    parent?.removeChild(self)
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
    pushChildSignal.sendNext(self)
  }
  
  public final func unregister(from bubbleNotification: BubbleNotificationName) {
    registeredBubbles.remove(type(of: bubbleNotification).domain + "." + bubbleNotification.rawValue)
  }
  
  public final func isRegistered(for bubbleNotification: BubbleNotificationName) -> Bool {
    return registeredBubbles.contains(type(of: bubbleNotification).domain + "." + bubbleNotification.rawValue)
  }
  
  public func raise(_ bubbleNotification: BubbleNotificationName, withObject object: Any? = nil) {
    _raise(bubbleNotification, withObject: object, sender: self)
  }
  
  public func _raise(_ bubbleNotification: BubbleNotificationName, withObject object: Any? = nil, sender: Model) {
    if isRegistered(for: bubbleNotification) {
      handle(BubbleNotification(name: bubbleNotification, object: object), sender: sender)
    } else {
      parent?._raise(bubbleNotification, withObject: object, sender: sender)
    }
  }
  
  open func handle(_ bubbleNotification: BubbleNotification, sender: Model) {}
  
  //Errors
  
  //TODO: extensions
  fileprivate var registeredErrors = [String: Set<String>]()
  
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
  
  public final func isRegistered(for error: ModelsTreeError) -> Bool {
    guard let codes = registeredErrors[error.domain] else { return false }
    return codes.contains(error.code.rawValue)
  }
  
  public func raise(_ error: ModelsTreeError) {
    if isRegistered(for: error) {
      handle(error)
    } else {
      parent?.raise(error)
    }
  }
  
  //Override to achieve custom behavior
  
  open func handle(_ error: ModelsTreeError) {
    errorSignal.sendNext(error)
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
    _ globalEvent: GlobalEventName,
    withObject object: Any? = nil,
               userInfo: [String: Any] = [:]) {
    let event = GlobalEvent(name: globalEvent, object: object, userInfo: userInfo)
    session.propagate(event)
  }
  
  private func propagate(_ globalEvent: GlobalEvent) {
    if isRegistered(for: globalEvent.name) {
      handle(globalEvent)
    }
    childModels.forEach { $0.propagate(globalEvent) }
  }
  
  open func handle(_ globalEvent: GlobalEvent) {}
  
}

extension Model: Hashable, Equatable {
  
  public var hashValue: Int { get { return hash.hash } }
  
}

public func ==(lhs: Model, rhs: Model) -> Bool {
  return lhs.hash == rhs.hash
}

extension Model {
  
  public enum TreeInfoOptions {
    case representation
    case globalEvents
    case bubbleNotifications
    case errors
    case errorsVerbous
    case youAreHere
  }
  
  public final func printSubtree(params: [TreeInfoOptions] = []) {
    _printSubtree(params: params, sender: self)
  }
  
  private func _printSubtree(params: [TreeInfoOptions] = [], sender: Model) {
    print("\n")
    printTree(withPrefix: nil, decoration: .EntryPoint, params: params, sender: sender)
    print("\n")
  }
  
  public final func printSessionTree(withOptions params: [TreeInfoOptions] = []) {
    session._printSubtree(params: params, sender: self)
  }
  
  private enum NodDecoration: String {
    case EntryPoint = "──"
    case Middle = "├─"
    case Last = "└─"
  }
  
  private func printTree(withPrefix prefix: String?, decoration: NodDecoration, params: [TreeInfoOptions] = [], sender: Model) {
    let indent = prefix == nil ? "" : "   "
    
    let currentPrefix = (prefix ?? "") + indent
    
    var nextIndent = ""
    if prefix != nil {
      if decoration == .Last {
        nextIndent = "   "
      } else {
        nextIndent = "   │"
      }
    }
    
    let nextPrefix = (prefix ?? "") + nextIndent
    
    var output = currentPrefix + decoration.rawValue + "\(String(describing: self).components(separatedBy: ".").last!)"
    if params.contains(.youAreHere) && sender == self {
      output += " <- "
    }
    
    if params.contains(.representation) && representationDeinitDisposable != nil {
      output += "  | (R)"
    }
    
    if params.contains(.globalEvents) && !registeredGlobalEvents.isEmpty {
      output += "  | (E):"
      registeredGlobalEvents.forEach { output += " \($0)" }
    }
    
    if params.contains(.bubbleNotifications) && !registeredBubbles.isEmpty {
      output += "  | (B):"
      registeredBubbles.forEach { output += " \($0)" }
    }
    
    if params.contains(.errorsVerbous) && !registeredErrors.isEmpty {
      output += "  | (Err): "
      for (domain, codes) in registeredErrors {
        codes.forEach { output += "[\(NSLocalizedString("\(domain).\($0)", comment: ""))] " }
      }
    } else if params.contains(.errors) && !registeredErrors.isEmpty {
      output += "  | (Err): "
      for (domain, codes) in registeredErrors {
        output += "\(domain) > "
        codes.forEach { output += "\($0) " }
      }
    }
    print(output)
    
    let models = childModels.sorted { return $0.timeStamp.compare($1.timeStamp) == .orderedAscending }
    
    models.forEach {
      var decoration: NodDecoration
      if models.count == 1 {
        decoration = .Last
      } else {
        decoration = $0 == models.last ? .Last : .Middle
      }
      
      $0.printTree(withPrefix: nextPrefix, decoration: decoration, params: params, sender: sender)
    }
  }
  
}

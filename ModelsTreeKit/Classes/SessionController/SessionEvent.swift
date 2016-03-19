//
//  SessionEvent.swift
//  ModelsTreeKit
//
//  Created by aleksey on 28.02.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

public protocol SessionEventName {
  var rawValue: String { get }
}

public func ==(lhs: SessionEventName, rhs: SessionEventName) -> Bool {
  return lhs.rawValue == rhs.rawValue
}

public struct SessionEvent {
  public var name: SessionEventName
  public var object: Any?
  public var userInfo: [String: Any]
  
  public init(name: SessionEventName, object: Any? = nil, userInfo: [String: Any] = [:]) {
    self.name = name
    self.object = object
    self.userInfo = userInfo
  }
  
  public var hashValue: Int {
    return name.rawValue.hashValue
  }

}

extension SessionEvent: Equatable, Hashable {
  
}

public func ==(lhs: SessionEvent, rhs: SessionEvent) -> Bool {
  return lhs.name.rawValue == rhs.name.rawValue
}
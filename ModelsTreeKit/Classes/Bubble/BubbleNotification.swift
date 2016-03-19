//
//  BubbleNotification.swift
//  ModelsTreeKit
//
//  Created by aleksey on 27.02.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

public protocol BubbleNotificationName {
  var rawValue: String { get }
}

public func ==(lhs: BubbleNotificationName, rhs: BubbleNotificationName) -> Bool {
  return lhs.rawValue == rhs.rawValue
}

import Foundation

public struct BubbleNotification {
  public var name: BubbleNotificationName
  public var domain: String
  public var object: Any?
  
  public init(name: BubbleNotificationName, domain: String, object: Any? = nil) {
    self.name = name
    self.domain = domain
    self.object = object
  }
  
  public var hashValue: Int {
    return (name.rawValue.hashValue &+ name.rawValue.hashValue).hashValue
  }
}

extension BubbleNotification: Hashable, Equatable {
  
}

public func ==(a: BubbleNotification, b: BubbleNotification) -> Bool {
  return a.name == b.name && a.domain == b.domain
}
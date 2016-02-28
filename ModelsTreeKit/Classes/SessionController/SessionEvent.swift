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

public struct SessionEvent {
  var name: String
  
  public init(name: SessionEventName) {
    self.name = name.rawValue
  }
}

extension SessionEvent: Equatable {
}

public func ==(lhs: SessionEvent, rhs: SessionEvent) -> Bool {
  return lhs.name == rhs.name
}
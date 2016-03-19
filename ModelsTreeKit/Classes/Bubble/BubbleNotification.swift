//
//  BubbleNotification.swift
//  ModelsTreeKit
//
//  Created by aleksey on 27.02.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

public struct BubbleNotification {
  public var code: Int
  public var domain: String
  
  public init(code: Int, domain: String) {
    self.code = code
    self.domain = domain
  }
  
  public var hashValue: Int {
    return (code.hashValue &+ domain.hashValue).hashValue
  }
}

extension BubbleNotification: Hashable, Equatable {
  
}

public func ==(a: BubbleNotification, b: BubbleNotification) -> Bool {
  return a.code == b.code && a.domain == b.domain
}
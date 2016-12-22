//
//  Wrapper.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 22.12.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

extension String: Wrappable {}
extension Int : Wrappable {}

protocol Wrappable: Any {}

extension Wrappable {
  
  func wrapped() -> Wrapper {
    return Wrapper(self)
  }
  
}

class Wrapper {
  
  var object: Any
  
  init(_ object: Any) {
    self.object = object
  }
  
  func unwrapped() -> Any {
    return object
  }
  
  var description: String {
    get {
      return String(describing: object)
    }
  }
  
}

extension Wrapper: CustomStringConvertible {}

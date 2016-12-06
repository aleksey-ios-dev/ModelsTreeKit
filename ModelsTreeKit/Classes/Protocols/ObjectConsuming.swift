//
// Created by aleksey on 06.11.15.
// Copyright (c) 2015 aleksey chernish. All rights reserved.
//

import Foundation

public protocol ObjectConsuming {
  
  associatedtype ObjectType
  
  func applyObject(_ object: ObjectType) -> Void
  
}

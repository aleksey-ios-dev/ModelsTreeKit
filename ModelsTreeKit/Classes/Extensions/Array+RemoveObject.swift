//
// Created by aleksey on 05.11.15.
// Copyright (c) 2015 aleksey chernish. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
  
  mutating func removeObject(object: Element) {
    if let index = self.index(of: object) {
      self.remove(at: index)
    }
  }
  
}

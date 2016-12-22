//
//  CollectionType+SafeCheck.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 22.12.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
  
  subscript (safe index: Index) -> Generator.Element? {
    return indices.contains(index) ? self[index] : nil
  }
  
}

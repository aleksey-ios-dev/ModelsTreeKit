//
// Created by aleksey on 05.11.15.
// Copyright (c) 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class ObjectsDataSource<ObjectType>: Equatable {
  
  let beginUpdatesSignal = Pipe<Void>()
  let endUpdatesSignal = Pipe<Void>()
  let didChangeObjectSignal = Pipe<(object: ObjectType, changeType: ListChangeType, fromIndexPath: IndexPath?, toIndexPath: IndexPath?)>()
  let didChangeSectionSignal = Pipe<(changeType: ListChangeType, fromIndex: Int?, toIndex: Int?)>()
  let reloadDataSignal = Pipe<Void>()
  let uid = NSUUID()
  var hashValue: Int {
    return uid.hashValue
  }
  
  func numberOfSections() -> Int {
    return 0
  }
  
  public func numberOfObjectsInSection(_ section: Int) -> Int {
    return 0
  }
  
  public func objectAtIndexPath(_ indexPath: IndexPath) -> ObjectType? {
    return nil
  }
  
  public func titleForSection(atIndex sectionIndex: Int) -> String? {
    return nil
  }
  
}

public func ==<T>(lhs: ObjectsDataSource<T>, rhs: ObjectsDataSource<T>) -> Bool {
  return lhs.uid == rhs.uid
}

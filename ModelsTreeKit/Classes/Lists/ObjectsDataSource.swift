//
// Created by aleksey on 05.11.15.
// Copyright (c) 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class ObjectsDataSource<ObjectType> {
  
  let beginUpdatesSignal = Signal<Void>()
  let endUpdatesSignal = Signal<Void>()
  let didChangeObjectSignal = Signal<(object: ObjectType, changeType: ListChangeType, fromIndexPath: NSIndexPath?, toIndexPath: NSIndexPath?)>()
  let didChangeSectionSignal = Signal<(changeType: ListChangeType, fromIndex: Int?, toIndex: Int?)>()
  let reloadDataSignal = Signal<Void>()
  
  func numberOfSections() -> Int {
    return 0
  }
  
  func numberOfObjectsInSection(section: Int) -> Int {
    return 0
  }
  
  func objectAtIndexPath(indexPath: NSIndexPath) -> ObjectType? {
    return nil
  }
  
}

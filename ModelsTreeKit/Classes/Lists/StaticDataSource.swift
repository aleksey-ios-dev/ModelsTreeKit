//
// Created by aleksey on 05.11.15.
// Copyright (c) 2015 aleksey chernish. All rights reserved.
//

import Foundation

public struct StaticObjectsSection<U> {
  
  var title: String?
  var objects: [U]
  
  public init(title: String?, objects: [U]) {
    self.title = title
    self.objects = objects
  }
  
}

public class StaticDataSource<ObjectType: Equatable, Hashable> : ObjectsDataSource<ObjectType> {
  
  public override init() { }
  
  public var sections: [StaticObjectsSection<ObjectType>] = [] {
    didSet { reloadDataSignal.sendNext() }
  }
  
  override func numberOfSections() -> Int {
    return sections.count
  }
  
  override func numberOfObjectsInSection(section: Int) -> Int {
    return sections[section].objects.count
  }
  
  override func objectAtIndexPath(indexPath: NSIndexPath) -> ObjectType? {
    return sections[indexPath.section].objects[indexPath.row]
  }
  
  public func indexPath(forObject object: ObjectType) -> NSIndexPath {
    var objectRow = 0
    var objectSection = 0
    
    for (index, section) in sections.enumerate() {
      if section.objects.contains(object) {
        objectSection = index
        objectRow = section.objects.indexOf(object)!
      }
    }
    
    return NSIndexPath(forRow: objectRow, inSection: objectSection) 
  }
  
}

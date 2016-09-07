//
//  ListDataSource.swift
//  SessionSwift
//
//  Created by aleksey on 16.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class ListDataSource<ObjectType, GroupKeyType where
  ObjectType: Hashable, ObjectType: Equatable,
GroupKeyType: Hashable, GroupKeyType: Comparable>: ObjectsDataSource<ObjectType> {
  
  typealias Section = (objects: [ObjectType], key: GroupKeyType?)
  typealias Sections = [Section]
  
  public var groupingCriteria: ((ObjectType) -> GroupKeyType)?
  public var groupsSortingCriteria: (GroupKeyType, GroupKeyType) -> Bool = { return $0 < $1 }
  public var groupContentsSortingCriteria: ((ObjectType, ObjectType) -> Bool)?
  
  private var sections = Sections()
  private let pool = AutodisposePool()
  
  public init(list: List<ObjectType>) {
    super.init()
    
    list.beginUpdatesSignal.subscribeNext { [weak self] in self?.beginUpdates() }.putInto(pool: pool)
    list.endUpdatesSignal.subscribeNext { [weak self] in self?.endUpdates() }.putInto(pool: pool)
    list.didReplaceContentSignal.subscribeNext() { [weak self] objects in
      guard let strongSelf = self else { return }
      strongSelf.sections = strongSelf.arrangedSectionsFrom(objects: objects)
    }.putInto(pool: pool)
    
    list.didChangeContentSignal.subscribeNext { [weak self] insertions, deletions, updates in
      guard let strongSelf = self else { return }
      let oldSections = strongSelf.sections
      strongSelf.applyInsertions(insertions: insertions, deletions: deletions, updates: updates)
      strongSelf.pushInsertions(
        insertions: insertions,
        deletions: deletions,
        updates: updates,
        oldSections: oldSections)
    }.putInto(pool: pool)
  }
  
  //Helpers
  
  public func fetchAllFrom(list: List<ObjectType>) {
    sections = arrangedSectionsFrom(objects: list.objects)
  }
  
  public func indexPathFor(object: ObjectType) -> NSIndexPath? {
    return indexPathFor(object: object, inSections: sections)
  }
  
  public func allObjects() -> [[ObjectType]] {
    if sections.isEmpty { return [] }
    return sections.map {return $0.objects}
  }
  
  public override func numberOfSections() -> Int {
    return sections.count
  }
  
  public override func numberOfObjectsInSection(section: Int) -> Int {
    return sections[section].objects.count
  }
  
  public override func objectAtIndexPath(indexPath: NSIndexPath) -> ObjectType? {
    return objectAtIndexPath(indexPath: indexPath, inSections: sections)
  }
  
  func objectAtIndexPath(indexPath: NSIndexPath, inSections sections: Sections) -> ObjectType? {
    return sections[indexPath.section].objects[indexPath.row]
  }
  
  //Private
  
  private func arrangedSectionsFrom(objects: Set<ObjectType>) -> Sections {
    if objects.isEmpty { return [] }
    
    guard let groupingBlock = groupingCriteria else {
      if let sortingCriteria = groupContentsSortingCriteria {
        return [(objects: objects.sorted(by: sortingCriteria), key: nil)]
      } else {
        return [(objects: Array(objects), key: nil)]
      }
    }
    
    var groupsDictionary = [GroupKeyType: [ObjectType]]()
    
    for object in objects {
      let key = groupingBlock(object)
      
      if groupsDictionary[key] == nil {
        groupsDictionary[key] = []
      }
      groupsDictionary[key]!.append(object)
    }
    
    let sortedKeys = groupsDictionary.keys.sorted(by: groupsSortingCriteria)
    var result = Sections()
    
    for key in sortedKeys {
      var objects = groupsDictionary[key]!
      if let sortingCriteria = groupContentsSortingCriteria {
        objects = objects.sorted(by: sortingCriteria)
      }
      result.append((objects, key))
    }
    return result
  }
  
  private func applyInsertions(insertions: Set<ObjectType>, deletions: Set<ObjectType>, updates: Set<ObjectType>) {
    var objects = allObjectsSet()
    objects.formUnion(insertions.union(updates))
    objects.subtract(deletions)
    
    sections = arrangedSectionsFrom(objects: objects)
  }
  
  private func pushInsertions(
    insertions: Set<ObjectType>,
    deletions: Set<ObjectType>,
    updates: Set<ObjectType>,
    oldSections: Sections) {
      
      //Objects
    
      for object in insertions {
        didChangeObjectSignal.sendNext(newValue: (
          object: object,
          changeType: .Insertion,
          fromIndexPath: nil,
          toIndexPath: indexPathFor(object: object, inSections: sections))
        )
      }
      
      for object in deletions {
        didChangeObjectSignal.sendNext(newValue: (
          object: object,
          changeType: .Deletion,
          fromIndexPath: indexPathFor(object: object, inSections: oldSections),
          toIndexPath: nil)
        )
      }
      
      for object in updates {
        guard
          let oldIndexPath = indexPathFor(object: object, inSections: oldSections),
          let newIndexPath = indexPathFor(object: object, inSections: oldSections)
          else {
            continue
        }
        
        let changeType: ListChangeType = oldIndexPath == newIndexPath ? .Update : .Move
        
        didChangeObjectSignal.sendNext(newValue: (
          object: object,
          changeType: changeType,
          fromIndexPath: oldIndexPath,
          toIndexPath: newIndexPath)
        )
      }
      
      //Sections
      
      for (index, section) in oldSections.enumerated() {
        if sections.filter({ return $0.key == section.key }).isEmpty {
          didChangeSectionSignal.sendNext(newValue: (
            changeType: .Deletion,
            fromIndex: index,
            toIndex: nil)
          )
        }
      }
      
      for (index, section) in sections.enumerated() {
        if oldSections.filter({ return $0.key == section.key }).isEmpty {
          didChangeSectionSignal.sendNext(newValue: (
            changeType: .Insertion,
            fromIndex: nil,
            toIndex: index)
          )
        }
      }
  }
  
  private func indexPathFor(object: ObjectType, inSections sections: Sections) -> NSIndexPath? {
    var allObjects: [ObjectType] = []
    
    for section in sections {
      allObjects.append(contentsOf: section.objects)
    }
    
    if !allObjects.contains(object) { return nil }
    
    var row = 0
    var section = 0
    var objectFound = false
    
    for (index, sectionInfo) in sections.enumerated() {
      if sectionInfo.objects.contains(object) {
        objectFound = true
        section = index
        row = sectionInfo.objects.index(of: object)!
        
        break
      }
    }
    
    return objectFound ? NSIndexPath(row: row, section: section) : nil
  }
  
  private func allObjectsSet() -> Set<ObjectType> {
    var result: Set<ObjectType> = []
    
    for section in sections {
      result.formUnion(section.objects)
    }
    
    return result
  }
  
  private func beginUpdates() {
    beginUpdatesSignal.sendNext(newValue: ())
  }
  
  private func endUpdates() {
    endUpdatesSignal.sendNext(newValue: ())
  }
  
  private func rearrangeAndPushReload() {
    sections = arrangedSectionsFrom(objects: allObjectsSet())
    reloadDataSignal.sendNext(newValue: ())
  }
  
}

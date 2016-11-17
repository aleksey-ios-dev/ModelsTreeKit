//
//  UnorderedListDataAdapter.swift
//  SessionSwift
//
//  Created by aleksey on 16.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class UnorderedListDataAdapter<ObjectType, GroupKeyType>: ObjectsDataSource<ObjectType> where
  ObjectType: Hashable, ObjectType: Equatable,
GroupKeyType: Hashable, GroupKeyType: Comparable {
  
  typealias Section = (objects: [ObjectType], key: GroupKeyType?)
  typealias Sections = [Section]
  
  public var groupingCriteria: ((ObjectType) -> GroupKeyType)?
  public var groupsSortingCriteria: (GroupKeyType, GroupKeyType) -> Bool = { return $0 < $1 }
  public var groupContentsSortingCriteria: ((ObjectType, ObjectType) -> Bool)?
  
  private var sections = Sections()
  private let pool = AutodisposePool()
  
  public init(list: UnorderedList<ObjectType>) {
    super.init()
    
    list.beginUpdatesSignal.subscribeNext { [weak self] in self?.beginUpdates() }.putInto(pool)
    list.endUpdatesSignal.subscribeNext { [weak self] in self?.endUpdates() }.putInto(pool)
    list.didReplaceContentSignal.subscribeNext() { [weak self] objects in
      guard let strongSelf = self else { return }
      strongSelf.sections = strongSelf.arrangedSections(fromObjects: objects)
    }.putInto(pool)
    
    list.didChangeContentSignal.subscribeNext { [weak self] insertions, deletions, updates in
      guard let strongSelf = self else { return }
      let oldSections = strongSelf.sections
      strongSelf.applyInsertions(insertions: insertions, deletions: deletions, updates: updates)
      strongSelf.pushInsertions(
        insertions: insertions,
        deletions: deletions,
        updates: updates,
        oldSections: oldSections)
    }.putInto(pool)
  }
  
  //Helpers
  
  public func fetchAllFrom(list: UnorderedList<ObjectType>) {
    sections = arrangedSections(fromObjects: list.objects)
  }
  
  public func indexPath(forObject object: ObjectType) -> IndexPath? {
    return indexPath(forObject: object, inSections: sections)
  }
  
  public func allObjects() -> [[ObjectType]] {
    if sections.isEmpty { return [] }
    return sections.map {return $0.objects}
  }
  
  public override func numberOfSections() -> Int {
    return sections.count
  }
  
  public override func numberOfObjectsInSection(_ section: Int) -> Int {
    return sections[section].objects.count
  }
  
  public override func objectAtIndexPath(_ indexPath: IndexPath) -> ObjectType? {
    return object(atIndexPath: indexPath, inSections: sections)
  }
  
  func object(atIndexPath indexPath: IndexPath, inSections sections: Sections) -> ObjectType? {
    return sections[indexPath.section].objects[indexPath.row]
  }
  
  override func titleForSection(atIndex sectionIndex: Int) -> String? {
    return sections[sectionIndex].key as? String
  }
  
  //Private
  
  private func arrangedSections(fromObjects objects: Set<ObjectType>) -> Sections {
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
    
    sections = arrangedSections(fromObjects: objects)
  }
  
  private func pushInsertions(
    insertions: Set<ObjectType>,
    deletions: Set<ObjectType>,
    updates: Set<ObjectType>,
    oldSections: Sections) {
    
    //Objects
    
    for object in insertions {
      didChangeObjectSignal.sendNext((
        object: object,
        changeType: .Insertion,
        fromIndexPath: nil,
        toIndexPath: indexPath(forObject: object, inSections: sections))
      )
    }
    
    for object in deletions {
      didChangeObjectSignal.sendNext((
        object: object,
        changeType: .Deletion,
        fromIndexPath: indexPath(forObject: object, inSections: oldSections),
        toIndexPath: nil)
      )
    }
    
    for object in updates {
      guard
        let oldIndexPath = indexPath(forObject: object, inSections: oldSections),
        let newIndexPath = indexPath(forObject: object, inSections: sections)
        else {
          continue
      }
      
      let changeType: ListChangeType = oldIndexPath == newIndexPath ? .Update : .Move
      
      didChangeObjectSignal.sendNext((
        object: object,
        changeType: changeType,
        fromIndexPath: oldIndexPath,
        toIndexPath: newIndexPath)
      )
    }
    
    //Sections
    
    for (index, section) in oldSections.enumerated() {
      if sections.filter({ return $0.key == section.key }).isEmpty {
        didChangeSectionSignal.sendNext((
          changeType: .Deletion,
          fromIndex: index,
          toIndex: nil)
        )
      }
    }
    
    for (index, section) in sections.enumerated() {
      if oldSections.filter({ return $0.key == section.key }).isEmpty {
        didChangeSectionSignal.sendNext((
          changeType: .Insertion,
          fromIndex: nil,
          toIndex: index)
        )
      }
    }
  }
  
  private func indexPath(forObject object: ObjectType, inSections sections: Sections) -> IndexPath? {
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
    
    return objectFound ? IndexPath(row: row, section: section) : nil
  }
  
  private func allObjectsSet() -> Set<ObjectType> {
    var result: Set<ObjectType> = []
    
    for section in sections {
      result.formUnion(Set(section.objects))
    }
    
    return result
  }
  
  private func beginUpdates() {
    beginUpdatesSignal.sendNext()
  }
  
  private func endUpdates() {
    endUpdatesSignal.sendNext()
  }
  
  private func rearrangeAndPushReload() {
    sections = arrangedSections(fromObjects: allObjectsSet())
    reloadDataSignal.sendNext()
  }
  
}

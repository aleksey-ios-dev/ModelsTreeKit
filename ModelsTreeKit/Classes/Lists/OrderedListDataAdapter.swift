//
//  OrderedListDataAdapter.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 15.10.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

public class OrderedListDataAdapter<ObjectType>: ObjectsDataSource<ObjectType> where ObjectType: Hashable & Equatable {
  
  public var groupingCriteria: ((ObjectType) -> String)?
  public let groupsSortingCriteria: (String, String) -> Bool = { return $0 < $1 }
  
  private(set) var sections = [StaticObjectsSection<ObjectType>]()
  private let pool = AutodisposePool()
  
  public init(list: OrderedList<ObjectType>) {
    super.init()
    
    list.beginUpdatesSignal.subscribeNext { [weak self] in self?.beginUpdates() }.putInto(pool)
    list.endUpdatesSignal.subscribeNext { [weak self] in self?.endUpdates() }.putInto(pool)
    list.didReplaceContentSignal.subscribeNext() { [weak self] objects in
      self?.rearrangeAndPushReload(withObjects: objects)
    }.putInto(pool)
    
    list.didChangeContentSignal.subscribeNext { [weak self] appendedObjects, deletions, updates in
      guard let strongSelf = self else { return }
      let oldSections = strongSelf.sections
      strongSelf.apply(appendedObjects: appendedObjects, deletions: deletions, updates: updates)
      strongSelf.push(
        appendedObjects: appendedObjects,
        deletions: deletions,
        updates: updates,
        oldSections: oldSections
      )
      }.putInto(pool)
  }
  
  private func beginUpdates() {
    beginUpdatesSignal.sendNext()
  }
  
  private func endUpdates() {
    endUpdatesSignal.sendNext()
  }
  
  private func apply(appendedObjects: [ObjectType], deletions: Set<ObjectType>, updates: Set<ObjectType>) {
      applyAppendedObjects(appendedObjects)
      applyDeletions(deletions)
    }
    
  private func applyAppendedObjects(_ appendedObjects: [ObjectType]) {
    if appendedObjects.isEmpty { return }
    
    if groupingCriteria == nil {
      if self.sections.isEmpty {
        self.sections.append(StaticObjectsSection(title: nil, objects: []))
      }
      let section = self.sections.first!
      section.objects += appendedObjects
    } else {
      var lastSectionKey = sections.last?.title
      
      for object in appendedObjects {
        if groupingCriteria!(object) == lastSectionKey {
          let lastSection = sections.last!
          lastSection.objects += [object]
        } else {
          lastSectionKey = groupingCriteria!(object)
          let newSection = StaticObjectsSection(title: lastSectionKey, objects: [object])
          self.sections.append(newSection)
        }
      }
    }
  }
  
  private func applyDeletions(_ deletions: Set<ObjectType>) {
    if deletions.isEmpty { return }
    
    if groupingCriteria == nil {
      sections.first!.objects = sections.first!.objects.filter { !deletions.contains($0) }
      
      return
    }
    
    deletions.forEach { deletedObject in
      let groupKey = groupingCriteria!(deletedObject)
      if let section = (sections.filter { $0.title == groupKey }).first {
        section.objects = section.objects.filter { $0 != deletedObject }
      }
    }
    
    sections = sections.filter { !$0.objects.isEmpty }
  }
  
  private func push(
    appendedObjects: [ObjectType],
    deletions: Set<ObjectType>,
    updates: Set<ObjectType>,
    oldSections: [StaticObjectsSection<ObjectType>]) {
    //Objects
    
    for object in appendedObjects {
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
      if sections.filter({ return $0.title == section.title }).isEmpty {
        didChangeSectionSignal.sendNext((
          changeType: .Deletion,
          fromIndex: index,
          toIndex: nil)
        )
      }
    }
    
    for (index, section) in sections.enumerated() {
      if oldSections.filter({ return $0.title == section.title }).isEmpty {
        didChangeSectionSignal.sendNext((
          changeType: .Insertion,
          fromIndex: nil,
          toIndex: index)
        )
      }
    }
  }
  
  private func arrangedSectionsFrom(objects: [ObjectType]) -> [StaticObjectsSection<ObjectType>] {
    //FOR REPLACEMENT
    return []
  }
  
  private func indexPath(forObject object: ObjectType, inSections sections: [StaticObjectsSection<ObjectType>]) -> IndexPath? {
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
  
  private func rearrangeAndPushReload(withObjects objects: [ObjectType]) {
    sections = []
    applyAppendedObjects(objects)
    reloadDataSignal.sendNext()
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
  
  func object(atIndexPath indexPath: IndexPath, inSections sections: [StaticObjectsSection<ObjectType>]) -> ObjectType? {
    return sections[indexPath.section].objects[indexPath.row]
  }
  
  override public func titleForSection(atIndex sectionIndex: Int) -> String? {
    return sections[sectionIndex].title
  }
  
}

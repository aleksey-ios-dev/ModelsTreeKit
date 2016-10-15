//
//  OrderedListDataAdapter.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 15.10.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

public class OrderedListDataAdapter<ObjectType where
  ObjectType: Hashable, ObjectType: Equatable>: ObjectsDataSource<ObjectType> {
  
  typealias Section = (objects: [ObjectType], key: String?)
  typealias Sections = [Section]
  
  public var groupingCriteria: (ObjectType -> String)?
  public let groupsSortingCriteria: (String, String) -> Bool = { return $0 < $1 }
  
  private var sections = Sections()
  private let pool = AutodisposePool()
  
  public init(list: OrderedList<ObjectType>) {
    super.init()
    
    list.beginUpdatesSignal.subscribeNext { [weak self] in self?.beginUpdates() }.putInto(pool)
    list.endUpdatesSignal.subscribeNext { [weak self] in self?.endUpdates() }.putInto(pool)
    list.didReplaceContentSignal.subscribeNext() { [weak self] objects in
      guard let strongSelf = self else { return }
      strongSelf.sections = strongSelf.arrangedSectionsFrom(objects)
      }.putInto(pool)
    
    list.didChangeContentSignal.subscribeNext { [weak self] appendedObjects, deletions, updates in
      guard let strongSelf = self else { return }
      let oldSections = strongSelf.sections
      strongSelf.applyAppendedObjects(appendedObjects, deletions: deletions, updates: updates)
      strongSelf.pushAppendedObjects(
        appendedObjects,
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
  
  private func applyAppendedObjects(appendedObjects: [ObjectType], deletions: Set<ObjectType>, updates: Set<ObjectType>) {
  }
  
  private func pushAppendedObjects(
    appendedObjects: [ObjectType],
    deletions: Set<ObjectType>,
    updates: Set<ObjectType>,
    oldSections: Sections) {
  }
  
  private func arrangedSectionsFrom(objects: [ObjectType]) -> Sections {
    return []
  }
  
    

  
}

//
//  OrderedListDataAdapter.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 15.10.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

public class OrderedListDataAdapter<ObjectType, GroupKeyType where
  ObjectType: Hashable, ObjectType: Equatable,
GroupKeyType: Hashable, GroupKeyType: Comparable>: ObjectsDataSource<ObjectType> {
  
  typealias Section = (objects: [ObjectType], key: GroupKeyType?)
  typealias Sections = [Section]
  
  public var groupingCriteria: (ObjectType -> GroupKeyType)?
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
      strongSelf.sections = strongSelf.arrangedSectionsFrom(objects)
      }.putInto(pool)
    
    list.didChangeContentSignal.subscribeNext { [weak self] insertions, deletions, updates in
      guard let strongSelf = self else { return }
      let oldSections = strongSelf.sections
      strongSelf.applyInsertions(insertions, deletions: deletions, updates: updates)
      strongSelf.pushInsertions(
        insertions,
        deletions: deletions,
        updates: updates,
        oldSections: oldSections)
      }.putInto(pool)
}

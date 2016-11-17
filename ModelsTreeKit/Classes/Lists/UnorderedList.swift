//
//  UnorderedList.swift
//  SessionSwift
//
//  Created by aleksey on 15.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

enum ListChangeType {
  
  case Deletion, Insertion, Update, Move
  
}

public class UnorderedList<T>: Model where T: Hashable & Equatable {
  
  let beginUpdatesSignal = Pipe<Void>()
  let endUpdatesSignal = Pipe<Void>()
  let didChangeContentSignal = Pipe<(insertions: Set<T>, deletions: Set<T>, updates: Set<T>)>()
  let didReplaceContentSignal = Pipe<Set<T>>()
  
  public private(set) var objects = Set<T>()
  
  private var updatesPool = UpdatesPool<T>()
  
  public init(parent: Model?, objects: [T] = []) {
    super.init(parent: parent)
    
    self.objects = Set(objects)
  }
  
  public required init(parent: Model?) {
    fatalError("init(parent:) has not been implemented")
  }
  
  public func performUpdates(updates: (UnorderedList) -> Void) {
    beginUpdates()
    updates(self)
    endUpdates()
  }
  
  internal func beginUpdates() {
      beginUpdatesSignal.sendNext()
  }
  
  internal func endUpdates() {
    applyChanges()
    pushUpdates()
    updatesPool.drain()
    endUpdatesSignal.sendNext()
  }
  
  //Operations on objects. Use ONLY inside performBatchUpdate() call!
  
  public func delete(_ objects: [T]) {
    if objects.isEmpty { return }
    updatesPool.deletions.formUnion(Set(objects))
  }
  
  public func insert(_ objects: [T]) {
    if objects.isEmpty { return }
    updatesPool.insertions.formUnion(Set(objects))
  }
  
  //Call outside the batch update block. Informs subscriber that data should be reloaded
  //To perform batch-based replacement use removeAllObjects() and insert() methods within the batch update block
  
  public func replaceWith(_ objects: [T]) {
    self.objects = Set(objects)
    didReplaceContentSignal.sendNext(self.objects)
  }
  
  public func reset() {
    replaceWith([])
  }
  
  public func removeAllObjects() {
    delete(Array(objects))
  }
  
  public func didFinishFetchingObjects() {
  }
  
  //Private
  
  private func applyChanges() {
    updatesPool.optimizeFor(objects: objects)
    objects.formUnion(updatesPool.insertions)
    objects.formUnion(updatesPool.updates)
    objects.subtract(updatesPool.deletions)
  }
  
  private func pushUpdates() {
    didChangeContentSignal.sendNext((
      insertions: updatesPool.insertions,
      deletions: updatesPool.deletions,
      updates: updatesPool.updates)
    )
  }
  
}

internal class UpdatesPool<T> where T: Hashable & Equatable {
  
  var insertions = Set<T>()
  var deletions = Set<T>()
  var updates = Set<T>()
  
  func addObjects(objects: [T], forChangeType changeType: ListChangeType) {
    switch changeType {
    case .Insertion: insertions.formUnion(objects)
    case .Deletion: deletions.formUnion(objects)
    default: break
    }
  }
  
  func drain() {
    insertions = []
    deletions = []
    updates = []
  }
  
  func optimizeFor(objects: Set<T>) {
    optimizeDuplicatingEntries()
    updates.formUnion(insertions.intersection(objects))
    insertions.subtract(updates)
    deletions.formIntersection(objects)
  }
  
  func optimizeDuplicatingEntries() {
    let commonObjects = insertions.intersection(deletions)
    insertions.subtract(commonObjects)
    deletions.subtract(commonObjects)
  }
  
}

//
//  OrderedList.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 15.10.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

public class OrderedList<T>: Model where T: Hashable & Equatable {
  
  let beginUpdatesSignal = Pipe<Void>()
  let endUpdatesSignal = Pipe<Void>()
  let didChangeContentSignal = Pipe<(appendedObjects: [T], deletions: Set<T>, updates: Set<T>)>()
  let didReplaceContentSignal = Pipe<[T]>()
  
  public private(set) var objects = [T]() {
    didSet {
      objectsSet = Set(objects)
    }
  }
  
  public private(set) var objectsSet = Set<T>()
  
  private var updatesPool = OrderedListUpdatesPool<T>()
  
  public init(parent: Model?, objects: [T] = []) {
    super.init(parent: parent)
    
    self.objects = objects
  }
  
  public required init(parent: Model?) {
    super.init(parent: parent)
  }
  
  public func performUpdates(updates: (OrderedList) -> Void) {
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
  
  private func pushUpdates() {
    didChangeContentSignal.sendNext((
      appendedObjects: updatesPool.appendedObjects,
      deletions: updatesPool.deletions,
      updates: updatesPool.updates)
    )
  }
  
  public func replaceWith(_ objects: [T]) {
    self.objects = objects
    didReplaceContentSignal.sendNext(self.objects)
  }
  
  //Operations on objects. Use ONLY inside performBatchUpdate() call!
  
  public func append(_ objects: [T]) {
    updatesPool.appendedObjects += objects
  }
  
  public func delete(_ objects: [T]) {
    if objects.isEmpty { return }
    updatesPool.deletions.formUnion(objects)
  }
  
  public func update(_ objects: [T]) {
    if objects.isEmpty { return }
    updatesPool.updates.formUnion(objects)
  }
  
  private func applyChanges() {
    updatesPool.optimize(for: objectsSet)
    objects = objects.filter { !self.updatesPool.deletions.contains($0) }
    objects = objects + updatesPool.appendedObjects
    objects = objects.map { return updatesPool.updates.objectEqualTo($0) ?? $0 }
  }
  
}

internal class OrderedListUpdatesPool<T> where T: Hashable & Equatable {
  
  var appendedObjects = [T]()
  var deletions = Set<T>()
  var updates = Set<T>()
  
  func drain() {
    appendedObjects = []
    deletions = []
    updates = []
  }
  
  func optimize(for objects: Set<T>) {
    deletions.formIntersection(objects)
    updates.subtract(deletions)
    updates.formIntersection(objects)
    appendedObjects = appendedObjects.removeDuplicates().filter {
      !self.deletions.contains($0) && !objects.contains($0)
    }
  }
  
}

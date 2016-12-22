//
//  MapDataAdapter.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 17.12.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

extension ObjectsDataSource {
  
  func map<U>(_ mapper: @escaping ((ObjectType) -> U)) -> MapDataAdapter<ObjectType, U> {
    return MapDataAdapter(mappedDataSource: self, mapper: mapper)
  }
  
}

public class MapDataAdapter<T, U>: ObjectsDataSource<U> {
  
  public private(set) var sections = [StaticObjectsSection<U>]()
  
  private var mappedDataSource: ObjectsDataSource<T>
  private var mapper: ((T) -> U)
  private let pool = AutodisposePool()
  private let changesPool = MappedSourceChangesPool<T>()
  
  public init(mappedDataSource: ObjectsDataSource<T>, mapper: @escaping (T) -> U) {
    self.mappedDataSource = mappedDataSource
    self.mapper = mapper
    
    super.init()
    
    remapFromSource()
    subscribeForMappedSource()
  }
  
  // MARK: - Access
  
  public override func objectAtIndexPath(_ indexPath: IndexPath) -> U? {
    return sections[indexPath.section].objects[indexPath.row]
  }
  
  public override func numberOfSections() -> Int {
    return mappedDataSource.numberOfSections()
  }
  
  public override func numberOfObjectsInSection(_ section: Int) -> Int {
    return mappedDataSource.numberOfObjectsInSection(section)
  }
  
  public override func titleForSection(atIndex sectionIndex: Int) -> String? {
    return mappedDataSource.titleForSection(atIndex: sectionIndex)
  }
  
  // MARK: - Private
  
  private func subscribeForMappedSource() {
    mappedDataSource.beginUpdatesSignal.subscribeNext { [weak self] in
      self?.beginUpdatesSignal.sendNext()
    }.putInto(pool)
    
    mappedDataSource.endUpdatesSignal.subscribeNext { [weak self] in
      self?.commitChanges()
      self?.endUpdatesSignal.sendNext()
    }.putInto(pool)
    
    mappedDataSource.reloadDataSignal.subscribeNext { [weak self] in
      self?.remapFromSource()
      self?.reloadDataSignal.sendNext()
    }.putInto(pool)
    
    mappedDataSource.didChangeObjectSignal.subscribeNext { [weak self] object, changeType, fromIndexPath, toIndexPath in
      guard let _self = self else { return }

      switch changeType {
      
      case .Deletion:
        let mappedObject = _self.sections[fromIndexPath!.section].objects[fromIndexPath!.row]
        _self.changesPool.addIndexPathForDeletion(fromIndexPath!)
        _self.didChangeObjectSignal.sendNext((object: mappedObject, changeType: changeType, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath))
        
      case .Insertion:
        _self.changesPool.addIndexPathForInsert(toIndexPath!)
        _self.didChangeObjectSignal.sendNext((object: _self.mapper(object), changeType: changeType, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath))
        
      case .Update:
        _self.changesPool.addIndexPathForUpdate(fromIndexPath!)
        _self.didChangeObjectSignal.sendNext((object: _self.mapper(object), changeType: changeType, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath))
      
      default:
        break
      }
      
    }.putInto(pool)
    
    mappedDataSource.didChangeSectionSignal.subscribeNext { [weak self] changeType, fromIndex, toIndex in
      self?.didChangeSectionSignal.sendNext((changeType: changeType, fromIndex: fromIndex, toIndex: toIndex))
      if changeType == .Insertion {
        self?.changesPool.indexesOfInsertedSections.append(toIndex!)
      } else if changeType == .Deletion {
        self?.changesPool.indexesOfDeletedSections.append(fromIndex!)
      }
    }.putInto(pool)
  }
  
  private func commitChanges() {
    changesPool.finalize()
    
    //Deletions 
    
    for section in changesPool.indexesOfSectionsWithDeletions() {
      let indexes = changesPool.deletionsInSection(section)
    
      var filteredObjects = [U]()
      let s = sections[section]
      for (index, object) in s.objects.enumerated() {
        if !indexes.contains(index) {
          filteredObjects.append(object)
        }
      }
      sections[section].objects = filteredObjects
    }
    
    //Remove deleted and insert new sections
    
    var filteredSections = [StaticObjectsSection<U>]()
    for (index, section) in sections.enumerated() {
      if !changesPool.indexesOfDeletedSections.contains(index) {
        filteredSections.append(section)
      }
    }
    sections = filteredSections
    for index in changesPool.indexesOfInsertedSections.sorted(by: > ) {
      sections.insert(StaticObjectsSection(title: mappedDataSource.titleForSection(atIndex: index), objects: []), at: index)
    }
    
    //Inserts
    
    for section in changesPool.indexesOfSectionsWithInserts() {
      let indexes = changesPool.insertsInSection(section)

      let s = sections[section]
      
      for index in indexes.sorted(by: < ) {
        let underlyingObject = mappedDataSource.objectAtIndexPath(IndexPath(row: index, section: section))
        s.objects.insert(mapper(underlyingObject!), at: index)        
      }
    }
    
    //Updates
    
    for section in changesPool.indexesOfSectionsWithUpdates() {
      let indexes = changesPool.updatesInSection(section)
      
      let s = sections[section]
      indexes.forEach {
        let underlyingObject = mappedDataSource.objectAtIndexPath(IndexPath(row: $0, section: section))
        s.objects[$0] = mapper(underlyingObject!)
      }
    }
    
    changesPool.drain()
  }
  
  private func remapFromSource() {
    var sections = [StaticObjectsSection<U>]()
    for section in 0..<mappedDataSource.numberOfSections() {
      var objects = [T]()
      for row in 0..<mappedDataSource.numberOfObjectsInSection(section) {
        objects.append(mappedDataSource.objectAtIndexPath(IndexPath(row: row, section: section))!)
      }
      let mappedSection = StaticObjectsSection<U>(title: mappedDataSource.titleForSection(atIndex: section), objects: objects.map { self.mapper($0) })
      sections.append(mappedSection)
    }
    
    self.sections = sections
  }
  
}

fileprivate class MappedSourceChangesPool<T> {
  
  private var insertions = [Int: [Int]]()
  private var deletions = [Int: [Int]]()
  private var updates = [Int: [Int]]()
  
  private var indexPathsForInsert = [IndexPath]()
  private var indexPathsForDeletion = [IndexPath]()
  private var indexPathsForUpdate = [IndexPath]()
  var indexesOfInsertedSections = [Int]()
  var indexesOfDeletedSections = [Int]()
  
  // Input for changes to be finalized
  
  func addIndexPathForInsert(_ indexPath: IndexPath) {
    indexPathsForInsert.append(indexPath)
  }
  
  func addIndexPathForDeletion(_ indexPath: IndexPath) {
    indexPathsForDeletion.append(indexPath)
  }
  
  func addIndexPathForUpdate(_ indexPath: IndexPath) {
    indexPathsForUpdate.append(indexPath)
  }
  
  func finalize() {
    insertions = finalizedIndexes(from: indexPathsForInsert)
    deletions = finalizedIndexes(from: indexPathsForDeletion)
    updates = finalizedIndexes(from: indexPathsForUpdate)
  }
  
  // Access after finalization
  
  func insertsInSection(_ section: Int) -> [Int] {
    return insertions[section]!
  }
  
  func indexesOfSectionsWithInserts() -> [Int] {
    return Array(insertions.keys)
  }
  
  func deletionsInSection(_ section: Int) -> [Int] {
    return deletions[section]!
  }
  
  func indexesOfSectionsWithDeletions() -> [Int] {
    return Array(deletions.keys)
  }
  
  func updatesInSection(_ section: Int) -> [Int] {
    return updates[section]!
  }
  
  func indexesOfSectionsWithUpdates() -> [Int] {
    return Array(updates.keys)
  }
  
  func drain() {
    insertions = [:]
    deletions = [:]
    updates = [:]
    indexPathsForInsert = []
    indexPathsForDeletion = []
    indexPathsForUpdate = []
    indexesOfInsertedSections = []
    indexesOfDeletedSections = []
  }
  
  // Private 
  
  private func finalizedIndexes(from indexPaths: [IndexPath]) -> [Int: [Int]]{
    var indexesDictionary = [Int: [Int]]()
    
    indexPaths.forEach {
      if indexesDictionary[$0.section] == nil {
        indexesDictionary[$0.section] = []
      }
      indexesDictionary[$0.section]?.append($0.row)
    }
    
    return indexesDictionary
  }
  
}

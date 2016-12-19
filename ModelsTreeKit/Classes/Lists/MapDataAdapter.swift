//
//  MapDataAdapter.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 17.12.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

class MapDataAdapter<T, U>: ObjectsDataSource<U> where
  T: Equatable, T: Hashable,
  U: Equatable, U: Hashable {
  
  private var mappedDataSource: ObjectsDataSource<T>
  private var mapper: ((T) -> U)
  private let pool = AutodisposePool()
  private let changesPool = MappedSourceChangesPool<T>()
  private(set) var sections = [StaticObjectsSection<U>]()
  
  init(mappedDataSource: ObjectsDataSource<T>, mapper: @escaping (T) -> U) {
    self.mappedDataSource = mappedDataSource
    self.mapper = mapper
    
    super.init()
    
    remapFromSource()
    subscribeForMappedSource()
  }
  
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
      
      //case .Update:
       // _self.cha
        //mappedObject = _self.mapper(object)
        //_self.sections[fromIndexPath!.section].objects[fromIndexPath!.row] = mappedObject
      
        
      case .Deletion:
        let mappedObject = _self.sections[fromIndexPath!.section].objects[fromIndexPath!.row]
        //_self.sections[fromIndexPath!.section].objects.remove(at: fromIndexPath!.row)
        
        if _self.changesPool.deletions[fromIndexPath!.section] == nil {
          _self.changesPool.deletions[fromIndexPath!.section] = []
        }
        _self.changesPool.deletions[fromIndexPath!.section]?.append(fromIndexPath!.row)
        _self.didChangeObjectSignal.sendNext((object: mappedObject, changeType: changeType, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath))
        
      case .Insertion:

        if _self.changesPool.insertions[toIndexPath!.section] == nil {
          _self.changesPool.insertions[toIndexPath!.section] = []
        }
        _self.changesPool.insertions[toIndexPath!.section]?.append(toIndexPath!.row)
        _self.didChangeObjectSignal.sendNext((object: _self.mapper(object), changeType: changeType, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath))
        
      case .Update:
        if _self.changesPool.updates[fromIndexPath!.section] == nil {
          _self.changesPool.updates[fromIndexPath!.section] = []
        }
        
        _self.changesPool.updates[fromIndexPath!.section].append(fromIndexPath!.row)
        
      /*case .Insertion:
        mappedObject = _self.mapper(object)
        _self.sections[toIndexPath!.section].objects.insert(mappedObject, at: toIndexPath!.row)
      
      case .Move:
        mappedObject = _self.sections[fromIndexPath!.section].objects[fromIndexPath!.row]
        _self.sections[fromIndexPath!.section].objects.remove(at: fromIndexPath!.row)
        _self.sections[toIndexPath!.section].objects.insert(mappedObject, at: toIndexPath!.row)
      }
    */
      default:
        break
      }
      
      //_self.didChangeObjectSignal.sendNext((object: mappedObject, changeType: changeType, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath))
      
    }.putInto(pool)
    
    mappedDataSource.didChangeSectionSignal.subscribeNext { [weak self] changeType, fromIndex, toIndex in
      guard let _self = self else { return }
      
      switch changeType {
      case .Insertion:
        _self.sections.insert(StaticObjectsSection<U>(title: _self.mappedDataSource.titleForSection(atIndex: toIndex!), objects: []), at: toIndex!)
      case .Deletion:
        _self.sections.remove(at: fromIndex!)
      default:
        break
      }
    }.putInto(pool)
  }
  
  private func commitChanges() {
    //update sections from changes pool
    print(changesPool.insertions)
    print("OLD SECTIONS")
    sections.map { $0.objects }.forEach { print($0) }
    
    for (section, indexes) in changesPool.deletions {
      var filteredObjects = [U]()
      let s = sections[section]
      for (index, object) in s.objects.enumerated() {
        if !indexes.contains(index) {
          filteredObjects.append(object)
        }
      }
      sections[section].objects = filteredObjects
    }
    
    //Insertions
    
    for (section, indexes) in changesPool.insertions {
      //var filteredObjects = [U]()
      let s = sections[section]

      for index in indexes {
        let underlyingObject = mappedDataSource.objectAtIndexPath(IndexPath(row: index, section: section))
        s.objects.insert(mapper(underlyingObject!), at: index)
      }
//        if !indexes.contains(index) {
  //        filteredObjects.append(object)
//        }
      }
    //  sections[section].objects = filteredObjects
    
    
    
    
    print("NEW SECTIONS")
    sections.map { $0.objects }.forEach { print($0) }
    changesPool.drain()
  }
  
  override func objectAtIndexPath(_ indexPath: IndexPath) -> U? {
    return sections[indexPath.section].objects[indexPath.row]
  }
  
  override func numberOfSections() -> Int {
    return mappedDataSource.numberOfSections()
  }
  
  override func numberOfObjectsInSection(_ section: Int) -> Int {
    return mappedDataSource.numberOfObjectsInSection(section)
  }
  
  override func titleForSection(atIndex sectionIndex: Int) -> String? {
    return mappedDataSource.titleForSection(atIndex: sectionIndex)
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
  
  var insertions = [Int: [Int]]()
  var deletions = [Int: [Int]]()
  var updates = [IndexPath]()
  var moves = [IndexPath: T]()
  
  func drain() {
    insertions = [:]
    deletions = [:]
    updates = []
    moves = [:]
  }
  
}

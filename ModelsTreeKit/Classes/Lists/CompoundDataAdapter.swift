//
//  CompoundDataAdapter.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 11.12.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

public class CompoundDataAdapter<ObjectType> : ObjectsDataSource<ObjectType> where ObjectType: Equatable, ObjectType: Hashable {
  
  public typealias ContainedDataSourceType = ObjectsDataSource<ObjectType>
  
  private let pool = AutodisposePool()
  private let dataSources: [ContainedDataSourceType]
  
  public init(dataSources: [ContainedDataSourceType]) {
    self.dataSources = dataSources
    
    super.init()
    
    subscribeForUpdates(inSources: dataSources)
  }
  
  // MARK: - Access to objects and sections
  
  public override func numberOfSections() -> Int {
    return dataSources.reduce(0) { totalNumberOfSections, dataSource in
      totalNumberOfSections + dataSource.numberOfSections() }
  }
  
  public override func numberOfObjectsInSection(_ section: Int) -> Int {
    let flatSection = flatSections()[section]
    
    return flatSection.dataSource.numberOfObjectsInSection(flatSection.relativeSectionIndex)
  }
  
  public override func objectAtIndexPath(_ indexPath: IndexPath) -> ObjectType? {
    let flatSection = flatSections()[indexPath.section]
    
    return flatSection.dataSource.objectAtIndexPath(IndexPath(row: indexPath.row, section: flatSection.relativeSectionIndex))
  }
  
  // MARK: - Helpers
  
  private func flatSections() -> [(relativeSectionIndex: Int, dataSource: ContainedDataSourceType)] {
    var result = [(relativeSectionIndex: Int, dataSource: ContainedDataSourceType)]()
    var sectionsPassed = 0
    for source in dataSources {
      for i in 0..<source.numberOfSections() {
        result.append((relativeSectionIndex: i, dataSource: source))
      }
      sectionsPassed += source.numberOfSections()
    }
    
    return result
  }
  
  private func subscribeForUpdates(inSources sources: [ContainedDataSourceType]) {
    sources.forEach { source in
      source.beginUpdatesSignal.subscribeNext { [weak self] in
        self?.beginUpdatesSignal.sendNext()
      }.putInto(pool)
      
      source.endUpdatesSignal.subscribeNext { [weak self] in
        self?.endUpdatesSignal.sendNext()
      }.putInto(pool)
      
      source.didChangeObjectSignal.subscribeNext { [weak self] object, changeType, fromIndexPath, toIndexPath in
        self?.didChangeObjectSignal.sendNext(
          (object: object,
           changeType: changeType,
           fromIndexPath: self?.absoluteIndexPath(fromRelative: fromIndexPath, in: source),
           toIndexPath: self?.absoluteIndexPath(fromRelative: toIndexPath, in: source)
          )
        )
      }.putInto(pool)

      source.didChangeSectionSignal.subscribeNext { [weak self] changeType, fromIndex, toIndex in
        guard let _self = self else { return }
        
        let precedingDataSources = _self.dataSources.prefix(upTo: _self.dataSources.index(of: source)!)
        let precedingSectionsCount = precedingDataSources.reduce(0) { totalSectionsCount, dataSource in
          return totalSectionsCount + (dataSource != source ? dataSource.numberOfSections() : 0)
        }
        
        _self.didChangeSectionSignal.sendNext(
          (changeType: changeType,
           fromIndex: fromIndex != nil ? precedingSectionsCount + fromIndex! : nil,
           toIndex: toIndex != nil ? precedingSectionsCount + toIndex! : nil
          )
        )
      }.putInto(pool)
      
      source.reloadDataSignal.subscribeNext { [weak self] in
        self?.reloadDataSignal.sendNext()
      }.putInto(pool)
    }
  }
  
  private func absoluteIndexPath(fromRelative relativeIndexPath: IndexPath?, in source: ContainedDataSourceType) -> IndexPath? {
    guard let relativeIndexPath = relativeIndexPath else { return nil }
    
    let precedingDataSources = dataSources.prefix(upTo: dataSources.index(of: source)!)
    let precedingSectionsCount = precedingDataSources.reduce(0) { totalSectionsCount, dataSource in
      return totalSectionsCount + (dataSource != source ? dataSource.numberOfSections() : 0)
    }
    
    return IndexPath(row: relativeIndexPath.row, section: precedingSectionsCount + relativeIndexPath.section)
  }

}

//
//  CompoundDataAdapter.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 11.12.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

public class CompoundDataAdapter<ObjectType> : ObjectsDataSource<ObjectType> where ObjectType: Equatable, ObjectType: Hashable {
  
  typealias ContainedDataSourceType = ObjectsDataSource<ObjectType>
  
  private let dataSources: [ContainedDataSourceType]
  
  init(dataSources: [ContainedDataSourceType]) {
    self.dataSources = dataSources
  }
  
  // Number of sections
  
//  private var cachedNumberOfSections = 0
  
  override func numberOfSections() -> Int {
    return dataSources.reduce(0) { $0 + $1.numberOfSections() }
  }
  
  public override func numberOfObjectsInSection(_ section: Int) -> Int {
    var sectionsSkipped = 0
    var dataSource: ContainedDataSourceType!
    var relativeSectionNumber = 0
    for source in dataSources {
      relativeSectionNumber = section - sectionsSkipped
      sectionsSkipped += source.numberOfSections()
      if sectionsSkipped > section {
        dataSource = source
        
        break
      }
    }
    
    return dataSource.numberOfObjectsInSection(relativeSectionNumber)
  }
  
  public override func objectAtIndexPath(_ indexPath: IndexPath) -> ObjectType? {
    let section = indexPath.section
    let row = indexPath.row
    
    var sectionsSkipped = 0
    var dataSource: ContainedDataSourceType!
    var relativeSectionNumber = 0
    for source in dataSources {
      relativeSectionNumber = section - sectionsSkipped
      sectionsSkipped += source.numberOfSections()
      if sectionsSkipped > section {
        dataSource = source
        
        break
      }
    }
    
    return dataSource.objectAtIndexPath(IndexPath(row: row, section: relativeSectionNumber))
  }
  
  
  //Helpers to be optimized
  
  private func dataSource(forSection section: Int) -> ObjectsDataSource<ObjectType>! {
    var sectionsSkipped = 0
    for source in dataSources {
      sectionsSkipped += source.numberOfSections()
      if sectionsSkipped > section {
        return source
      }
    }
    
    fatalError()
  }
  
}

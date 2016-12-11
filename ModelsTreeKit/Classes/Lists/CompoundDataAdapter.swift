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
  
  private let dataSources: [ContainedDataSourceType]
  
  public init(dataSources: [ContainedDataSourceType]) {
    self.dataSources = dataSources
  }
  
  // MARK: - Access to objects and sections
  
  public override func numberOfSections() -> Int {
    return dataSources.reduce(0) { $0 + $1.numberOfSections() }
  }
  
  public override func numberOfObjectsInSection(_ section: Int) -> Int {
    let flatSection = flatSections()[section]!
    return flatSection.dataSource.numberOfObjectsInSection(flatSection.relativeSectionIndex)
  }
  
  public override func objectAtIndexPath(_ indexPath: IndexPath) -> ObjectType? {
    let flatSection = flatSections()[indexPath.section]!
    return flatSection.dataSource.objectAtIndexPath(IndexPath(row: indexPath.row, section: flatSection.relativeSectionIndex))
  }
  
  // MARK: - Helpers
  
  private func flatSections() -> [Int: (relativeSectionIndex: Int, dataSource: ContainedDataSourceType)] {
    var result = [Int: (relativeSectionIndex: Int, dataSource: ContainedDataSourceType)]()
    var sectionsPassed = 0
    for source in dataSources {
      for i in 0..<source.numberOfSections() {
        result[i + sectionsPassed] = (relativeSectionIndex: i, dataSource: source)
      }
      sectionsPassed += source.numberOfSections()
    }
    return result
  }

}

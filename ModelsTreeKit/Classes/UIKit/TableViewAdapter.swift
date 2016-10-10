//
//  TableViewAdapter.swift
//  SessionSwift
//
//  Created by aleksey on 18.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import UIKit

public class TableViewAdapter<ObjectType>: NSObject, UITableViewDataSource, UITableViewDelegate {
  
  typealias DataSourceType = ObjectsDataSource<ObjectType>
  
  public var nibNameForObjectMatching: (ObjectType -> String)!
  public var footerClassForSectionIndexMatching: (Int -> UITableViewHeaderFooterView.Type?) = { _ in nil }
  public var headerClassForSectionIndexMatching: (Int -> UITableViewHeaderFooterView.Type?) = { _ in nil }
  public var userInfoForCellHeightMatching: (NSIndexPath -> [String: AnyObject]?) = { _ in return nil }
  public var userInfoForSectionHeaderHeightMatching: (Int -> [String: AnyObject]?) = { _ in return nil }
  public var userInfoForSectionFooterHeightMatching: (Int -> [String: AnyObject]?) = { _ in return nil }
  
  public let didSelectCell = Pipe<(UITableViewCell, NSIndexPath, ObjectType)>()
  public let willDisplayCell = Pipe<(UITableViewCell, NSIndexPath)>()
  public let didEndDisplayingCell = Pipe<(UITableViewCell, NSIndexPath)>()
  public let willSetObject = Pipe<(UITableViewCell, NSIndexPath)>()
  public let didSetObject = Pipe<(UITableViewCell, NSIndexPath)>()
  
  public var checkedIndexPaths = [NSIndexPath]() {
    didSet {
      tableView.indexPathsForVisibleRows?.forEach {
        if var checkable = tableView.cellForRowAtIndexPath($0) as? Checkable {
          checkable.checked = checkedIndexPaths.contains($0)
        }
      }
    }
  }
  
  private weak var tableView: UITableView!
  private var nibs = [String: UINib]()
  private var dataSource: ObjectsDataSource<ObjectType>!
  private var cellInstances = [String: UITableViewCell]()
  private var headerFooterInstances = [String: UITableViewHeaderFooterView]()
  private var identifiersForIndexPaths = [NSIndexPath: String]()
  private var mappings: [String: (ObjectType, UITableViewCell, NSIndexPath) -> Void] = [:]
  
  public init(dataSource: ObjectsDataSource<ObjectType>, tableView: UITableView) {
    super.init()
    
    self.tableView = tableView
    tableView.dataSource = self
    tableView.delegate = self
    
    self.dataSource = dataSource
    
    dataSource.beginUpdatesSignal.subscribeNext { [weak self] in
      self?.tableView.beginUpdates()
    }.putInto(pool)
    
    dataSource.endUpdatesSignal.subscribeNext { [weak self] in
      self?.tableView.endUpdates()
    }.putInto(pool)
    
    dataSource.reloadDataSignal.subscribeNext { [weak self] in
      guard let strongSelf = self else { return }
      UIView.animateWithDuration(0.1, animations: {
        strongSelf.tableView.alpha = 0},
        completion: { completed in
          strongSelf.tableView.reloadData()
          UIView.animateWithDuration(0.2, animations: {
            strongSelf.tableView.alpha = 1
        })
      })
    }.putInto(pool)
    
    dataSource.didChangeObjectSignal.subscribeNext { [weak self] object, changeType, fromIndexPath, toIndexPath in
      guard let strongSelf = self else { return }
      switch changeType {
      case .Insertion:
        if let toIndexPath = toIndexPath {
          strongSelf.tableView.insertRowsAtIndexPaths([toIndexPath],
            withRowAnimation: UITableViewRowAnimation.Fade)
        }
      case .Deletion:
        if let fromIndexPath = fromIndexPath {
          strongSelf.tableView.deleteRowsAtIndexPaths([fromIndexPath],
            withRowAnimation: .Fade)
        }
      case .Update:
        if let indexPath = toIndexPath {
          strongSelf.tableView.reloadRowsAtIndexPaths([indexPath],
            withRowAnimation: .Fade)
        }
      case .Move:
        if let fromIndexPath = fromIndexPath, let toIndexPath = toIndexPath {
          strongSelf.tableView.moveRowAtIndexPath(fromIndexPath,
            toIndexPath: toIndexPath)
        }
      }
    }.putInto(pool)
    
    dataSource.didChangeSectionSignal.subscribeNext { [weak self] changeType, fromIndex, toIndex in
      guard let strongSelf = self else { return }
      switch changeType {
      case .Insertion:
        if let toIndex = toIndex {
          strongSelf.tableView.insertSections(NSIndexSet(index: toIndex),
            withRowAnimation: .Fade)
        }
      case .Deletion:
        if let fromIndex = fromIndex {
          strongSelf.tableView.deleteSections(NSIndexSet(index: fromIndex),
            withRowAnimation: .Fade)
        }
      default:
        break
      }
    }.putInto(pool)
  }
  
  public func registerSectionHeaderFooterClass(headerFooterClass: UITableViewHeaderFooterView.Type) {
    let identifier = String(headerFooterClass)
    headerFooterInstances[identifier] = headerFooterClass.init(reuseIdentifier: String(headerFooterClass))
    tableView.registerClass(headerFooterClass, forHeaderFooterViewReuseIdentifier: identifier)
  }
  
  public func registerCellClass<U: ObjectConsuming where U.ObjectType == ObjectType>(cellClass: U.Type) {
    let identifier = String(cellClass)
    let nib = UINib(nibName: identifier, bundle: nil)
    tableView.registerNib(nib, forCellReuseIdentifier: identifier)
    cellInstances[identifier] = nib.instantiateWithOwner(self, options: nil).last as? UITableViewCell
    
    mappings[identifier] = { object, cell, _ in
      if let consumer = cell as? U { consumer.applyObject(object) }
    }
  }
  
  //UITableViewDataSource
  
  @objc
  public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataSource.numberOfObjectsInSection(section)
  }
  
  @objc
  public func tableView(tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let object = dataSource.objectAtIndexPath(indexPath)!;
      let identifier = nibNameForObjectMatching(object)
      var cell = tableView.dequeueReusableCellWithIdentifier(identifier)
      identifiersForIndexPaths[indexPath] = identifier
      
      if cell == nil {
        cell = (nibs[identifier]!.instantiateWithOwner(nil, options: nil).last as! UITableViewCell)
      }
      
      willSetObject.sendNext((cell!, indexPath))
      
      let mapping = mappings[identifier]!
      mapping(object, cell!, indexPath)
      
      didSetObject.sendNext((cell!, indexPath))
      
      return cell!
  }
  
  @objc
  public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return dataSource.numberOfSections()
  }
  
  // UITableViewDelegate
  
  @objc
  public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    let identifier = nibNameForObjectMatching(dataSource.objectAtIndexPath(indexPath)!)
    if let cell = cellInstances[identifier] as? HeightCalculatingCell {
      return cell.heightForObject(dataSource.objectAtIndexPath(indexPath), width: tableView.frame.size.width, userInfo: userInfoForCellHeightMatching(indexPath))
    }
    return UITableViewAutomaticDimension;
  }
  
  
  public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if let headerClass = headerClassForSectionIndexMatching(section) {
      return tableView.dequeueReusableHeaderFooterViewWithIdentifier(String(headerClass))
    }
    
    return nil
  }
  
  @objc
  public func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    if let footerClass = footerClassForSectionIndexMatching(section) {
      return tableView.dequeueReusableHeaderFooterViewWithIdentifier(String(footerClass))
    }
    
    return nil
  }
  
  public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if let headerClass = headerClassForSectionIndexMatching(section),
      let view = headerFooterInstances[String(headerClass)] as? HeightCalculatingCell {
      return view.heightForObject(nil, width: tableView.frame.size.width, userInfo: userInfoForSectionHeaderHeightMatching(section))
    }
    
    return UITableViewAutomaticDimension
  }
  
  public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if let footerClass = footerClassForSectionIndexMatching(section),
      let view = headerFooterInstances[String(footerClass)] as? HeightCalculatingCell {
      return view.heightForObject(nil, width: tableView.frame.size.width, userInfo: userInfoForSectionFooterHeightMatching(section))
    }
    
    return UITableViewAutomaticDimension
  }
  
  @objc
  public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    didSelectCell.sendNext((
      tableView.cellForRowAtIndexPath(indexPath)!,
      indexPath,
      dataSource.objectAtIndexPath(indexPath)!)
    )
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  @objc
  public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
  
    if var checkable = cell as? Checkable {
      checkable.checked = checkedIndexPaths.contains(indexPath)
    }
  
    willDisplayCell.sendNext((cell, indexPath))
  }
  
  public func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    didEndDisplayingCell.sendNext((cell, indexPath))
  }
  
}

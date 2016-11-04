//
//  TableViewBehavior.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 04.11.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import Foundation

public protocol TableViewBehavior: UITableViewDelegate {
  
  weak var tableView: UITableView! { get set }
  
  func userInfo(forCellAtIndexPath indexPath: NSIndexPath) -> [String: AnyObject]
  
}

extension TableViewBehavior {
  
  func heightCalculationUserInfo(forCellAtIndexPath indexPath: NSIndexPath) -> [String: AnyObject] {
    return [:]
  }
  
}

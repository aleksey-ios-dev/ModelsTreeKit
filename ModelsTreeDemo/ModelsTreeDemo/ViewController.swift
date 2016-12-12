//
//  ViewController.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 20.08.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var searchBar: UISearchBar!
  
  private var adapter: TableViewAdapter<Int>!
  private var dataAdapter: ObjectsDataSource<Int>!
  let list1 = UnorderedList<Int>(parent: nil, objects: [1, 2])
  let list2 = UnorderedList<Int>(parent: nil, objects: [-9, 10])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let listAdapter1 = UnorderedListDataAdapter<Int, String>(list: list1)
    listAdapter1.groupContentsSortingCriteria = { $0 < $1 }
    listAdapter1.groupingCriteria = { return $0 > 3 ? "2" : "1" }
    
    let listAdapter2 = UnorderedListDataAdapter<Int, String>(list: list2)
    listAdapter2.groupContentsSortingCriteria = { $0 > $1 }
    listAdapter2.groupingCriteria = { return $0 > 0 ? "2" : "1" }

    dataAdapter = CompoundDataAdapter(dataSources: [listAdapter1, listAdapter2])
    adapter = TableViewAdapter(dataSource: dataAdapter, tableView: tableView)
    
    adapter.registerCellClass(TestCell.self)
    adapter.nibNameForObjectMatching = { _ in String(describing: TestCell.self) }
  }
  
  @IBAction private func addMore(sender: AnyObject?) {
    list1.performUpdates { $0.insert([6]) }
    list2.performUpdates { $0.insert([-151, 12]) }
  }
  
}

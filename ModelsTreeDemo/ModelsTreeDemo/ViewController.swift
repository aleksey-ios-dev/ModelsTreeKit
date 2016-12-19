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
  let list1 = UnorderedList<String>(parent: nil, objects: ["7", "4", "1"])
  let list2 = UnorderedList<Int>(parent: nil, objects: [-7, 0, 3, 15])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
   let listAdapter1 = UnorderedListDataAdapter<String>(list: list1)
    listAdapter1.groupContentsSortingCriteria = { $0 > $1 }
    listAdapter1.groupingCriteria = { return NumberFormatter().number(from: $0)!.intValue > 3 ? "2" : "1" }
    list1.replaceWith(["1", "2", "4", "7", "9"])
    
    let mappedAdapter: MapDataAdapter<String, Int> = MapDataAdapter(mappedDataSource: listAdapter1,
                                                                    mapper: { NumberFormatter().number(from: $0)!.intValue })
    
    /*
    let listAdapter2 = UnorderedListDataAdapter<Int>(list: list2)
    listAdapter2.groupingCriteria = { return $0 > 4 ? "2" : "1" }
    listAdapter2.groupContentsSortingCriteria = { $0 > $1 }
    list2.replaceWith([1, 2, 3, 7, 10])
     */
    

    //dataAdapter = CompoundDataAdapter(dataSources: [mappedAdapter, listAdapter2])
    
    adapter = TableViewAdapter(dataSource: mappedAdapter, tableView: tableView)
    
    adapter.registerCellClass(TestCell.self)
    adapter.nibNameForObjectMatching = { _ in String(describing: TestCell.self) }
  }
  
  @IBAction private func addMore(sender: AnyObject?) {
    list1.performUpdates { $0.insert(["0", "8"]); $0.delete(["1", "9", "4"]) }
    //list2.performUpdates { $0.insert([-151, 12]) }
  }
  
}

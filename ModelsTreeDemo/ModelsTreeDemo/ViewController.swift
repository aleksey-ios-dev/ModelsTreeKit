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
  
  private var adapter: TableViewAdapter<String>!
  let namesList = UnorderedList(parent: nil, objects: ["Aleksey", "Vitaly"])
  let integerList = UnorderedList(parent: nil, objects: [1, 2, 3, 4, 5])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let namesListAdapter = UnorderedListDataAdapter(list: namesList)
    namesListAdapter.groupContentsSortingCriteria = { $0 > $1 }
    
    let integerListAdapter = UnorderedListDataAdapter(list: integerList)
    integerListAdapter.groupingCriteria = { $0 > 3 ? "2" : "1" }
    
    let mappedAdapter: MapDataAdapter<Int, String> = MapDataAdapter(mappedDataSource: integerListAdapter,
                                                                    mapper: { String(describing: $0)})
    
    let compoundAdapter = CompoundDataAdapter(dataSources: [namesListAdapter, mappedAdapter])
    
    adapter = TableViewAdapter(dataSource: compoundAdapter, tableView: tableView)
    
    adapter.registerCellClass(TestCell.self)
    adapter.nibNameForObjectMatching = { _ in String(describing: TestCell.self) }
  }
  
  @IBAction private func addMore(sender: AnyObject?) {
    namesList.performUpdates { $0.insert(["Eugene"]) }
    integerList.performUpdates { $0.insert([7, 8]); $0.delete([1, 4]) }
  }
  
}

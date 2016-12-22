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
  
  private var adapter: TableViewAdapter<Wrapper>!
  let namesList = UnorderedList(parent: nil, objects: ["Aleksey", "Vitaly"])
  let integerList = UnorderedList(parent: nil, objects: [1, 2, 3, 4, 5])
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let namesListAdapter = UnorderedListDataAdapter(list: namesList)
    namesListAdapter.groupContentsSortingCriteria = { $0 > $1 }
    namesListAdapter.groupContentsSortingCriteria = { $0 < $1 }
    namesListAdapter.groupingCriteria = { String(describing: $0.characters.first) }
    
    let integerListAdapter = UnorderedListDataAdapter(list: integerList)
    integerListAdapter.groupingCriteria = { $0 > 3 ? "2" : "1" }
    integerListAdapter.groupsSortingCriteria = { $0 < $1 }
    integerListAdapter.groupContentsSortingCriteria = { $0 > $1 }
    
    let staticSource = StaticDataSource<String>()
    let section = StaticObjectsSection(title: "SomeTitle", objects: ["Option 1", "Option 2"])
    staticSource.sections = [section]
    
    let compoundAdapter = CompoundDataAdapter<Wrapper>(from:
      [namesListAdapter.map { $0.wrapped() },
       integerListAdapter.map { $0.wrapped() },
       staticSource.map { $0.wrapped() }]
    )
    
    adapter = TableViewAdapter(dataSource: compoundAdapter, tableView: tableView)
    adapter.registerCellClass(TestCell.self)
    adapter.nibNameForObjectMatching = { _ in String(describing: TestCell.self) }
    adapter.didSelectCell.subscribeNext { _, _, object in print(object) }.ownedBy(self)
  }
  
  @IBAction private func addMore(sender: AnyObject?) {
    namesList.performUpdates { $0.insert(["Andrew", "Vladimir"]); $0.delete(["Aleksey"]) }
    integerList.performUpdates { $0.insert([7, 8]); $0.delete([1, 2, 3, 4]) }
  }
  
}

//
//  AppDelegate.swift
//  ModelsTreeDemo
//
//  Created by Aleksey on 20.08.16.
//  Copyright © 2016 Aleksey Chernish. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let list = OrderedList<Int>(parent: nil)
    
    let dataAdapter = OrderedListDataAdapter(list: list)
    
    dataAdapter.groupingCriteria = { $0 > 3 ? "2 BIG" : "1 SMALL" }
    
    dataAdapter.endUpdatesSignal.subscribeNext {
      print(dataAdapter.sections)
    }
    
    list.performUpdates {
      $0.append([1, 2, 3])
    }
    
    list.performUpdates {
      $0.append([4, 5])
    }
    
    list.performUpdates {
      $0.delete([1, 2, 3])
    }
    
    return true
  }
  
}

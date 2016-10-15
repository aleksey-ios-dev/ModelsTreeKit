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
    
    list.didChangeContentSignal.subscribeNext { appendedObjects, deletions, updates in
      print("appended \(appendedObjects)")
      print("deleted \(deletions)")
      print("updated: \(updates)")
      print("___________________")
      print("")
    }.ownedBy(self)
    
    list.performUpdates {
      $0.append([1, 2, 3])
    }
    
    list.performUpdates {
      $0.update([1, 3, 4])
      $0.delete([1])
      $0.append([5, 5, 5])
    }
    
    return true
  }
  
}

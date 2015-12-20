//
//  UIViewController+Pool.swift
//  We Learn English
//
//  Created by aleksey on 13.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import UIKit

public extension UIViewController {
    private struct AssociatedKeys {
        static var AutodisposePoolKey = "AutodisposePoolKey"
    }
    
    public var pool: AutodisposePool {
        get {
            var pool = objc_getAssociatedObject(self, &AssociatedKeys.AutodisposePoolKey) as? AutodisposePool
            
            if (pool == nil) {
                pool = AutodisposePool()
                objc_setAssociatedObject(self, &AssociatedKeys.AutodisposePoolKey, pool, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            }
            
            return pool!
        }
    }
}
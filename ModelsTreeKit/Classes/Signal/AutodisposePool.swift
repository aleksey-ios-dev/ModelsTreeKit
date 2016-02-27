//
//  DisposablesPool.swift
//  SessionSwift
//
//  Created by aleksey on 25.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class AutodisposePool: NSObject { //TODO: избавься от NSObject
    private var disposables = [WeakRef]()
    
    public func add(disposable: Disposable) {
        disposables.append(WeakRef(object: disposable))
    }

    public func drain() {
        for weakRef in disposables {
            if let disposable = weakRef.object as? Disposable {
                disposable.dispose()
            }
        }
        
        disposables.removeAll()
    }
    
    deinit {
        drain()
    }
}

private class WeakRef {
    weak var object: AnyObject?
    
    init(object: AnyObject?) {
        self.object = object
    }
}
//
//  SignalObjcWrapper.swift
//  We Learn English
//
//  Created by aleksey on 13.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

class DeinitNotifier: NSObject {
    var signal = Signal<Bool>()
    
    deinit {
        signal.sendNext(true)
    }
}
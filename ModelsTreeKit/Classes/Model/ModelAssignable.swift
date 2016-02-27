//
//  ModelAssignabl.swift
//  SessionSwift
//
//  Created by aleksey on 26.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public protocol ModelAssignable: class {
    func assignModel(model: Model) -> Void
}

public protocol DeinitObservable: class {
    var deinitSignal: Signal<Void> { get }
}


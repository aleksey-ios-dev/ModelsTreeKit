//
//  SessionCompletionParams.swift
//  SessionSwift
//
//  Created by aleksey on 26.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public struct SessionCompletionParams<T: Hashable> {
    private var parameters = [T: AnyObject]()
    
    public init() {
    }
    
    public subscript(n: T) -> AnyObject? {
        get {
            return parameters[n]
        }
        set {
            parameters[n] = newValue
        }
    }
}

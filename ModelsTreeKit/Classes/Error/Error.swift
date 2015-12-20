//
//  Error.swift
//  SessionSwift
//
//  Created by aleksey on 14.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public protocol ErrorCodesList {
    static func allCodes() -> [ErrorCode]
}

public protocol ErrorCode {
    func codeValue() -> Int
}

public protocol ErrorDomain {
    var domainTitle: String { get }
}

public struct Error: ErrorType, Hashable, Equatable  {
    let domain: ErrorDomain
    let code: ErrorCode
    
    public init(domain: ErrorDomain, code: ErrorCode) {
        self.domain = domain
        self.code = code
    }
    
    public func localizedDescription() -> String {
        return NSLocalizedString(descriptionString(), comment: "")
    }
    
    public func fullDescription() -> String {
        return descriptionString() + ": " + localizedDescription()
    }
    
    private func descriptionString() -> String {
        return "\(domain.domainTitle).\(code.codeValue())"
    }
    
    public var hashValue: Int {
        return (code.codeValue().hashValue + domain.domainTitle.hashValue).hashValue
    }
}

public func ==(a: Error, b: Error) -> Bool {
    return a.code.codeValue() == b.code.codeValue() && a.domain.domainTitle == b.domain.domainTitle
}
//
//  ErrorCodes.swift
//  SessionSwift
//
//  Created by aleksey on 15.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

//TODO: убери из кита
//TODO: убери TSTTransitionController из кита

public struct NetworkErrorDomain: ErrorDomain {
    public let domainTitle = "NetworkErrorDomain"
    
    public init() {
    }
    
    public enum Errors: Int, ErrorCodesList, ErrorCode {
        case DownloadError = 100
        case BadToken = 101
        
        public static func allCodes() -> [ErrorCode] {
            return [Errors.DownloadError, Errors.BadToken]
        }
        
        public func codeValue() -> Int {
            return rawValue
        }
    }
}

public struct ParseErrorDomain: ErrorDomain {
    public let domainTitle = "RegistrationErrorDomain"
    
    public init() {
    }

    public enum Errors: Int, ErrorCodesList, ErrorCode {
        case UserExists = 202
        case WrongPassword = 101

        public static func allCodes() -> [ErrorCode] {
            return [Errors.UserExists, Errors.WrongPassword]
        }

        public func codeValue() -> Int {
            return rawValue
        }
    }
}


public struct ApplicationErrorDomain: ErrorDomain {
    public let domainTitle = "ApplicationErrorDomain"
    
    public init() {
    }

    public enum Errors: Int, ErrorCodesList, ErrorCode {
        case UnknownError = 100
        case ScannerError = 101
        case DownloadError = 102

        public static func allCodes() -> [ErrorCode] {
            return [Errors.UnknownError, Errors.ScannerError, Errors.DownloadError]
        }
        
        public func codeValue() -> Int {
            return rawValue
        }
    }
}

//TODO: увести из кита!

public extension Error {
    public static func mappedErrorFromNSError(error: NSError?) -> Error? {
        guard let error = error else {
            return nil
        }

        switch error.domain {
            case "Parse":
                if let code = ParseErrorDomain.Errors(rawValue: error.code) {
                    return Error(domain: ParseErrorDomain(), code: code)
                }
            default:
                break
        }


        return Error(domain: ApplicationErrorDomain(), code: ApplicationErrorDomain.Errors.UnknownError)
    }
}
//
//  SessionCredentials.swift
//  SessionSwift
//
//  Created by aleksey on 12.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public struct SessionCredentials: Archivable {
//    private enum Keys: String {
//        case Token = "token"
//        case FirstName = "firstName"
//        case LastName = "lastName"
//        case Uid = "uid"
//    }
  
  private var fields = [String: AnyObject]()
  
//    public var token: String?
//    var firstName: String?
//    var lastName: String?
//    public var uid: String?
  
//    public init(params: SessionCompletionParams<LoginSessionCompletion>) {
//      fields[.Token] = params[.Token]
//        token = params[.Token] as? String
//        uid = params[.Uid] as? String
//        firstName = params[.FirstName] as? String
//        lastName = params[.LastName] as? String
//    }
  
    //Archivable
    
    public init(archivationProxy: [String : AnyObject]) {
      fields = archivationProxy
//        token = archivationProxy[Keys.Token.rawValue] as? String
//        firstName = archivationProxy[Keys.FirstName.rawValue] as? String
//        lastName = archivationProxy[Keys.LastName.rawValue] as? String
//        uid = archivationProxy[Keys.Uid.rawValue] as? String
    }
    
    public func archivationProxy() -> [String : AnyObject] {
      return fie
        var proxy = [String: AnyObject]()
        proxy[Keys.Token.rawValue] = token
        proxy[Keys.FirstName.rawValue] = firstName
        proxy[Keys.LastName.rawValue] = lastName
        proxy[Keys.Uid.rawValue] = uid
        
        return proxy
    }
}
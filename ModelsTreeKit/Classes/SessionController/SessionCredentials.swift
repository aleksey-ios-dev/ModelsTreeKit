//
//  SessionCredentials.swift
//  SessionSwift
//
//  Created by aleksey on 12.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

struct SessionCredentials: Archivable {
    private enum Keys: String {
        case Token = "token"
        case FirstName = "firstName"
        case LastName = "lastName"
        case Uid = "uid"
    }
    
    var token: String?
    var firstName: String?
    var lastName: String?
    var uid: String?
    
    init(params: SessionCompletionParams<LoginSessionCompletion>) {
        token = params[.Token] as? String
        uid = params[.Uid] as? String
        firstName = params[.FirstName] as? String
        lastName = params[.LastName] as? String
    }
    
    //Archivable
    
    init(archivationProxy: [String : AnyObject]) {
        token = archivationProxy[Keys.Token.rawValue] as? String
        firstName = archivationProxy[Keys.FirstName.rawValue] as? String
        lastName = archivationProxy[Keys.LastName.rawValue] as? String
        uid = archivationProxy[Keys.Uid.rawValue] as? String
    }
    
    func archivationProxy() -> [String : AnyObject] {
        var proxy = [String: AnyObject]()
        proxy[Keys.Token.rawValue] = token
        proxy[Keys.FirstName.rawValue] = firstName
        proxy[Keys.LastName.rawValue] = lastName
        proxy[Keys.Uid.rawValue] = uid
        
        return proxy
    }
}
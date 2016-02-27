//
//  UserSession.swift
//  SessionSwift
//
//  Created by aleksey on 12.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class UserSession: Session {
    public init(params: SessionCompletionParams) {
        super.init()
        
        credentials = SessionCredentials()
    }
    
    public required init(archivationProxy: ArchivationProxy) {
        super.init()
        if let credentialsProxy = archivationProxy["credentials"] as? ArchivationProxy {
            credentials = SessionCredentials(archivationProxy: credentialsProxy)
        }
    }
}

extension UserSession: Archivable {
    public func archivationProxy() -> ArchivationProxy {
        var proxy = ArchivationProxy()
        proxy["credentials"] = credentials?.archivationProxy()
        
        return proxy
    }
}
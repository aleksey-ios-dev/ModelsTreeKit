//
//  ServiceLocator.swift
//  SessionSwift
//
//  Created by aleksey on 10.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class ServiceLocator {
    private var services = [String: Any]()
    
    public init() {
    }
    
    public func registerService(service: Any, forKey key: String) {
        services[key] = service
    }
    
    public func serviceForKey(key: String) -> Any? {
        return services[key]
    }
    
    public func takeOff() {
        for service in services.values {
            if let service = service as? Service {
                service.takeOff()
            }
        }
    }
    
    func prepareToClose() {
        for service in services.values {
            if let service = service as? Service {
                service.prepareToClose()
            }
        }
    }
}
//
//  ServiceLocator.swift
//  SessionSwift
//
//  Created by aleksey on 10.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public enum ServiceKey {
    case Defaults
    case DataStorage
    case UserStore
    case DataLoader
    case ScanResultsProcessor
    case Initialization
}

public class ServiceLocator {
    private var services = [ServiceKey: Any]()
    
    public init() {
    }
    
    public func registerService(service: Any, forKey key: ServiceKey) {
        services[key] = service
    }
    
    public func serviceForKey(key: ServiceKey) -> Any? {
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
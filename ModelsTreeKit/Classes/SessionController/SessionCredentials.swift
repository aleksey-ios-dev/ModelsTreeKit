//
//  SessionCredentials.swift
//  SessionSwift
//
//  Created by aleksey on 12.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public final class SessionCredentials {
  
  private var fields = [String: AnyObject]()
  
  public init() {}
  
  public init(archivationProxy: ArchivationProxy) {
    fields = archivationProxy
  }
  
  public init(params: SessionCompletionParams) {
    fields = params
  }
  
  public subscript(n: String) -> AnyObject? {
    get { return fields[n] }
    set { fields[n] = newValue }
  }
  
}

extension SessionCredentials: Archivable {

  public func archivationProxy() -> ArchivationProxy {
    return fields
  }
  
}

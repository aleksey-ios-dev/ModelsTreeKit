//
//  Session.swift
//  SessionSwift
//
//  Created by aleksey on 10.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public typealias SessionCompletionParams = [String: AnyObject]

protocol SessionDelegate: class {
  func sessionDidPrepareToShowRootRepresenation(session: Session) -> Void
  func session(session: Session, didCloseWithParams params: Any?) -> Void
  func sessionDidOpen(session: Session) -> Void
}

public struct SessionEvent {
  var name: String
  
  public init(name: String) {
    self.name = name
  }
}

extension SessionEvent: Equatable {
}

public func ==(lhs: SessionEvent, rhs: SessionEvent) -> Bool {
  return lhs.name == rhs.name
}


public class Session: Model {
  
  public var services: ServiceLocator!
  public var credentials: SessionCredentials?
  
  private weak var controller: SessionDelegate?
  
  public init() {
    super.init(parent: nil)
  }
  
  func openWithController(controller: SessionController) {
    self.controller = controller
    self.services.takeOff()
    self.controller?.sessionDidOpen(self)
    self.controller?.sessionDidPrepareToShowRootRepresenation(self)
  }
  
  public func closeWithParams(params: Any?) {
    services.prepareToClose()
    controller?.session(self, didCloseWithParams: params)
  }
}


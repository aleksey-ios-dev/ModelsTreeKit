//
//  Routers.swift
//  SessionSwift
//
//  Created by aleksey on 24.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public protocol RootRepresentationsRouter {
    func representationFor(session session: Session) -> AnyObject;
}

public protocol RootModelsRouter {
    func modelFor(session session: Session) -> Model;
}

public protocol RootNavigationManager {
    func showRootRepresentation(representation: AnyObject) -> Void
}

public protocol SessionsGenerator {
    func newLoginSession() -> LoginSession
    func newUserSessionFrom(proxy: ArchivationProxy) -> UserSession
    func newUserSessionWithParams(params: SessionCompletionParams<LoginSessionCompletion>) -> UserSession
}

public  protocol ServicesConfigurator {
    func configure(session: Session) -> Void
}


//
//  SessionController.swift
//  SessionSwift
//
//  Created by aleksey on 09.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public class SessionController {
  private enum ArchiverErrors: ErrorType {
    case SessionArchivationFailed
    case NoSessionForKey
  }
  
  public static let controller = SessionController()
  
  //Decoration on start
  
  public var configuration: SessionControllerConfiguration!
  
  public var navigationManager: RootNavigationManager!
  public var representationsRouter: RootRepresentationsRouter!
  public var modelsRouter: RootModelsRouter!
  public var sessionsRouter: SessionsGenerator!
  public var servicesConfigurator: ServicesConfigurator!
  
  private let userDefaults = NSUserDefaults.standardUserDefaults()
  private var activeSession: Session?
  
  public func restoreLastOpenedOrStartLoginSession() {
    if let lastSession = lastOpenedUserSession {
      openSession(lastSession)
    } else {
      openSession(self.sessionsRouter.newLoginSession())
    }
  }
  
  private func openSession(session: Session) {
    activeSession = session
    servicesConfigurator.configure(session)
    session.openWithController(self)
    
    if let userSession = session as? UserSession {
      lastOpenedUserSession = userSession
    }
  }
  
  //Storage
  
  var lastOpenedUserSession: UserSession? {
    set {
      do {
        try archiveUserSession(newValue)
      }
      catch {
      }
      
      let hash: Int? = newValue?.credentials?[configuration.credentialsPrimaryKey]?.hash
      
      let uidString: String? = hash == nil ? nil : String(hash!)
      
      userDefaults.setValue(uidString, forKey: configuration.keychainAccessKey)
      userDefaults.synchronize()
    }
    
    get {
      guard let key = userDefaults.valueForKey(configuration.keychainAccessKey) as? String else {
        return nil
      }
      do {
        return try archivedUserSessionForKey(key)
      } catch {
        fatalError()
      }
      
      return nil
    }
  }
  
  private func archiveUserSession(session: UserSession?) throws {
    guard
      let session = session,
      let sessionKey = session.credentials?[configuration.credentialsPrimaryKey] as! String?
      else {
        throw ArchiverErrors.SessionArchivationFailed
    }
    
    let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session.archivationProxy())
    let keychain = KeychainItemWrapper.init(identifier: String(sessionKey.hash), accessGroup: nil)
    keychain.setObject(sessionData, forKey: kSecAttrService)
  }
  
  private func archivedUserSessionForKey(key: String?) throws -> UserSession {
    guard
      let key = key,
      let sessionData = KeychainItemWrapper(identifier: key , accessGroup: nil).objectForKey(kSecAttrService) as? NSData,
      let sessionProxy = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as? ArchivationProxy else {
        throw ArchiverErrors.NoSessionForKey
    }
    
    return sessionsRouter.newUserSessionFrom(sessionProxy)
  }
}

extension SessionController: SessionDelegate {
  func sessionDidOpen(session: Session) {
  }
  
  func session(session: Session, didCloseWithParams params: Any?) {
    guard let _ = session as? LoginSession, let loginParams = params as? SessionCompletionParams<LoginSessionCompletion> else {
      lastOpenedUserSession = nil
      openSession(sessionsRouter.newLoginSession())
      
      return
    }
    
    do {
      let uidString = loginParams[.Token]!
      let session = try archivedUserSessionForKey(String(uidString.hash))
      openSession(session)
    } catch {
      openSession(sessionsRouter.newUserSessionWithParams(loginParams))
    }
  }
  
  func sessionDidPrepareToShowRootRepresenation(session: Session) {
    let representation = representationsRouter.representationFor(session: session)
    let model = modelsRouter.modelFor(session: session)

    if let assignable = representation as? ModelAssignable {
      assignable.assignModel(model)
    }
    
    if let deinitObservable = representation as? DeinitObservable {
      model.applyRepresentation(deinitObservable)
    }
    
    navigationManager.showRootRepresentation(representation)
  }
}

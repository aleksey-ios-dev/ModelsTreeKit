//
//  TakeUntilTests.swift
//  ModelsTreeKit
//
//  Created by aleksey on 05.06.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation
import XCTest
@testable import ModelsTreeKit

class TakeUntilTests: XCTestCase {
  let signalA = Signal<Int>()
  weak var disposable: Disposable?
  
  var testSwitch: UISwitch!
  var testSwitch2: UISwitch!
  
  override func setUp() {
    testSwitch = UISwitch()
    testSwitch2 = UISwitch()
  }
  
  func testThatKillingObjectsKillsSubscription() {
    disposable = testSwitch.onSignal.bindTo(keyPath: "on", of: testSwitch2)
  }
  
  override func tearDown() {
    testSwitch = nil
    testSwitch2 = nil
    
    XCTAssert(disposable == nil)
  }
}

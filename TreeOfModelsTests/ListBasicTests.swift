//
//  ListTests.swift
//  ModelsTreeKit
//
//  Created by aleksey on 20.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import XCTest
@testable import ModelsTreeKit

class ListBasicTests: XCTestCase {
    func testInstantiationWithArray() {
        let list = List<Int>(parent: nil, array: [1, 2, 3])
        XCTAssertEqual(list.objects, [1, 2, 3])
    }
    
    func testInstantiationWithFetchBlock() {
        let list = List<Int>(parent: nil) {completion, _  in
            completion(success: true, response: [1,2, 3], error: nil)
            return nil
        }
        list.getNext()
        
        XCTAssertEqual(list.objects, [1, 2, 3])
    }
    
    func testInsertion() {
        let list = List<Int>(parent: nil, array: [1, 2, 3])
        list.performUpdates(
            list.insert([1, 2, 3, 4, 5])
      )
  
      
        
        XCTAssertEqual(list.objects, [1, 2, 3, 4, 5])
    }
    
    func testDeletion() {
        let list = List<Int>(parent: nil, array: [1, 2, 3])
        list.performUpdates(list.delete([1, 2, 4, 5]))
        
        XCTAssertEqual(list.objects, [3])
    }
    
    func testReplacement() {
        let list = List<Int>(parent: nil, array: [1, 2, 3])
        list.replaceWith([4, 5 ,6])
        
        XCTAssertEqual(list.objects, [4, 5 ,6])
    }
    
    func testResetting() {
        let list = List<Int>(parent: nil, array: [1, 2, 3])
        list.performUpdates(
            list.reset()
        )
        
        XCTAssertEqual(list.objects, [])
    }
}
//
//  UpdatesPoolTests.swift
//  ModelsTreeKit
//
//  Created by aleksey on 20.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import XCTest
@testable import ModelsTreeKit

class UpdatesPoolTests: XCTestCase {
    func testThatAddsObjectsForInsertion() {
        let pool = UpdatesPool<Int>()
        pool.addObjects([1, 2, 3], forChangeType: .Insertion)
        
        XCTAssertEqual(pool.insertions, [1, 2, 3])
    }
    
    func testThatAddsObjectsForDeletion() {
        let pool = UpdatesPool<Int>()
        pool.addObjects([1, 2, 3], forChangeType: .Deletion)
        
        XCTAssertEqual(pool.deletions, [1, 2, 3])
    }
    
    func testThatIgnoresMoveAndUpdateChangeTypes() {
        let pool = UpdatesPool<Int>()
        pool.addObjects([1, 2, 3], forChangeType: .Update)
        pool.addObjects([1, 2, 3], forChangeType: .Move)

        XCTAssertEqual(pool.deletions, [])
        XCTAssertEqual(pool.insertions, [])
        XCTAssertEqual(pool.updates, [])
    }
    
    func testThatReducesDuplicatingInsertionsAndDeletions() {
        let pool = UpdatesPool<Int>()
        pool.addObjects([1, 2, 3], forChangeType: .Insertion)
        pool.addObjects([2, 3], forChangeType: .Deletion)
        
        pool.optimizeDuplicatingEntries()
        
        XCTAssertEqual(pool.deletions, [])
        XCTAssertEqual(pool.insertions, [1])
    }
    
    func testThatConvertsOverridingInsertionsIntoUpdate() {
        let pool = UpdatesPool<Int>()
        pool.addObjects([1, 2, 3], forChangeType: .Insertion)
        
        pool.optimizeFor([3, 4, 5])
        
        XCTAssertEqual(pool.insertions, [1, 2])
        XCTAssertEqual(pool.updates, [3])
    }
}
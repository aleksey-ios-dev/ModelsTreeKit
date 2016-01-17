//
//  ListTests.swift
//  ModelsTreeKit
//
//  Created by aleksey on 21.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation


import Foundation
import XCTest
@testable import ModelsTreeKit

class ListTests: XCTestCase {
    func testThatListStartsUpdateThenUpdatesAndThenEndsUpdate() {
        let list = List<Int>(parent: nil, array: [])
        let dataSource = MockDataSource(list: list)

        list.performUpdates() {
            list.insert([1])
        }
        
        XCTAssertEqual(dataSource.performedActions, [.BeginUpdates, .ChangeContent, .EndUpdates])
    }
    
    func testThatListDoesntPushDeletionsOfNotContainedObjects() {
        let list = List<Int>(parent: nil, array: [1, 2, 3])
        let dataSource = MockDataSource(list: list)
        
        list.performUpdates() {
            list.delete([1, 4])
        }
        
        XCTAssertEqual(dataSource.lastDeletions, [1])
    }
    
    func testThatListPushesUpdatesWhenInsertsContainedObjects() {
        let list = List<Int>(parent: nil, array: [1, 2, 3])
        let dataSource = MockDataSource(list: list)
        
        list.performUpdates() {
            list.insert([1, 2, 5])
        }
        
        XCTAssertEqual(dataSource.lastUpdates, [1, 2])
        XCTAssertEqual(dataSource.lastInsertions, [5])
    }
    
    func testThatListPushesNewObjectsSetByReplaceSignal() {
        let list = List<Int>(parent: nil, array: [1, 2, 3])
        let dataSource = MockDataSource(list: list)
        
        list.replaceWith([3, 4, 5])
        
        XCTAssertEqual(dataSource.objectsPushedForReplacement, [3, 4, 5])
        XCTAssertEqual(list.objects, [3, 4, 5])
    }
}

class MockDataSource {
    enum ListActions {
        case BeginUpdates, ChangeContent, EndUpdates
    }
    
    var lastDeletions = Set<Int>()
    var lastUpdates = Set<Int>()
    var lastInsertions = Set<Int>()
    var objectsPushedForReplacement = Set<Int>()
    
    var performedActions = Array<ListActions>()
    
    private let pool = AutodisposePool()
    
    init(list: List<Int>?) {
        guard let list = list else {
            return
        }
        
        list.didReplaceContentSignal.subscribeNext() { [weak self] objects in
                self?.objectsPushedForReplacement = objects
        }.putInto(pool)
        
        list.beginUpdatesSignal.subscribeNext { [weak self] _ in
            self?.performedActions.append(.BeginUpdates)
        }.putInto(pool)
        
        list.endUpdatesSignal.subscribeNext { [weak self] _ in
            self?.performedActions.append(.EndUpdates)
        }.putInto(pool)
        
        list.didChangeContentSignal.subscribeNext { [weak self] insertions, deletions, updates in
            self?.performedActions.append(.ChangeContent)
            self?.lastDeletions = deletions
            self?.lastInsertions = insertions
            self?.lastUpdates = updates
        }.putInto(pool)
    }
}
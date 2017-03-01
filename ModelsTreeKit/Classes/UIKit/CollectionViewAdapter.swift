//
//  CollectionViewAdapter.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import UIKit

public class CollectionViewAdapter <ObjectType>: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    typealias DataSourceType = ObjectsDataSource<ObjectType>
    typealias UpdateAction = (Void) -> Void
    
    public var nibNameForObjectMatching: ((ObjectType, IndexPath) -> String)!
    public var typeForSupplementaryViewOfKindMatching: ((String, IndexPath) -> UICollectionReusableView.Type)?
    public var userInfoForCellSizeMatching: ((IndexPath) -> [String: AnyObject]?) = { _ in return nil }
    
    public let didSelectCell = Pipe<(UICollectionViewCell, IndexPath, ObjectType)>()
    public let willDisplayCell = Pipe<(UICollectionViewCell, IndexPath)>()
    public let willCalculateSize = Pipe<(UICollectionViewCell, IndexPath)>()
    public let didEndDisplayingCell = Pipe<(UICollectionViewCell, IndexPath)>()
    public let willSetObject = Pipe<(UICollectionViewCell, IndexPath)>()
    public let didSetObject = Pipe<(UICollectionViewCell, IndexPath)>()
    public let didScroll = Pipe<UICollectionView>()
    public let didEndDecelerating = Pipe<UICollectionView>()
    public let didEndDragging = Pipe<UICollectionView>()
    public let willEndDragging = Pipe<(UICollectionView, CGPoint, UnsafeMutablePointer<CGPoint>)>()
    
    public let willDisplaySupplementaryView = Pipe<(UICollectionReusableView, String, IndexPath)>()
    public let didEndDisplayingSupplementaryView = Pipe<(UICollectionReusableView, String, IndexPath)>()
    
    public var checkedIndexPaths = [IndexPath]() {
        didSet {
            collectionView.indexPathsForVisibleItems.forEach {
                if var checkable = collectionView.cellForItem(at: $0) as? Checkable {
                    checkable.checked = checkedIndexPaths.contains($0)
                }
            }
        }
    }
    
    private weak var collectionView: UICollectionView!
    
    private var dataSource: ObjectsDataSource<ObjectType>!
    private var instances = [String: UICollectionViewCell]()
    private var identifiersForIndexPaths = [IndexPath: String]()
    private var mappings: [String: (ObjectType, UICollectionViewCell, IndexPath) -> Void] = [:]
    private var updateActions = [UpdateAction]()
    
    public init(dataSource: ObjectsDataSource<ObjectType>, collectionView: UICollectionView) {
        super.init()
        
        self.collectionView = collectionView
        collectionView.dataSource = self
        collectionView.delegate = self
        
        self.dataSource = dataSource
        
        dataSource.beginUpdatesSignal.subscribeNext { [weak self] in
            self?.updateActions.removeAll()
            }.putInto(pool)
        
        dataSource.endUpdatesSignal.subscribeNext { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.updateActions.forEach { $0() }
            }.putInto(pool)
        
        dataSource.reloadDataSignal.subscribeNext { [weak self] in
            guard let strongSelf = self else { return }
            
            UIView.animate(withDuration: 0.1, animations: {
                strongSelf.collectionView.alpha = 0},
                           completion: { completed in
                            strongSelf.collectionView.reloadData()
                            UIView.animate(withDuration: 0.2, animations: {
                                strongSelf.collectionView.alpha = 1
                            })
            })
            }.putInto(pool)
        
        dataSource.didChangeObjectSignal.subscribeNext { [weak self] object, changeType, fromIndexPath, toIndexPath in
            guard let strongSelf = self else {
                return
            }
            
            switch changeType {
            case .Insertion:
                if let toIndexPath = toIndexPath {
                    strongSelf.updateActions.append() { [weak strongSelf] in
                        strongSelf?.collectionView.insertItems(at: [toIndexPath])
                    }
                }
            case .Deletion:
                strongSelf.updateActions.append() { [weak strongSelf] in
                    if let fromIndexPath = fromIndexPath {
                        strongSelf?.collectionView.deleteItems(at: [fromIndexPath])
                    }
                }
            case .Update:
                strongSelf.updateActions.append() { [weak strongSelf] in
                    if let indexPath = toIndexPath {
                        strongSelf?.collectionView.reloadItems(at: [indexPath])
                    }
                }
            case .Move:
                strongSelf.updateActions.append() { [weak strongSelf] in
                    if let fromIndexPath = fromIndexPath, let toIndexPath = toIndexPath {
                        strongSelf?.collectionView.moveItem(at: fromIndexPath, to: toIndexPath)
                    }
                }
            }
            }.putInto(pool)
        
        dataSource.didChangeSectionSignal.subscribeNext { [weak self] changeType, fromIndex, toIndex in
            guard let strongSelf = self else { return }
            
            switch changeType {
            case .Insertion:
                strongSelf.updateActions.append() { [weak strongSelf] in
                    if let toIndex = toIndex {
                        strongSelf?.collectionView.insertSections(IndexSet(integer: toIndex))
                    }
                }
            case .Deletion:
                if let fromIndex = fromIndex {
                    strongSelf.updateActions.append() { [weak strongSelf] in
                        strongSelf?.collectionView.deleteSections(IndexSet(integer: fromIndex))
                    }
                }
            default:
                break
            }
            }.putInto(pool)
    }
    
    public func registerCellClass<U: ObjectConsuming>(_ cellClass: U.Type) where U.ObjectType == ObjectType {
        let identifier = String(describing: cellClass)
        let nib = UINib(nibName: identifier, bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: identifier)
        instances[identifier] = nib.instantiate(withOwner: self, options: nil).last as? UICollectionViewCell
        
        mappings[identifier] = { object, cell, _ in
            if let consumer = cell as? U {
                consumer.applyObject(object)
            }
        }
    }
    
    //UICollectionViewDataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfObjectsInSection(section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let object = dataSource.objectAtIndexPath(indexPath)!;
        
        let identifier = nibNameForObjectMatching(object, indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        identifiersForIndexPaths[indexPath] = identifier
        
        
        willSetObject.sendNext((cell, indexPath))
        let mapping = mappings[identifier]!
        mapping(object, cell, indexPath)
        didSetObject.sendNext((cell, indexPath))
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if var checkable = cell as? Checkable {
            checkable.checked = checkedIndexPaths.contains(indexPath)
        }
        
        willDisplayCell.sendNext((cell, indexPath))
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let identifier = String(describing: typeForSupplementaryViewOfKindMatching!(kind, indexPath))
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)
        return view
    }
    
    public func collectiolnView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        didEndDisplayingCell.sendNext((cell, indexPath))
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        willDisplaySupplementaryView.sendNext((view, elementKind, indexPath))
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        didEndDisplayingSupplementaryView.sendNext((view, elementKind, indexPath))
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let identifier = nibNameForObjectMatching(dataSource.objectAtIndexPath(indexPath)!, indexPath)
        
        if let cell = instances[identifier] as? SizeCalculatingCell {
            willCalculateSize.sendNext((instances[identifier]!, indexPath))
            return cell.size(forObject: dataSource.objectAtIndexPath(indexPath), userInfo: userInfoForCellSizeMatching(indexPath))
        }
        
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.itemSize
        }
        
        return CGSize.zero;
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll.sendNext(collectionView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndDecelerating.sendNext(collectionView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        didEndDragging.sendNext(collectionView)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        willEndDragging.sendNext((collectionView, velocity, targetContentOffset))
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectCell.sendNext((
            collectionView.cellForItem(at: indexPath)!,
            indexPath,
            dataSource.objectAtIndexPath(indexPath)!)
        )
    }
    
}

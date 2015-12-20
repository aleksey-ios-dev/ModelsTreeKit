//
//  CollectionViewAdapter.swift
//  We Learn English
//
//  Created by aleksey on 06.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import UIKit

public class CollectionViewAdapter <ObjectType>: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    typealias DataSourceType = ObjectsDataSource<ObjectType>
    typealias UpdateAction = Void -> Void
    
    weak var collectionView: UICollectionView!
    
    public var nibNameForObjectMatching: (ObjectType -> String)!
    
    public let didSelectCellSignal = Signal<(cell: UICollectionViewCell?, object: ObjectType?)>()
    public let willDisplayCell = Signal<UICollectionViewCell>()
    public let willCalculateSizeSignal = Signal<UICollectionViewCell>()

    public let didEndDisplayingCell = Signal<UICollectionViewCell>()

    public let willSetObject = Signal<UICollectionViewCell>()
    public let didSetObject = Signal<UICollectionViewCell>()
    
    private var dataSource: ObjectsDataSource<ObjectType>!
    private var instances = [String: UICollectionViewCell]()
    private var identifiersForIndexPaths = [NSIndexPath: String]()
    private var pool = AutodisposePool()
    
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
            guard let strongSelf = self else {
                return
            }
            for action in strongSelf.updateActions {
                action()
            }
        }.putInto(pool)
        
        dataSource.reloadDataSignal.subscribeNext { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            UIView.animateWithDuration(0.1, animations: {
                strongSelf.collectionView.alpha = 0},
                completion: { completed in
                    strongSelf.collectionView.reloadData()
                    UIView.animateWithDuration(0.2, animations: {
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
                        strongSelf?.collectionView.insertItemsAtIndexPaths([toIndexPath])
                    }
                }
            case .Deletion:
                strongSelf.updateActions.append() { [weak strongSelf] in
                    if let fromIndexPath = fromIndexPath {
                        strongSelf?.collectionView.deleteItemsAtIndexPaths([fromIndexPath])
                    }
                }
            case .Update:
                strongSelf.updateActions.append() { [weak strongSelf] in
                    if let indexPath = toIndexPath {
                        strongSelf?.collectionView.reloadItemsAtIndexPaths([indexPath])
                    }
                }
            case .Move:
                strongSelf.updateActions.append() { [weak strongSelf] in
                    if let fromIndexPath = fromIndexPath, let toIndexPath = toIndexPath {
                        strongSelf?.collectionView.moveItemAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                    }
                }
            }
        }.putInto(pool)
        
        dataSource.didChangeSectionSignal.subscribeNext { [weak self] changeType, fromIndex, toIndex in
            guard let strongSelf = self else {
                return
            }
            
            switch changeType {
            case .Insertion:
                strongSelf.updateActions.append() { [weak strongSelf] in
                    if let toIndex = toIndex {
                        strongSelf?.collectionView.insertSections(NSIndexSet(index: toIndex))
                    }
                }
            case .Deletion:
                if let fromIndex = fromIndex {
                    strongSelf.updateActions.append() { [weak strongSelf] in
                        strongSelf?.collectionView.deleteSections(NSIndexSet(index: fromIndex))
                    }
                }
            default:
                break
            }
        }.putInto(pool)
    }
    
    public func registerNibNamed(nibName: String) {
        let nib = UINib(nibName: nibName, bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: nibName)
        instances[nibName] = nib.instantiateWithOwner(self, options: nil).last as? UICollectionViewCell
    }
    
    //UICollectionViewDataSource
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections()
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfObjectsInSection(section)
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let object = dataSource.objectAtIndexPath(indexPath)!;
        
        let identifier = nibNameForObjectMatching(object)
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
        identifiersForIndexPaths[indexPath] = identifier
        
        if var consumer = cell as? ObjectConsuming {
            willSetObject.sendNext(cell)
            consumer.object = dataSource.objectAtIndexPath(indexPath)
            didSetObject.sendNext(cell)
        }
        
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        willDisplayCell.sendNext(cell)
    }
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        didEndDisplayingCell.sendNext(cell)
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let identifier = nibNameForObjectMatching(dataSource.objectAtIndexPath(indexPath)!)
        
        if let cell = instances[identifier] as? SizeCalculatingCell {
            willCalculateSizeSignal.sendNext(instances[identifier]!)
            return cell.sizeFor(dataSource.objectAtIndexPath(indexPath))
        }
        
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.itemSize
        }
        
        return CGSizeZero;
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        didSelectCellSignal.sendNext(cell: collectionView.cellForItemAtIndexPath(indexPath), object: dataSource.objectAtIndexPath(indexPath))
    }
}



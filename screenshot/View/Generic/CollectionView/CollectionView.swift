//
//  CollectionView.swift
//  screenshot
//
//  Created by Corey Werner on 2/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CollectionView: UICollectionView, EmptyListProtocol {
    private let emptyListController = EmptyListController()
    
    var emptyView: UIView? {
        willSet(newEmptyView) {
            emptyListController.willSetEmptyView(newEmptyView, oldEmptyView: emptyView)
        }
        didSet {
            emptyListController.didSetEmptyView(emptyView, scrollView: self)
        }
    }
    
    override var contentSize: CGSize {
        didSet {
            emptyListController.didSetContentSize(scrollView: self, emptyView: emptyView)
        }
    }
    
    override var contentInset: UIEdgeInsets {
        didSet {
            emptyListController.didSetContentInset(scrollView: self)
        }
    }
}

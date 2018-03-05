//
//  ShoppablesCollectionView.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

public protocol ShoppablesCollectionViewDelegate : UICollectionViewDelegate {
    var didViewControllerAppear:Bool {get}
    func repositionShoppables()
}

class ShoppablesCollectionView: UICollectionView {
    var shoppableDelegate: ShoppablesCollectionViewDelegate?
    
    override var contentSize: CGSize {
        didSet{
            if self.shoppableDelegate?.didViewControllerAppear == true && self.numberOfItems(inSection: 0) > 0 {
                if (self.contentInset.left == ShoppablesToolbar.preservedCollectionViewContentInset().left) {
                    // This generally will happen through state restoration and
                    // is needed to prevent undesired animations
                    self.shoppableDelegate?.repositionShoppables()
                } else {
                    self.layoutIfNeeded()
                    UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                        self.shoppableDelegate?.repositionShoppables()
                    })
                }
            } else {
                self.shoppableDelegate?.repositionShoppables()
            }
        }
    }
}


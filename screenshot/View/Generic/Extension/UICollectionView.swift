//
//  UICollectionView.swift
//  screenshot
//
//  Created by Corey Werner on 3/21/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

extension UICollectionView {
    func indexPath(for event: UIEvent) -> IndexPath? {
        if let location = event.allTouches?.first?.location(in: self) {
            return indexPathForItem(at: location)
        }
        return nil
    }
}

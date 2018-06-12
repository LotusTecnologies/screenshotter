//
//  UITableView.swift
//  screenshot
//
//  Created by Corey Werner on 3/20/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

extension UITableView {
    func indexPath(for event: UIEvent) -> IndexPath? {
        if let location = event.allTouches?.first?.location(in: self) {
            return indexPathForRow(at: location)
        }
        return nil
    }
}

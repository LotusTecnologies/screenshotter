//
//  ScreenshotsDeleteButton.swift
//  screenshot
//
//  Created by Corey Werner on 2/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ScreenshotsDeleteButton : UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .crazeRed
        updateTitle()
        updateTitleColor()
    }
    
    var deleteCount: Int = 0 {
        didSet {
            updateTitle()
            updateTitleColor()
        }
    }
    
    fileprivate func updateTitle() {
        if deleteCount == 0 {
            setTitle("screenshots.delete.placeholder".localized, for: .normal)
        }
        else if deleteCount == 1 {
            setTitle("screenshots.delete.single".localized(withFormat: deleteCount), for: .normal)
        }
        else {
            setTitle("screenshots.delete.plural".localized(withFormat: deleteCount), for: .normal)
        }
    }
    
    fileprivate func updateTitleColor() {
        let alpha: CGFloat = (deleteCount == 0) ? 0.5 : 1
        setTitleColor(UIColor(white: 1, alpha: alpha), for: .normal)
    }
}

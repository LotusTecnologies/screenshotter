//
//  TutorialTrySlideView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

protocol TutorialTrySlideViewDelegate : class {
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideView)
}

public class TutorialTrySlideView : HelperView {
    weak var delegate: TutorialTrySlideViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.text = "Try It Out"
        
        if UIDevice.isHomeButtonless {
            subtitleLabel.text = "Press the volume up & power buttons to take a screenshot of this page"
            contentImage = UIImage(named: "TutorialTryGraphicX")
            
        } else {
            subtitleLabel.text = "Press the home & power buttons to take a screenshot of this page"
            
            if UIDevice.is568h || UIDevice.is480h {
                contentImage = UIImage(named: "TutorialTryGraphicSE")
                
            } else {
                contentImage = UIImage(named: "TutorialTryGraphic")
            }
        }
        
        if UIDevice.isSimulator {
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(applicationUserDidTakeScreenshot)))
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Screenshot handling
    
    @objc func applicationUserDidTakeScreenshot() {
        PermissionsManager.shared.requestPermission(for: .photo) { granted in
            AssetSyncModel.sharedInstance.syncTutorialPhoto(image: UIImage(named: "TutorialScreenshot")!)
            self.delegate?.tutorialTrySlideViewDidComplete(self)
        }
    }
}

extension TutorialTrySlideView : TutorialSlideView {
    public func didEnterSlide() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }
    
    public func willLeaveSlide() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Parse Image Helper

extension TutorialTrySlideView {
    static let rawGraphic = UIImage(named: "TutorialScreenshot")
}

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
            contentImage = UIImage(named: "TutorialTryGraphic")
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
        guard let window = window else {
            return
        }
        
        let scale = UIScreen.main.scale
        var snapshotImage:UIImage? = nil
        var rect = CGRect.zero
        rect.size.width = window.bounds.size.width * scale
        rect.size.height = window.bounds.size.height * scale
        
        UIGraphicsBeginImageContext(rect.size)
        window.drawHierarchy(in: rect, afterScreenUpdates: false)
        snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = snapshotImage else {
            return
        }
    
        PermissionsManager.shared().requestPermission(for: .photo) { granted in
            AssetSyncModel.sharedInstance.syncTutorialPhoto(image: image)
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
    static let rawGraphic = UIImage(named: "TutorialTryRawGraphic")
}

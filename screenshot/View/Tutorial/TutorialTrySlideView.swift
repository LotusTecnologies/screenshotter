//
//  TutorialTrySlideView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import Appsee

protocol TutorialTrySlideViewDelegate : NSObjectProtocol {
    func tutorialTrySlideViewDidSkip(_ slideView: TutorialTrySlideView)
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideView)
}

public class TutorialTrySlideView : HelperView {
    weak var delegate: TutorialTrySlideViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.text = "tutorial.try.title".localized
        
        let font = UIFont.preferredFont(forTextStyle: .title3)
        var boldFont = font
        
        if let descriptor = boldFont.fontDescriptor.withSymbolicTraits(.traitBold) {
            boldFont = UIFont(descriptor: descriptor, size: 0)
        }
        
        let attributes = [
            [NSFontAttributeName: boldFont],
            [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.crazeRed],
            [NSFontAttributeName: font]
        ]
        
        if UIDevice.isHomeButtonless {
            subtitleLabel.attributedText = NSMutableAttributedString(segmentedString: "tutorial.try.detail.x", attributes: attributes)
            contentImage = UIImage(named: "TutorialTryGraphicX")
            
        } else {
            subtitleLabel.attributedText = NSMutableAttributedString(segmentedString: "tutorial.try.detail", attributes: attributes)
            
            if UIDevice.is568h || UIDevice.is480h {
                contentImage = UIImage(named: "TutorialTryGraphicSE")
                
            } else {
                contentImage = UIImage(named: "TutorialTryGraphic")
            }
        }
        
        let skipButton = UIButton()
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("tutorial.try.skip".localized, for: .normal)
        skipButton.setTitleColor(.crazeGreen, for: .normal)
        skipButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        skipButton.addTarget(self, action: #selector(skipButtonAction), for: .touchUpInside)
        addSubview(skipButton)
        skipButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        skipButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
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
            AssetSyncModel.sharedInstance.syncTutorialPhoto(image: type(of: self).rawGraphic!)
            self.delegate?.tutorialTrySlideViewDidComplete(self)
        }
    }
    
    // MARK: Skip
    
    @objc func skipButtonAction() {
        AssetSyncModel.sharedInstance.scanPhotoGalleryForFashion()
        self.delegate?.tutorialTrySlideViewDidSkip(self)
    }
}

extension TutorialTrySlideView : TutorialSlideViewProtocol {
    func didEnterSlide() {
        Appsee.startScreen("Tutorial Try")
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }
    
    func willLeaveSlide() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Parse Image Helper

extension TutorialTrySlideView {
    static let rawGraphic = UIImage(named: "TutorialScreenshot")
}

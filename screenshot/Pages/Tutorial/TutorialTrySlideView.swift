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
        subtitleLabel.text = "Press the home & power buttons to take a screenshot of this page"
        
        let imageView = UIImageView(image: UIImage(named: "TutorialTryGraphic"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        
        imageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        if UIDevice.isSimulator {
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(applicationUserDidTakeScreenshot)))
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
            
            if granted == false {
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.tutorialShouldPresentScreenshotPicker)
                UserDefaults.standard.synchronize()
            }
            
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

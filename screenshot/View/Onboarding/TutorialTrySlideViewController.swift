//
//  TutorialTrySlideView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import Appsee

protocol TutorialTrySlideViewControllerDelegate : class {
    func tutorialTrySlideViewDidSkip(_ slideView: TutorialTrySlideViewController)
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideViewController)
}

public class TutorialTrySlideViewController : UIViewController {
    weak var delegate: TutorialTrySlideViewControllerDelegate?
    
    let helperView = HelperView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = .white
        
        helperView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        helperView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        helperView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        helperView.layoutMargins = {
            var extraTop = CGFloat(0)
            var extraBottom = CGFloat(0)
            
            if !UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
                if UIDevice.is812h || UIDevice.is736h {
                    extraTop = .extendedPadding
                    extraBottom = .extendedPadding
                    
                } else {
                    extraTop = .padding
                    extraBottom = .padding
                }
            }
            var paddingX: CGFloat = .padding
            if UIApplication.shared.preferredContentSizeCategory == UIContentSizeCategory.large {
                if UIDevice.is375w {
                    paddingX = 30
                    
                } else if UIDevice.is414w {
                    paddingX = 45
                }
            }
            
            return UIEdgeInsets(top: .padding + extraTop, left: paddingX, bottom: .padding + extraBottom, right: paddingX)
        }()
        
        helperView.titleLabel.text = "tutorial.try.title".localized
        
        let font = UIFont.preferredFont(forTextStyle: .title3)
        var boldFont = font
        
        if let descriptor = boldFont.fontDescriptor.withSymbolicTraits(.traitBold) {
            boldFont = UIFont(descriptor: descriptor, size: 0)
        }
        
        let attributes = [
            [NSAttributedStringKey.font: boldFont],
            [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.crazeRed],
            [NSAttributedStringKey.font: font]
        ]
        
        if UIDevice.isHomeButtonless {
            helperView.subtitleLabel.attributedText = NSMutableAttributedString(segmentedString: "tutorial.try.detail.x", attributes: attributes)
            helperView.contentImage = UIImage(named: "TutorialTryGraphicX")
            
        } else {
            helperView.subtitleLabel.attributedText = NSMutableAttributedString(segmentedString: "tutorial.try.detail", attributes: attributes)
            
            if UIDevice.is568h || UIDevice.is480h {
                helperView.contentImage = UIImage(named: "TutorialTryGraphicSE")
                
            } else {
                helperView.contentImage = UIImage(named: "TutorialTryGraphic")
            }
        }
        
        let skipButton = UIButton()
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("tutorial.try.skip".localized, for: .normal)
        skipButton.setTitleColor(.crazeGreen, for: .normal)
        skipButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        skipButton.addTarget(self, action: #selector(skipButtonAction), for: .touchUpInside)
        helperView.addSubview(skipButton)
        skipButton.bottomAnchor.constraint(equalTo: helperView.bottomAnchor).isActive = true
        skipButton.trailingAnchor.constraint(equalTo: helperView.trailingAnchor).isActive = true
        
        if UIDevice.isSimulator {
            helperView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(applicationUserDidTakeScreenshot)))
        }
    }
    
    
    public override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        Appsee.startScreen("Tutorial Try")
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationUserDidTakeScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
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
            if let image = UIImage(named: "TutorialScreenshot") {
                AssetSyncModel.sharedInstance.syncTutorialPhoto(image:image )
            }
            self.delegate?.tutorialTrySlideViewDidComplete(self)
        }
    }
    
    // MARK: Skip
    
    @objc func skipButtonAction() {
        AssetSyncModel.sharedInstance.scanPhotoGalleryForFashion()
        self.delegate?.tutorialTrySlideViewDidSkip(self)
    }
}

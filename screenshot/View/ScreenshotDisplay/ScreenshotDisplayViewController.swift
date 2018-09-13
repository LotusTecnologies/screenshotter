//
//  ScreenshotDisplayViewController.swift
//  screenshot
//
//  Created by Gershon Kagan on 2/11/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class ScreenshotDisplayViewController: BaseViewController, UIScrollViewDelegate {
    
    // MARK: Properties
    
    let scrollView = UIScrollView()
    var screenshotImageFrameView: UIView?
    var b0: CGPoint = .zero
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .gray4
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.maximumZoomScale = 3
        scrollView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        self.view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo:self.topLayoutGuide.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo:self.view.leadingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo:self.bottomLayoutGuide.topAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo:self.view.trailingAnchor).isActive = true
        
        let horizontal: CGFloat = self.scrollView.contentInset.left + self.scrollView.contentInset.right
        let vertical: CGFloat  = self.scrollView.contentInset.top + self.scrollView.contentInset.bottom
        
        screenshotImageView.contentMode = .scaleAspectFit
        self.scrollView.addSubview(screenshotImageView)
        screenshotImageView.translatesAutoresizingMaskIntoConstraints = false
        screenshotImageView.topAnchor.constraint(equalTo:self.scrollView.topAnchor).isActive = true
        screenshotImageView.leadingAnchor.constraint(equalTo:self.scrollView.leadingAnchor).isActive = true
        screenshotImageView.bottomAnchor.constraint(equalTo:self.scrollView.bottomAnchor).isActive = true
        screenshotImageView.trailingAnchor.constraint(equalTo:self.scrollView.trailingAnchor).isActive = true
        screenshotImageView.widthAnchor.constraint(equalTo:self.scrollView.widthAnchor, constant:-horizontal).isActive = true
        screenshotImageView.heightAnchor.constraint(equalTo:self.scrollView.heightAnchor, constant:-vertical).isActive = true
        
        screenshotImageView.didLayoutSubviews = { [weak self] in
            self?.insertShoppableFrames()
        }
        
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        guard let screenshot = screenshot else {
            return []
        }
        
        let deleteAction = UIPreviewAction(title: "generic.delete".localized, style: .destructive) { (action, viewController) in
            DataModel.sharedInstance.hide(screenshotOIDArray: [screenshot.objectID], kind:.single)
        }
        return [deleteAction]
    }
    
    // MARK: Screenshot
    
    fileprivate var shoppablesFrc: FetchedResultsControllerManager<Shoppable>?
    
    var screenshot: Screenshot? {
        didSet {
            if let screenshot = screenshot {
                let shoppablesFrc = DataModel.sharedInstance.shoppableFrc(delegate: self, screenshot: screenshot)
                self.shoppablesFrc = shoppablesFrc
                
                if let data = screenshot.imageData, let image = UIImage(data: data as Data) {
                    self.image = image
                }
                
            }
        }
    }
    
    // MARK: - Image
    
    fileprivate let screenshotImageView = ImageView()
    
    fileprivate var image: UIImage? {
        get {
            return self.screenshotImageView.image
        }
        set(newImage) {
            self.screenshotImageView.image = newImage
        }
    }
    
    // MARK: - Shoppable
    
    @objc func insertShoppableFrames() {
        guard let image = image, !screenshotImageView.bounds.isEmpty else {
            print("insertShoppableFrames empty image")
            return
        }
        self.screenshotImageFrameView?.removeFromSuperview()
        
        let imageFrame = image.size.aspectFitRectInSize(self.screenshotImageView.bounds.size)
        
        let screenshotImageFrameView = UIView(frame: imageFrame)
        screenshotImageFrameView.isUserInteractionEnabled = false
        self.screenshotImageView.addSubview(screenshotImageFrameView)
        self.screenshotImageFrameView = screenshotImageFrameView

        
        if let shoppables = self.shoppablesFrc?.fetchedObjects {
            for shoppable in shoppables {
                let frame = shoppable.frame(size: screenshotImageFrameView.bounds.size)
                
                let frameView = UIView(frame: frame)
                frameView.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
                frameView.layer.borderWidth = 2
                screenshotImageFrameView.addSubview(frameView)
            }
        }
    }
    
    // MARK: - Scroll View

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.screenshotImageView
    }
    
}

extension ScreenshotDisplayViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            insertShoppableFrames()
        }
    }
}

fileprivate extension ScreenshotDisplayViewController {
    class ImageView: UIImageView {
        var didLayoutSubviews: (()->())?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            didLayoutSubviews?()
        }
    }
}

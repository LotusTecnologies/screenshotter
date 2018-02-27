//
//  ScreenshotDisplayViewController.swift
//  screenshot
//
//  Created by Gershon Kagan on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ScreenshotDisplayViewController: BaseViewController, UIScrollViewDelegate {
    
    // MARK: Properties
    
    var shoppables: [Shoppable]?
    var scrollView: UIScrollView!
    var screenshotImageFrameView: UIView?
    var b0: CGPoint = .zero

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let p: CGFloat = .padding
        let statusBarHeight:CGFloat = UIApplication.shared.statusBarFrame.size.height
        
        let backgroundView = UIView.init()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .gray4
        self.view.addSubview(backgroundView)
        backgroundView.topAnchor.constraint(equalTo:self.view.topAnchor, constant:statusBarHeight).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo:self.view.leadingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo:self.view.bottomAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo:self.view.trailingAnchor).isActive = true
        
        self.scrollView = {
            let scrollView = UIScrollView.init()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.delegate = self
            scrollView.maximumZoomScale = 3
            scrollView.contentInset = UIEdgeInsetsMake(p, p, p, p)
            self.view.addSubview(scrollView)
            scrollView.topAnchor.constraint(equalTo:self.topLayoutGuide.bottomAnchor).isActive = true
            scrollView.leadingAnchor.constraint(equalTo:self.view.leadingAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo:self.bottomLayoutGuide.topAnchor).isActive = true
            scrollView.trailingAnchor.constraint(equalTo:self.view.trailingAnchor).isActive = true
            return scrollView
        }()
        
        let horizontal: CGFloat = self.scrollView.contentInset.left + self.scrollView.contentInset.right
        let vertical: CGFloat  = self.scrollView.contentInset.top + self.scrollView.contentInset.bottom
        
        let screenshotImageView = self.screenshotImageView
        screenshotImageView.contentMode = .scaleAspectFit
        self.scrollView.addSubview(screenshotImageView)
        screenshotImageView.translatesAutoresizingMaskIntoConstraints = false
        screenshotImageView.topAnchor.constraint(equalTo:self.scrollView.topAnchor).isActive = true
        screenshotImageView.leadingAnchor.constraint(equalTo:self.scrollView.leadingAnchor).isActive = true
        screenshotImageView.bottomAnchor.constraint(equalTo:self.scrollView.bottomAnchor).isActive = true
        screenshotImageView.trailingAnchor.constraint(equalTo:self.scrollView.trailingAnchor).isActive = true
        screenshotImageView.widthAnchor.constraint(equalTo:self.scrollView.widthAnchor, constant:-horizontal).isActive = true
        screenshotImageView.heightAnchor.constraint(equalTo:self.scrollView.heightAnchor, constant:-vertical).isActive = true
        
#if STORE_NEW_TUTORIAL_SCREENSHOT
        screenshotImageView.isUserInteractionEnabled = true
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(gestureRecognizer:)))
        screenshotImageView.addGestureRecognizer(longPressGestureRecognizer)
#endif
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
#if STORE_NEW_TUTORIAL_SCREENSHOT
#else
        if !self.screenshotImageView.bounds.isEmpty {
            self.insertShoppableFrames()
        }
#endif
    }
    
    // MARK: - Image
    
    let screenshotImageView = UIImageView()
    var image: UIImage? {
        get {
            return self.screenshotImageView.image
        }
        set(newImage) {
            self.screenshotImageView.image = newImage
        }
    }
    
    // MARK: - Shoppable

    @objc func insertShoppableFrames() {
        guard let image = image else {
            print("insertShoppableFrames empty image")
            return
        }
        self.screenshotImageFrameView?.removeFromSuperview()
        
        let imageFrame = image.size.aspectFitRectInSize(self.screenshotImageView.bounds.size)
        
        let screenshotImageFrameView = UIView(frame: imageFrame)
        screenshotImageFrameView.isUserInteractionEnabled = false
        self.screenshotImageView.addSubview(screenshotImageFrameView)
        self.screenshotImageFrameView = screenshotImageFrameView

        if let shoppables = self.shoppables {
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
    
    // MARK: - Gesture Recognizer

    @objc func handleLongPressGesture(gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .recognized else {
            return
        }
        let longPressPoint = gestureRecognizer.location(in: self.screenshotImageView)
        var normalizedX = longPressPoint.x / self.screenshotImageView.bounds.size.width
        var normalizedY = longPressPoint.y / self.screenshotImageView.bounds.size.height
    
        //    MAX(0, normalizedX)
        if normalizedX < 0 {
            normalizedX = 0
        }
        if normalizedY < 0 {
            normalizedY = 0
        }
        if normalizedX > 1 {
            normalizedX = 1
        }
        if normalizedY > 1 {
            normalizedY = 1
        }
        let normalizedPressPoint = CGPoint(x: normalizedX, y: normalizedY)
        if self.b0 == .zero {
            self.b0 = normalizedPressPoint
            print("b0:\(self.b0)  longPressPoint:\(longPressPoint)  in size:\(self.screenshotImageView.bounds.size)")
        } else {
            let b1 = normalizedPressPoint
            print("b1:\(b1)  longPressPoint:\(longPressPoint)  in size:\(self.screenshotImageView.bounds.size)")
            let viewWidth = self.screenshotImageView.bounds.size.width
            let viewHeight = self.screenshotImageView.bounds.size.height
            let frame = CGRect(x: self.b0.x * viewWidth, y: self.b0.y * viewHeight, width: (b1.x - self.b0.x) * viewWidth, height: (b1.y - self.b0.y) * viewHeight)
            let frameView = UIView(frame: frame)
            frameView.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
            frameView.layer.borderWidth = 2
            self.screenshotImageView.addSubview(frameView)
            self.b0 = .zero
        }
    }
    
}

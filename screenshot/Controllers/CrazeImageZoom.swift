//
//  CrazeImageZoom.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//
// based on https://github.com/twomedia/TMImageZoom by Thomas Maw

import UIKit


extension Notification.Name {
    static let CrazeImageZoom_started_notification = Notification.Name(rawValue: "io.crazeapp.screenshot.CrazeImageZoom_started_notification")
    static let CrazeImageZoom_ended_notification = Notification.Name(rawValue: "io.crazeapp.screenshot.CrazeImageZoom_ended_notification")
}


class CrazeImageZoom: NSObject {
    static let shared = CrazeImageZoom()
    
    private var currentImageView:UIView?
    var hostedImageView:UIImageView?
    private var isAnimatingReset:Bool = false
    private var relativePositionOfTouchInView:CGPoint?
    private var startingRect:CGRect?
    var isHandlingGesture:Bool = false

    func gestureStateChanged(_ gesture:UIPinchGestureRecognizer, imageView:UIImageView) {
        self.gestureStateChanged(gesture,
                                 imageView: imageView,
                                 popViewTransform: nil)
    }
    
    func gestureStateChanged(_ gesture:UIPinchGestureRecognizer, imageView:UIImageView, popViewTransform:((UIImageView)->UIView)?) {

        guard isAnimatingReset == false else {
            return
        }
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            self.resetImageZoom()
            return
        }
        
        if isHandlingGesture && self.hostedImageView != imageView {
            return
        }
    
        if !isHandlingGesture && gesture.state == .began {
            self.isHandlingGesture = true
            self.hostedImageView = imageView
            imageView.isHidden = true
            NotificationCenter.default.post(name: .CrazeImageZoom_started_notification, object: nil)
            
            let currentWindow = UIApplication.shared.keyWindow
            let transform:((UIImageView)->UIView) = popViewTransform ?? { imageView in
                let newImageView = UIImageView.init(image: imageView.image)
                newImageView.contentMode = imageView.contentMode
                let point = imageView.convert(imageView.frame.origin, to: nil)
                let imageViewStartingRect = CGRect.init(origin: point, size: imageView.frame.size)
                newImageView.frame = imageViewStartingRect
                return newImageView
            }
            let popupView = transform(imageView)
            self.startingRect = popupView.frame
            self.currentImageView = popupView
            self.relativePositionOfTouchInView = popupView.frame.relativePositionOf(point: gesture.location(in: popupView))
            currentWindow?.addSubview(popupView)
        }
        
        if (gesture.numberOfTouches < 2) {
            self.resetImageZoom()
            return;
        }
        if gesture.state == .changed {
            // Calculate new image scale.
            if let currentImageView = self.currentImageView, let startingRect = self.startingRect, startingRect.size.width > 0, let relativePositionOfTouchInView = self.relativePositionOfTouchInView {
                let currentScale = currentImageView.frame.size.width / startingRect.size.width;
                let newScale = currentScale * gesture.scale;
                let newSize = CGSize.init(width: startingRect.size.width * newScale, height: startingRect.size.height * newScale)
                let newFrameSize = CGRect.init(origin: .zero, size: newSize)
                
                
                //position the origin so that the location of the gesture stays in the same relative position of the image.
                // ie if the user zoomed in the bottom left, keep the bottom left in the same area as his fingers.
                let locationInWindow = gesture.location(in: UIApplication.shared.keyWindow)
                let origin = CGPoint.init(
                    x: locationInWindow.x - newFrameSize.absolutePositionOf(relativePoint: relativePositionOfTouchInView).x,
                    y: locationInWindow.y - newFrameSize.absolutePositionOf(relativePoint: relativePositionOfTouchInView).y)
                
                let frame = CGRect.init(origin: origin, size: newSize)
                if frame.isValid {
                    currentImageView.frame = frame
                    // Reset gesture scale
                    gesture.scale = 1;
                }
                
            }
        }
    }
    
    
    func resetImageZoom() {
        
        if (isAnimatingReset || !isHandlingGesture) {
        return;
        }
        isAnimatingReset = true
        UIView.animate(withDuration: 0.2, animations: {
            if let startingRect = self.startingRect {
                self.currentImageView?.frame = startingRect
            }
        }, completion: { (finished) in
            self.currentImageView?.removeFromSuperview()
            self.currentImageView = nil
            self.hostedImageView?.isHidden = false
            self.hostedImageView = nil
            self.startingRect = nil
            self.isHandlingGesture = false
            self.isAnimatingReset = false
            NotificationCenter.default.post(name: .CrazeImageZoom_ended_notification, object: nil)
        })
    }
}

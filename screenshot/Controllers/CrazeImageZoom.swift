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
    private var firstCenterPoint:CGPoint?
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
            self.firstCenterPoint = gesture.location(in: currentWindow)
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
            currentWindow?.addSubview(popupView)
        }
        
        if (gesture.numberOfTouches < 2) {
            self.resetImageZoom()
            return;
        }
        if gesture.state == .changed {
            // Calculate new image scale.
            if let currentImageView = self.currentImageView, let startingRect = self.startingRect, let firstCenterPoint = self.firstCenterPoint, startingRect.size.width > 0 {
                let currentScale = currentImageView.frame.size.width / startingRect.size.width;
                let newScale = currentScale * gesture.scale;
                let newSize = CGSize.init(width: startingRect.size.width * newScale, height: startingRect.size.height * newScale)
                currentImageView.frame = CGRect.init(origin: currentImageView.frame.origin, size: newSize)
                
                
                // Calculate new center
                let currentWindow = UIApplication.shared.keyWindow
                let centerXDif = firstCenterPoint.x - gesture.location(in: currentWindow).x
                let centerYDif = firstCenterPoint.y -  gesture.location(in: currentWindow).y
                
                currentImageView.center = CGPoint.init(x: (startingRect.origin.x+(startingRect.size.width/2))-centerXDif,
                                                       y: (startingRect.origin.y+(startingRect.size.height/2))-centerYDif)
                
                // Reset gesture scale
                gesture.scale = 1;
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
            self.firstCenterPoint = nil
            self.isHandlingGesture = false
            self.isAnimatingReset = false
            NotificationCenter.default.post(name: .CrazeImageZoom_started_notification, object: nil)
        })
    }
}

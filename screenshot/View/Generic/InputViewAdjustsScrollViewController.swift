//
//  InputViewAdjustsScrollViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol InputViewAdjustsScrollViewControllerDelegate: NSObjectProtocol {
    func inputViewAdjustsScrollViewControllerWillShow(_ controller: InputViewAdjustsScrollViewController)
    func inputViewAdjustsScrollViewControllerWillHide(_ controller: InputViewAdjustsScrollViewController)
}

class InputViewAdjustsScrollViewController: NSObject {
    var scrollView: UIScrollView?
    weak var delegate: InputViewAdjustsScrollViewControllerDelegate?
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShowNotification(_ notification: Notification) {
        guard let scrollView = scrollView, scrollView.window != nil else {
            return
        }
        
        var contentInset = scrollView.contentInset
        var scrollIndicatorInsets = scrollView.scrollIndicatorInsets
        
        if let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contentInset.bottom = keyboardRect.height
            scrollIndicatorInsets.bottom = keyboardRect.height
        }
        
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets
        
        delegate?.inputViewAdjustsScrollViewControllerWillShow(self)
    }
    
    @objc private func keyboardWillHideNotification(_ notification: Notification) {
        guard let scrollView = scrollView, scrollView.window != nil else {
            return
        }
        
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset
        
        var scrollIndicatorInsets = scrollView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom = 0
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets
        
        delegate?.inputViewAdjustsScrollViewControllerWillHide(self)
    }
}

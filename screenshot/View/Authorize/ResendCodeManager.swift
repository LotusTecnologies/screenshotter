//
//  ResendCodeManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit


class ResendCodeManager : NSObject {
    weak var button:UIButton?
    private var startTime:Date = Date()
    private let countDownTime:TimeInterval = 60
    var timer:Timer?
    func start(with button:UIButton){
        self.button = button
        self.startTime = Date()

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {  [weak self] (t) in
            self?.updateButton()
        })
        self.updateButton()
    }
    
    deinit{
        self.timer?.invalidate()
    }
    
    private func updateButton(){
        let time = abs(startTime.timeIntervalSinceNow)
        var attributes:[NSAttributedStringKey:Any] = [:]
        attributes[.underlineStyle] = NSUnderlineStyle.styleSingle.rawValue
        if time < countDownTime {
            let secondString =  String(Int(ceil(countDownTime - time)))
            let text = "authorize.confirm.resend_code_in".localized(withFormat: secondString)
            attributes[.foregroundColor] = UIColor.gray5
            attributes[.underlineColor] = UIColor.gray5
            attributes[.font] = UIFont.systemFont(ofSize: 16)
            let attributedText = NSMutableAttributedString.init(string: text, attributes: attributes)
            let range = NSString(string: text).range(of: secondString)
            if range.location != NSNotFound{
                if let font = UIFont.init(name: "Menlo", size: 16){
                    attributedText.addAttribute(NSAttributedStringKey.font, value: font, range: range)
                }
            }
            
            self.button?.setAttributedTitle(attributedText, for: .normal)
            self.button?.isUserInteractionEnabled = false
            
        }else{
            let text = "authorize.confirm.resend_code".localized
            attributes[.foregroundColor] = UIColor.crazeRed
            attributes[.underlineColor] = UIColor.crazeRed
            let attributedText = NSAttributedString.init(string: text, attributes: attributes)
            self.button?.setAttributedTitle(attributedText, for: .normal)
            self.button?.isUserInteractionEnabled = true
        }
    }
}

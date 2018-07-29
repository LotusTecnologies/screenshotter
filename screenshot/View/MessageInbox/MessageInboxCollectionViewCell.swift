//
//  MessageInboxCollectionViewCell.swift
//  Screenshop
//
//  Created by Jonathan Rose on 7/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class MessageInboxCollectionViewCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let newBadge = UIImageView()
    let actionButton = UIButton()
    
    
    var isExpired = false {
        didSet {
            imageView.alpha = isExpired ? 0.5 : 1.0
            titleLabel.alpha = isExpired ? 0.5 : 1.0
            newBadge.alpha = isExpired ? 0.5 : 1.0
            actionButton.alpha = isExpired ? 0.5 : 1.0
        }
    }
    
    static func taggedStringForAttributedString(taggedString:String) -> NSAttributedString {
        var toReturn = NSMutableAttributedString()
        
        func append(char:Character, tags:[String]){
            var color = UIColor.gray3
            var font = UIFont.screenshopFont(.hindMedium, size: UIFont.buttonFontSize)
            var underlineStyle = NSUnderlineStyle.styleNone.rawValue

            for t in tags {
                let tag = t.lowercased()

                if tag == "crazered" {
                    color = UIColor.crazeRed
                }else if tag == "crazegreen" {
                    color = UIColor.crazeGreen
                }else if tag == "bold" {
                    font = UIFont.screenshopFont(.hindBold, size: UIFont.buttonFontSize)
                }else if tag == "underline"{
                    underlineStyle = NSUnderlineStyle.styleSingle.rawValue
                }else if UIColor.isCssName(tag) || tag.hasPrefix("#") {
                     color = UIColor.init(hex: tag)
                }
             }
            if underlineStyle == NSUnderlineStyle.styleNone.rawValue {
                toReturn.append(NSAttributedString.init(string: String(char), attributes: [
                    .foregroundColor: color,
                    .backgroundColor:UIColor.clear,
                    .font: font
                    ])
                )
            }else{
                toReturn.append(NSAttributedString.init(string: String(char), attributes: [
                    .foregroundColor: color,
                    .backgroundColor:UIColor.clear,
                    .font: font ,
                    .underlineStyle : underlineStyle,
                    .underlineColor: color
                    ])
                )
            }
            
        }
        
        var currentTags:[String] = []
        var buildingTag:String?
        var buildingClosingTag:String?
        var justOpenedTag = false
        taggedString.forEach { (char) in
            if justOpenedTag {
                justOpenedTag = false
                if char == "/" {
                    buildingClosingTag = ""
                }else{
                    buildingTag = ""
                }
            }
            if let b = buildingTag {
                if char == ">" {
                    currentTags.append(b)
                    buildingTag = nil
                }else {
                    buildingTag?.append(char)
                }
            }else if let b = buildingClosingTag{
                if char == ">" {
                    if currentTags.last == b {
                        currentTags.removeLast()
                    }else{
                        print("error parasing tagged string: \(taggedString)")
                    }

                    buildingClosingTag = nil
                }else if char == "/"{
                    //ignore
                }else{
                    buildingClosingTag?.append(char)
                }
            }else {
                if char == "<" {
                    justOpenedTag = true
                }else{
                    append(char: char, tags: currentTags)
                }
            }
        }
        
        return toReturn
    }
    
}



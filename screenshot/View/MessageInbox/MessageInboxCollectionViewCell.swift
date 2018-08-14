//
//  MessageInboxCollectionViewCell.swift
//  Screenshop
//
//  Created by Jonathan Rose on 7/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class MessageInboxCollectionViewCell: UICollectionViewCell {
    
    let embossedView = EmbossedView()
    let titleLabel = UILabel()
    let badge = UIView()
    let actionButton = BorderButton()
    
    var buttonColor = UIColor.crazeGreen {
        didSet {
            syncButtonColor()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.clipsToBounds = true
        self.contentView.backgroundColor = .white
        
//        let line = UIView()
//        line.backgroundColor = .gray9
//        line.translatesAutoresizingMaskIntoConstraints = false
//        self.contentView.addSubview(line)
//        line.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
//        line.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
//        line.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
//        line.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        
        embossedView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(embossedView)
        embossedView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant:.padding).isActive = true
        embossedView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        embossedView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        embossedView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: .padding).isActive = true
        
        titleLabel.numberOfLines = 3
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: self.embossedView.trailingAnchor, constant:.padding).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.embossedView.topAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant:-.padding).isActive = true

        
        actionButton.setTitleColor(self.buttonColor, for: .normal)
        actionButton.tintColor = self.buttonColor
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(actionButton)
        actionButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        actionButton.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        actionButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant:-.padding).isActive = true
        actionButton.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: .padding + .extendedPadding).isActive = true
        actionButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -1 * (.padding + .extendedPadding) ).isActive = true

        titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: actionButton.topAnchor).isActive = true

        
        badge.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.backgroundColor = .crazeRed
        badge.isUserInteractionEnabled = false
        badge.isHidden = true
        badge.transform = CGAffineTransform(rotationAngle: .pi / 4)
        badge.layer.shadowPath = UIBezierPath(rect: badge.bounds).cgPath
        badge.layer.shadowColor = UIColor.black.cgColor
        badge.layer.shadowOffset = CGSize(width: 0, height: 1)
        badge.layer.shadowRadius = 2
        badge.layer.shadowOpacity = 0.4
        self.contentView.addSubview(badge)
        badge.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: -badge.bounds.size.height / 2).isActive = true
        badge.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: badge.bounds.size.width / 2).isActive = true
        badge.widthAnchor.constraint(equalToConstant: badge.bounds.size.width).isActive = true
        badge.heightAnchor.constraint(equalToConstant: badge.bounds.size.height).isActive = true
    }
    static let height:CGFloat =  80 + 48 + 2 * CGFloat.padding + CGFloat.padding
    
    private func syncButtonColor(){
        
        let expiredColor = UIColor.init(hex: "#C3C7CA")
        if isExpired {
            actionButton.setTitleColor(expiredColor, for: .normal)
            actionButton.tintColor = expiredColor
        }else{
            actionButton.setTitleColor(self.buttonColor, for: .normal)
            actionButton.tintColor = self.buttonColor
            
        }
    }
    var isExpired = false {
        didSet {
            badge.alpha = isExpired ? 0.0 : 1.0
           syncButtonColor()
        }
    }
    
    static func attributedStringFor(taggedString:String?, isExpired:Bool) -> NSAttributedString {
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
            if isExpired {
                let expiredColor = UIColor.init(hex: "#C3C7CA")
                let font = UIFont.screenshopFont(.hindMedium, size: UIFont.buttonFontSize)
                toReturn.append(NSAttributedString.init(string: String(char), attributes: [
                    .foregroundColor: expiredColor,
                    .backgroundColor:UIColor.clear,
                    .font: font
                    ])
                )
            }else if underlineStyle == NSUnderlineStyle.styleNone.rawValue {
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
        if let taggedString = taggedString {
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
        }
        
        return toReturn
    }
    
}



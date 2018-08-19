//
//  ScreenshotSimilarLooksCollectionViewCell.swift
//  Screenshop
//
//  Created by Jonathan Rose on 8/15/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ScreenshotSimilarLooksCollectionViewCell: UICollectionViewCell {
    var embossedView = EmbossedView()
    var product1ImageView = UIImageView()
    var product2ImageView = UIImageView()
    var product1Title = UILabel()
    var product2Title = UILabel()
    var product1Byline = UILabel()
    var product2Byline = UILabel()
    var isLoaded = false {
        didSet{
            let animationKey = "fadeInAndOut";
            let color = isLoaded ? UIColor.clear : UIColor.lightGray
            [product1ImageView, product2ImageView, product1Title, product2Title, product1Byline, product2Byline].forEach{
                $0.backgroundColor = color
                var animation = $0.layer.animation(forKey: animationKey)
                if !isLoaded {
                    if animation == nil {
                        let a = CABasicAnimation.init(keyPath: #keyPath(CALayer.opacity))
                        a.duration = 1.0
                        a.fromValue = 1.0
                        a.toValue = 0.2
                        a.isRemovedOnCompletion = false;
                        a.autoreverses = true
                        a.repeatCount = HUGE
                        $0.layer.add(a, forKey: animationKey)
                        animation = a
                    }
                    
                }else{
                    $0.layer.removeAnimation(forKey: animationKey)
                }
            }
            
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        embossedView.translatesAutoresizingMaskIntoConstraints = false
        product1ImageView.translatesAutoresizingMaskIntoConstraints = false
        product2ImageView.translatesAutoresizingMaskIntoConstraints = false
        product1Title.translatesAutoresizingMaskIntoConstraints = false
        product2Title.translatesAutoresizingMaskIntoConstraints = false
        product1Byline.translatesAutoresizingMaskIntoConstraints = false
        product2Byline.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(embossedView)
        self.contentView.addSubview(product1ImageView)
        self.contentView.addSubview(product2ImageView)
        self.contentView.addSubview(product1Title)
        self.contentView.addSubview(product2Title)
        self.contentView.addSubview(product1Byline)
        self.contentView.addSubview(product2Byline)

        product1ImageView.contentMode = .scaleAspectFill
        product2ImageView.contentMode = .scaleAspectFill
        embossedView.imageView.contentMode = .scaleAspectFill
        
        product1ImageView.clipsToBounds = true
        product2ImageView.clipsToBounds = true
        embossedView.imageView.clipsToBounds = true
        
        product1ImageView.layer.borderWidth = 1.0
        product1ImageView.layer.borderColor = UIColor.gray9.cgColor
        
        product2ImageView.layer.borderWidth = 1.0
        product2ImageView.layer.borderColor = UIColor.gray9.cgColor

        product1Title.font = UIFont.init(screenshopName: .hindBold, size: 14)
        product2Title.font = UIFont.init(screenshopName: .hindBold, size: 14)
        
        let halfPadding = CGFloat.padding / 2.0
        embossedView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        embossedView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        embossedView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        embossedView.heightAnchor.constraint(equalTo: self.embossedView.widthAnchor, multiplier: CGFloat.goldenRatio).isActive = true
        
        product1ImageView.topAnchor.constraint(equalTo: embossedView.bottomAnchor, constant: .padding).isActive = true
        product1ImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: halfPadding).isActive = true
        product1ImageView.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        product1ImageView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        product2ImageView.topAnchor.constraint(equalTo: product1ImageView.bottomAnchor, constant: .padding).isActive = true
        product2ImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: halfPadding).isActive = true
        product2ImageView.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        product2ImageView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true

        
        product1Title.bottomAnchor.constraint(equalTo: product1ImageView.centerYAnchor, constant:-1).isActive = true
        product1Title.leadingAnchor.constraint(equalTo: product1ImageView.trailingAnchor, constant: halfPadding).isActive = true
        product1Title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: halfPadding).isActive = true
        product1Title.heightAnchor.constraint(greaterThanOrEqualToConstant: 12).isActive = true
        
        product1Byline.topAnchor.constraint(equalTo: product1ImageView.centerYAnchor, constant:1).isActive = true
        product1Byline.leadingAnchor.constraint(equalTo: product1ImageView.trailingAnchor, constant: halfPadding).isActive = true
        product1Byline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: halfPadding ).isActive = true
        product1Byline.heightAnchor.constraint(greaterThanOrEqualToConstant: 12).isActive = true
        
        product2Title.bottomAnchor.constraint(equalTo: product2ImageView.centerYAnchor,  constant:-1).isActive = true
        product2Title.leadingAnchor.constraint(equalTo: product2ImageView.trailingAnchor, constant: halfPadding).isActive = true
        product2Title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: halfPadding).isActive = true
        product2Title.heightAnchor.constraint(greaterThanOrEqualToConstant: 12).isActive = true
        
        product2Byline.topAnchor.constraint(equalTo: product2ImageView.centerYAnchor, constant:1).isActive = true
        product2Byline.leadingAnchor.constraint(equalTo: product2ImageView.trailingAnchor, constant: halfPadding).isActive = true
        product2Byline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: halfPadding).isActive = true
        product2Byline.heightAnchor.constraint(greaterThanOrEqualToConstant: 12).isActive = true
        
        
        
        
    }
    static func cellHeight(for width:CGFloat) -> CGFloat {
        return  width * CGFloat.goldenRatio + CGFloat.padding * 3 + 50 * 2
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

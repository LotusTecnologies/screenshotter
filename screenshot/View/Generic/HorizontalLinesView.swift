//
//  HorizontalLinesView.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class HorizontalLinesView: UIView {
    let label = UILabel()
    let leftLine = UIView()
    let rightLine = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray3
        label.font = .screenshopFont(.hindMedium, size: 16)
        label.textAlignment = .center
        addSubview(label)
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        setupLine(leftLine)
        leftLine.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        leftLine.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -.padding).isActive = true
        
        setupLine(rightLine)
        rightLine.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: .padding).isActive = true
        rightLine.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    private func setupLine(_ lineView: UIView) {
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .cellBorder
        addSubview(lineView)
        lineView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
}

//
//  TextExplanationTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 6/13/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class TextExplanationTableViewCell: UITableViewCell {
    let titleLabel = UILabel()
    let explanationLabel = UILabel()
    
    var hasSelectableAppearance = false {
        didSet {
            syncSelectableAppearance()
        }
    }
    private let selectedIndicatorButton = UIButton()
    private let selectedLabel = UILabel()
    private var selectableAppearanceConstraints: [NSLayoutConstraint] = []
    private var unselectableAppearanceConstraints: [NSLayoutConstraint] = []
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        separatorInset = .zero
        contentView.layoutMargins = UIEdgeInsets(top: .marginY, left: .marginX, bottom: .marginY, right: .marginX)
        selectionStyle = .none
        backgroundView = UIView()
        
        selectedIndicatorButton.translatesAutoresizingMaskIntoConstraints = false
        selectedIndicatorButton.isHidden = !hasSelectableAppearance
        selectedIndicatorButton.setBackgroundImage(UIImage(named: "TextExplanationNormalCheck"), for: .normal)
        selectedIndicatorButton.setBackgroundImage(UIImage(named: "TextExplanationSelectedCheck"), for: .selected)
        selectedIndicatorButton.isUserInteractionEnabled = false
        contentView.addSubview(selectedIndicatorButton)
        selectedIndicatorButton.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        selectedIndicatorButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .gray2
        titleLabel.font = .screenshopFont(.quicksandMedium, size: 22)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.baselineAdjustment = .alignCenters
        contentView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        
        selectableAppearanceConstraints += [
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectedIndicatorButton.leadingAnchor, constant: contentView.layoutMargins.left)
        ]
        unselectableAppearanceConstraints += [
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor)
        ]
        
        selectedLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedLabel.font = .systemFont(ofSize: 14, weight: .light)
        selectedLabel.isHidden = !hasSelectableAppearance
        contentView.addSubview(selectedLabel)
        selectedLabel.topAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor, constant: 8).isActive = true
        selectedLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        explanationLabel.font = .preferredFont(forTextStyle: .body)
        explanationLabel.adjustsFontForContentSizeCategory = true
        explanationLabel.textColor = .gray2
        explanationLabel.numberOfLines = 0
        contentView.addSubview(explanationLabel)
        explanationLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        explanationLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        explanationLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        selectableAppearanceConstraints += [
            explanationLabel.topAnchor.constraint(equalTo: selectedLabel.bottomAnchor, constant: .padding)
        ]
        unselectableAppearanceConstraints += [
            explanationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding)
        ]
        
        syncSelectableAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func syncSelectableAppearance() {
        if hasSelectableAppearance {
            NSLayoutConstraint.deactivate(unselectableAppearanceConstraints)
            NSLayoutConstraint.activate(selectableAppearanceConstraints)
        }
        else {
            NSLayoutConstraint.deactivate(selectableAppearanceConstraints)
            NSLayoutConstraint.activate(unselectableAppearanceConstraints)
        }
        
        selectedIndicatorButton.isHidden = !hasSelectableAppearance
        selectedLabel.isHidden = !hasSelectableAppearance
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        selectedLabel.textColor = selected ? .crazeGreen : .gray8
        selectedLabel.text = selected ? "text_explanation.enabled".localized : "text_explanation.disabled".localized
        selectedIndicatorButton.isSelected = selected
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        backgroundView?.backgroundColor = highlighted ? .cellBackground : .clear
    }
}

//
//  TutorialSlideView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

 @objc public protocol TutorialSlideView {
    func didEnterSlide()
    func willLeaveSlide()
}

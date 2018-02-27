//
//  TutorialSlideView.swift
//  screenshot
//
//  Created by Corey Werner on 1/17/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

typealias TutorialSlideView = UIView & TutorialSlideViewProtocol

protocol TutorialSlideViewProtocol : NSObjectProtocol {
    func didEnterSlide()
    func willLeaveSlide()
}

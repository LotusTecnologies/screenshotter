//
//  LifeCycleProtocol.swift
//  screenshot
//
//  Created by Corey Werner on 9/18/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

@objc protocol ViewControllerLifeCycle: NSObjectProtocol {
    @objc optional func viewControllerDidLoad(_ viewController: UIViewController)
    @objc optional func viewController(_ viewController: UIViewController, willAppear animated: Bool)
    @objc optional func viewController(_ viewController: UIViewController, didAppear animated: Bool)
    @objc optional func viewController(_ viewController: UIViewController, willDisappear animated: Bool)
    @objc optional func viewController(_ viewController: UIViewController, didDisappear animated: Bool)
}

//
//  LifeCycleProtocol.swift
//  screenshot
//
//  Created by Corey Werner on 9/18/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

protocol ViewControllerLifeCycle: NSObjectProtocol {
    func viewControllerDidLoad(_ viewController: UIViewController)
    func viewController(_ viewController: UIViewController, willAppear animated: Bool)
    func viewController(_ viewController: UIViewController, didAppear animated: Bool)
    func viewController(_ viewController: UIViewController, willDisappear animated: Bool)
    func viewController(_ viewController: UIViewController, didDisappear animated: Bool)
}

extension ViewControllerLifeCycle {
    func viewControllerDidLoad(_ viewController: UIViewController) {}
    func viewController(_ viewController: UIViewController, willAppear animated: Bool) {}
    func viewController(_ viewController: UIViewController, didAppear animated: Bool) {}
    func viewController(_ viewController: UIViewController, willDisappear animated: Bool) {}
    func viewController(_ viewController: UIViewController, didDisappear animated: Bool) {}
}

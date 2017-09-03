//
//  RatingFlowController.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/3/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import EggRating

@objc class RatingFlow : NSObject, RatingFlowControllerDelegate {
    static let sharedInstance = RatingFlow()
    
    let controller = RatingFlowController()
    
    func start() {
        controller.delegate = self
        
        if let rvc = UIApplication.shared.keyWindow?.rootViewController {
            controller.prompt(force: true, inViewController: rvc)
        }
    }
    
    // MARK: RatingFlowControllerDelegate
    
    func controller(_ controller: RatingFlowController, didRate rating: RatingFlowController.Rating) {
        if case .InApp = rating {
            print("rated \(rating)")
        } else {
            print("rated on app store!")
        }
    }
    
    func controllerDidCancel(_ controller: RatingFlowController, inPhase phase: RatingFlowController.Phase) {
        let suffix = phase == .AppStore ? " on AppStore" : ""
        print("Ignored rating" + suffix)
    }
}

protocol RatingFlowControllerDelegate : class {
    func controller(_ controller: RatingFlowController, didRate rating: RatingFlowController.Rating)
    func controllerDidCancel(_ controller: RatingFlowController, inPhase phase:RatingFlowController.Phase)
}

class RatingFlowController : NSObject {
    weak var delegate: RatingFlowControllerDelegate?

    enum Rating {
        case InApp(Double)
        case AppStore
    }
    
    enum Phase {
        case Initial
        case AppStore
    }
    
    // MARK: Initialization
    
    override init() {
        super.init()
        
        EggRating.delegate = self
        EggRating.itunesId = "1254964391"
        EggRating.minRatingToAppStore = 4
    }

    // MARK: Public methods
    func prompt(force: Bool = false, inViewController viewController: UIViewController) {
        guard force == false else {
            EggRating.promptRateUs(viewController: viewController)
            return
        }

        EggRating.promptRateUsIfNeeded(viewController: viewController)
    }
}

extension RatingFlowController : EggRatingDelegate {
    func shouldPresentDisadvantageAlert() -> Bool {
        return false
    }
    
    func didRateOnAppStore() {
        delegate?.controller(self, didRate: .AppStore)
    }
    
    func didRate(rating rate: Double) {
        delegate?.controller(self, didRate: .InApp(rate))
    }
    
    func didIgnoreToRate() {
        delegate?.controllerDidCancel(self, inPhase: .Initial)
    }
    
    func didIgnoreToRateOnAppStore() {
        delegate?.controllerDidCancel(self, inPhase: .AppStore)
    }
}

//
//  RatingFlowController.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/3/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import EggRating

class RatingFlow : NSObject, RatingFlowControllerDelegate {
    public static let sharedInstance = RatingFlow(significantEventThreshold: 3)

    private let containerViewControllerClosure: () -> UIViewController?
    
    init(significantEventThreshold threshold: Int = 3, containerViewControllerClosure closure: @escaping () -> UIViewController? = { UIApplication.shared.keyWindow?.rootViewController }) {
        self.containerViewControllerClosure = closure
        self.significantEventThreshold = threshold
        
        super.init()
    }
    
    private static let SignificantEventCountUserDefaultsKey = "\(RatingFlow.self).SignificantEventCount"
    private let significantEventThreshold: Int
    private var significantEventCount:Int {
        get {
            return UserDefaults.standard.integer(forKey: RatingFlow.SignificantEventCountUserDefaultsKey)
        }
        set (newCount) {
            UserDefaults.standard.set(newCount, forKey: RatingFlow.SignificantEventCountUserDefaultsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    fileprivate let controller = RatingFlowController()
    
    func start() {
        controller.delegate = self
    }
    
    func recordSignificantEvent() {
        significantEventCount += 1
        
        if let vc = self.containerViewControllerClosure(), significantEventCount > significantEventThreshold {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { [weak controller, vc] in
                controller?.prompt(inViewController: vc)
                
                self.significantEventCount = 0
            }
        }
    }
    
    // MARK: RatingFlowControllerDelegate
    fileprivate func controller(_ controller: RatingFlowController, didRate rating: RatingFlowController.Rating) {
        if case .InApp = rating {
            AnalyticsManager.track("Rated app", properties: ["rating": "\(rating)"])
        } else {
            AnalyticsManager.track("Rated app on app store")
        }
    }
    
    fileprivate func controllerDidCancel(_ controller: RatingFlowController, inPhase phase: RatingFlowController.Phase) {
        if case .Initial = phase {
            AnalyticsManager.track("Ignored rating in app")
        } else {
            AnalyticsManager.track("Ignored rating on AppStore")
        }
    }
}

fileprivate protocol RatingFlowControllerDelegate : class {
    func controller(_ controller: RatingFlowController, didRate rating: RatingFlowController.Rating)
    func controllerDidCancel(_ controller: RatingFlowController, inPhase phase:RatingFlowController.Phase)
}

fileprivate class RatingFlowController : NSObject {
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
        EggRating.daysUntilPrompt = 1
        EggRating.minRatingToAppStore = 4.5
    }

    // MARK: Operations
    
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

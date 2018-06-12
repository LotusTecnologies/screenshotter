//
//  RatingFlow.swift
//  screenshot
//
//  Created by Jacob Relkin on 9/3/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import EggRating

class RatingFlow : NSObject, RatingFlowControllerDelegate {
    enum Rating {
        case InApp(Double)
        case AppStore
    }
    
    enum Phase {
        case Initial
        case AppStore
    }

    public static let sharedInstance = RatingFlow(significantEventThreshold: 3)

    // Using a closure to allow for immediate initialization of the RatingFlow without a concrete instance of a UIViewController.
    private let containerViewControllerClosure: () -> UIViewController?
    
    init(significantEventThreshold threshold: Int = 3, containerViewControllerClosure closure: @escaping () -> UIViewController? = { UIApplication.shared.keyWindow?.rootViewController }) {
        self.containerViewControllerClosure = closure
        self.significantEventThreshold = threshold
        
        super.init()
    }

    private let significantEventThreshold: Int
    private var significantEventCount:Int {
        get {
            return UserDefaults.standard.integer(forKey: UserDefaultsKeys.significantEventCount)
        }
        set (newCount) {
            UserDefaults.standard.set(newCount, forKey: UserDefaultsKeys.significantEventCount)
            UserDefaults.standard.synchronize()
        }
    }
    
    private var hasSufficientSignificantEvents: Bool {
        return significantEventCount >= significantEventThreshold
    }
    
    fileprivate var controller = RatingFlowController()
    
    // MARK: Public methods
    
    func start() {
        controller.delegate = self
        promptIfNecessary(delay: 3.5)
    }
    
    func recordSignificantEvent() {
        significantEventCount += 1
        
        promptIfNecessary()
    }
    
    // MARK: Private methods
 
    private func promptIfNecessary(delay:Double = 2.5) {
        guard hasSufficientSignificantEvents else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            self.prompt()
        }
    }
    
    private func prompt(force: Bool = false) {
        guard let vc = self.containerViewControllerClosure() else {
            return
        }
        
        controller.prompt(force: force, inViewController: vc)
    }
    
    // MARK: RatingFlowControllerDelegate
    
    fileprivate func controller(_ controller: RatingFlowController, didRate rating: RatingFlow.Rating) {
        if case .InApp(let ratingValue) = rating {
            Analytics.trackRatedApp(rating: "\(ratingValue)")
            
            if ratingValue < EggRating.minRatingToAppStore {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: dismiss)
            }
        } else {
            Analytics.trackRatedAppOnAppStore()
            dismiss()
        }
    }
    
    fileprivate func controllerDidCancel(_ controller: RatingFlowController, inPhase phase: RatingFlow.Phase) {
        if case .Initial = phase {
            Analytics.trackIgnoredRatingInApp()
        } else {
            Analytics.trackIgnoredRatingOnAppStore()
        }
        
        dismiss()
    }
    
    private func dismiss() {
        containerViewControllerClosure()?.dismiss(animated: false, completion: nil)
    }
}

fileprivate protocol RatingFlowControllerDelegate : class {
    func controller(_ controller: RatingFlowController, didRate rating: RatingFlow.Rating)
    func controllerDidCancel(_ controller: RatingFlowController, inPhase phase:RatingFlow.Phase)
}

fileprivate class RatingFlowController : NSObject {
    weak var delegate: RatingFlowControllerDelegate?
    
    // MARK: Initialization
    
    override init() {
        super.init()

        EggRating.delegate = self
        EggRating.titleLabelText = "Rate \(Bundle.main.infoDictionary!["CFBundleDisplayName"] ?? "Craze")"
        EggRating.itunesId = "1254964391"
        EggRating.daysUntilPrompt = 1 // 1 day until first prompt
        EggRating.remindPeriod = 3 // remind every 3 days thereafter
        EggRating.minRatingToAppStore = 4
    }

    // MARK: Operations
    
    func prompt(force: Bool = false, inViewController viewController: UIViewController) {
        guard force == false else {
            EggRating.promptRateUs(in: viewController)
            return
        }

        EggRating.promptRateUsIfNeeded(in: viewController)
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

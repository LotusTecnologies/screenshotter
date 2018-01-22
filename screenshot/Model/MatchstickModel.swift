//
//  MatchstickModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 1/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit

class MatchstickModel: NSObject {
    
    public static let shared = MatchstickModel()

    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.matchsticks.serial")
    let processingQ = DispatchQueue.global(qos: .utility)
    var isFetchingNext = false
    
    @objc func fetchNextIfBelowWatermark() {
        let lowWatermark = 10
        let dataModel = DataModel.sharedInstance
        serialQ.promise { _ -> Promise<Bool> in
            guard self.isFetchingNext == false else {
                // Not really an error. Just an easy way to cancel further processing.
                let error = NSError(domain: "Craze", code: 23, userInfo: [NSLocalizedDescriptionKey : "Already fetching next matchsticks."])
                return Promise(error: error)
            }
            self.isFetchingNext = true
            return Promise(value: true)
            }.then(on: processingQ) { _ -> Promise<Int> in
                return Promise { fulfill, reject in
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        let matchstickCount = dataModel.countMatchsticks(managedObjectContext: managedObjectContext)
                        if matchstickCount < lowWatermark {
                            fulfill(matchstickCount)
                        } else {
                            // Not really an error. Just an easy way to cancel further processing.
                            let error = NSError(domain: "Craze", code: 24, userInfo: [NSLocalizedDescriptionKey : "Good. We have enough, \(matchstickCount) matchsticks."])
                            reject(error)
                        }
                    }
                }
            }.then(on: processingQ) { matchstickCount -> Promise<NSDictionary> in
                return NetworkingPromise.nextMatchsticks()
            }.then(on: processingQ) { dict -> Void in
                if let matchsticksArray = dict["screenshots"] as? [[String : Any]] {
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        // Reverse order received, so we can always take latest saved.
                        for matchstick in matchsticksArray {
                            if let remoteId = matchstick["id"] as? String,
                                let imageUrl = matchstick["image"] as? String,
                                let syteJson = matchstick["syteJson"] as? String {
                                let _ = dataModel.saveMatchstick(managedObjectContext: managedObjectContext,
                                                                 remoteId: remoteId,
                                                                 imageUrl: imageUrl,
                                                                 syteJson: syteJson)
                                print("fetchNextIfBelowWatermark saveMatchstick remoteId:\(remoteId)  imageUrl:\(imageUrl)")
                                self.processingQ.async {
                                    self.fetchImageData(imageUrl: imageUrl)
                                }
                            } else {
                                print("Could not parse matchstick:\(matchstick)")
                            }
                        }
                        dataModel.saveMoc(managedObjectContext: managedObjectContext)
                        if let token = dict["next"] as? String {
                            UserDefaults.standard.set(token, forKey: UserDefaultsKeys.matchsticksSyncToken)
                        }
                        print("fetchNextIfBelowWatermark saveMoc matchsticksArray.count:\(matchsticksArray.count)")
                    }
                } else {
                    print("fetchNextIfBelowWatermark could not parse dict:\(dict)")
                }
            }.always(on: self.serialQ) {
                self.isFetchingNext = false
            }.catch(on: processingQ) { error in
                print("fetchNextIfBelowWatermark catch error:\(error)")
        }
    }
    
    @objc func fetchImageData(imageUrl: String) {
        let dataModel = DataModel.sharedInstance
        NetworkingPromise.downloadImageData(urlString: imageUrl)
            .then(on: processingQ) { imageData -> Void in
                dataModel.performBackgroundTask { (managedObjectContext) in
                    dataModel.addImageDataToMatchstick(managedObjectContext: managedObjectContext, imageUrl: imageUrl, imageData: imageData)
                    print("fetchImageData addImageDataToMatchstick imageUrl:\(imageUrl)")
                }
            }.catch(on: processingQ) { error in
                print("fetchImageData catch error:\(error)")
        }
    }

}


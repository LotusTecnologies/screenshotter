//
//  ClarifaiModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import Clarifai_Apple_SDK
import PromiseKit

class ClarifaiModel: NSObject {

    enum ImageClassification {
        case human, furniture, unrecognized
    }
    
    public static let sharedInstance = ClarifaiModel()
    
    var isModelDownloaded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isModelDownloaded)

    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(modelDownloadStarted), name: Notification.Name.CAIWillFetchModel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelDownloadFinished), name: Notification.Name.CAIDidFetchModel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelAvailable), name: Notification.Name.CAIModelDidBecomeAvailable, object: nil)
        Clarifai.sharedInstance().start(apiKey: "b0c68b58001546afa6e9cbe0f8f619b2")
        if !isModelDownloaded {
            kickoffModelDownload()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func modelDownloadStarted() {
        AnalyticsTrackers.standard.track(.startedDownloadingClarifaiModel)
    }
    
    func modelDownloadFinished() {
        modelDownloaded()
        AnalyticsTrackers.standard.track(.finishedDownloadingClarifaiModel)
    }
    
    func modelAvailable() {
        modelDownloaded()
    }
    
    func modelDownloaded() {
        isModelDownloaded = true
        UserDefaults.standard.set(isModelDownloaded, forKey: UserDefaultsKeys.isModelDownloaded)
    }
    
    func kickoffModelDownload() {
        if let image = UIImage.init(named: "ControlX") {
            localPredict(image: image) { (outputs: [Output]?, error: Error?) in
                // Don't care about the results, just kick off prepping the model.
            }
        }
    }
    
    func localPredict(image: UIImage, completionHandler: @escaping ([Output]?, Error?) -> Void) {
        let localImage = Image(image: image)
        let dataAsset = DataAsset(image: localImage)
        let input = Input(dataAsset: dataAsset)
        let generalModel = Clarifai.sharedInstance().generalModel
        generalModel.predict([input], completionHandler: completionHandler)
    }
    
    func localClarifaiOutputs(image: UIImage) -> Promise<[Output]> {
        return Promise { fulfill, reject in
            localPredict(image: image) { (outputs: [Output]?, error: Error?) in
                if let error = error {
                    reject(error)
                } else if let outputs = outputs {
                    fulfill(outputs)
                } else {
                    let emptyError = NSError(domain: "Craze", code: 1, userInfo: [NSLocalizedDescriptionKey : "Clarifai returned no outputs"])
                    reject(emptyError)
                }
            }
        }
    }
    
    func classify(image: UIImage) -> Promise<(ImageClassification, UIImage)> {
        return localClarifaiOutputs(image: image).then { outputs -> Promise<(ImageClassification, UIImage)> in
            let conceptNamesArray = outputs.flatMap({$0.dataAsset.concepts}).flatMap({$0}).flatMap({$0.name})
            let conceptNames = Set<String>(conceptNamesArray)

            if !conceptNames.isDisjoint(with: ["woman", "man", "child"]) {
                return Promise(value: (.human, image))
            } else if !conceptNames.isDisjoint(with: ["furniture", "chair", "table", "desk", "sofa", "couch", "rug", "drapes", "bookshelf"]) {
                return Promise(value: (.furniture, image))
            } else {
                return Promise(value: (.unrecognized, image))
            }
        }
    }
    
}

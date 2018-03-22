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
        func shortString() -> String? {
            switch self {
            case .human:
                return "h"
            case .furniture:
                return "f"
            default:
                return nil
            }
        }
    }
    
    public static let sharedInstance = ClarifaiModel()
    
    var isModelDownloaded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isModelDownloaded)
    var didClassifyAtLeastOneImage = false
    private var modelDownloadPromise : Promise<Bool>?
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(modelDownloadStarted), name: Notification.Name.CAIWillFetchModel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelDownloadFinished), name: Notification.Name.CAIDidFetchModel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelAvailable), name: Notification.Name.CAIModelDidBecomeAvailable, object: nil)
        Clarifai.sharedInstance().start(apiKey: "b0c68b58001546afa6e9cbe0f8f619b2")
    }
    
    func kickoffModelDownload() -> Promise<Bool> {
        if let promise = self.modelDownloadPromise {
            return promise
        }
        
        let promise:Promise<Bool> = {
            if !isModelDownloaded,  let image = UIImage.init(named: "ControlX") {
                return self.classify(image: image).then(execute: { (i) -> Promise<Bool> in
                    return Promise(value: true)
                })
            }else{
                return Promise.init(value: true)
            }
        }()
    
        self.modelDownloadPromise = promise
        return promise
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
    
    var clarifaiClassifyQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "clarifai Classify Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    func classify(image: UIImage) -> Promise<ImageClassification> {
        return Promise { fulfill, reject in
            DispatchQueue.global(qos: .background).async {
                let timeout = self.didClassifyAtLeastOneImage ? 1.0 : 25   // give first one a long time to load model
                self.didClassifyAtLeastOneImage = true
                self.clarifaiClassifyQueue.addOperation(AsyncOperation.init(timeout: timeout, completion: { (completeOperation) in
                    let localImage = Image(image: image)
                    let dataAsset = DataAsset(image: localImage)
                    let input = Input(dataAsset: dataAsset)
                    let generalModel = Clarifai.sharedInstance().generalModel
                    generalModel.predict([input]) { (outputs: [Output]?, error: Error?) in
                        if let error = error {
                            reject(error)
                        } else if let outputs = outputs {
                            let conceptNamesArray = outputs.flatMap({$0.dataAsset.concepts}).flatMap({$0}).flatMap({$0.name})
                            let conceptNames = Set<String>(conceptNamesArray)
                            
                            if !conceptNames.isDisjoint(with: ["woman", "man", "child", "people", "person", "apparel","garment", "dress", "jewelry", "fashion"  ]) {
                                fulfill(.human)
                            } else if !conceptNames.isDisjoint(with: ["furniture", "chair", "table", "desk", "sofa", "couch", "rug", "drapes", "bookshelf"]) {
                                fulfill(.furniture)
                            } else {
                                fulfill(.unrecognized)
                            }
                            
                        } else {
                            let emptyError = NSError(domain: "Craze", code: 1, userInfo: [NSLocalizedDescriptionKey : "Clarifai returned no outputs"])
                            reject(emptyError)
                        }
                        completeOperation()
                    }
                }))
            }
        }
    }
    
}

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

    public static let sharedInstance = ClarifaiModel()
    
    public static func setup() {
        let _ = ClarifaiModel.sharedInstance
    }

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
        NSLog("modelDownloadStarted")
        track("started downloading Clarifai model")
    }
    
    func modelDownloadFinished() {
        NSLog("modelDownloadFinished")
        isModelDownloaded = true
        UserDefaults.standard.set(isModelDownloaded, forKey: UserDefaultsKeys.isModelDownloaded)
        track("finished downloading Clarifai model")
    }
    
    func modelAvailable() {
        NSLog("modelAvailable")
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
        guard isModelDownloaded else {
            let error = NSError(domain: "Craze", code: 19, userInfo: [NSLocalizedDescriptionKey : "Clarifai model unavailable"])
            return Promise(error: error)
        }
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
    
    func isFashion(image: UIImage) -> Promise<(Bool, UIImage)> {
        return localClarifaiOutputs(image: image).then { outputs -> Promise<(Bool, UIImage)> in
            var isFashion = false
            var j: Int = 0
            for output in outputs {
                guard let concepts = output.dataAsset.concepts else {
                    continue
                }
                for concept in concepts {
                    switch concept.name {
                    case "woman", "man", "fashion", "beauty", "glamour", "dress", "jewelry", "garment", "apparel", "shirt", "jacket", "vogue", "ensemble":
                        isFashion = true
                    default:
                        break
                    }
                    j += 1
                    //print("\(j)  \(concept.score * 100.0)  \(concept.name ?? "-")")
                }
            }
            print("isFashion: \(isFashion ? "YES" : "NO")")
            return Promise(value: (isFashion, image))
        }
    }
    
    
}

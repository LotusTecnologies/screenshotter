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

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(modelDownloadStarted), name: Notification.Name.CAIWillDownloadGeneralModel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modelDownloadFinished), name: Notification.Name.CAIDidDownloadGeneralModel, object: nil)
        Clarifai.sharedInstance().start(apiKey: "b0c68b58001546afa6e9cbe0f8f619b2")
        if UserDefaults.standard.object(forKey: UserDefaultsDateInstalled) == nil {
            if let image = UIImage.init(named: "ControlX") {
                let _ = localClarifaiOutputs(image: image)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func modelDownloadStarted() {
        NSLog("modelDownloadStarted")
        AnalyticsManager.track("started downloading Clarifai model")
    }
    
    func modelDownloadFinished() {
        NSLog("modelDownloadFinished")
        AnalyticsManager.track("finished downloading Clarifai model")
    }
    
    func localClarifaiOutputs(image: UIImage) -> Promise<[Output]> {
        let localImage = Image(image: image)
        let dataAsset = DataAsset(image: localImage)
        let input = Input(dataAsset: dataAsset)
        let generalModel = Clarifai.sharedInstance().generalModel
        return Promise { fulfill, reject in
            generalModel.predict([input]) { (outputs: [Output]?, error: Error?) in
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
                    case "woman", "man", "fashion", "beauty", "glamour", "dress":
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

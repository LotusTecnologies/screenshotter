//
//  AssetSyncModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/9/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import MobileCoreServices // kUTTypeImage

class AssetSyncModel: NSObject {

    public static let sharedInstance = AssetSyncModel()

    let imageMediaType = kUTTypeImage as String;
    
    func uploadLastScreenshot(completionHandler: ((_ success: Bool) -> Void)?) {
        let matchModel = MatchModel.shared()!
        let dataModel = DataModel.sharedInstance
        let moc = dataModel.adHocMoc()
        matchModel.logClarifaiSyteInitial({ (response: URLResponse, responseObject: Any?, error: Error?) in
            guard error == nil,
                let responseObjectDict = responseObject as? [String : AnyObject],
                let uploadedURLString = responseObjectDict.keys.first,
                let shoppables = responseObjectDict[uploadedURLString] as? [[String : AnyObject]],
                shoppables.count > 0,
                let screenshot = dataModel.lastSavedScreenshot(managedObjectContext: moc) else {
                    print("AssetSyncModel uploadLastScreenshot error:\(error)")
                    completionHandler?(false)
                    return
            }
            print("AssetSyncModel response:\(response)\nresponseObject:\(responseObject ?? ""))")
            var order: Int16 = 0
            for shoppable in shoppables {
                guard let b0 = shoppable["b0"] as? [Any],
                    b0.count >= 2,
                    let b1 = shoppable["b1"] as? [Any],
                    b1.count >= 2,
                    let b0x = b0[0] as? Double,
                    let b0y = b0[1] as? Double,
                    let b1x = b1[0] as? Double,
                    let b1y = b1[1] as? Double else {
                        print("AssetSyncModel error parsing b0, b1")
                        continue
                }
                let label = shoppable["label"] as? String
                let offersURL = shoppable["offersURL"] as? String
                print("b0x:\(b0x)  b0y:\(b0y)  b1x:\(b1x)  b1y:\(b1y)")
                let _ = dataModel.saveShoppable(managedObjectContext: moc,
                                                screenshot: screenshot,
                                                order: order,
                                                label: label,
                                                offersURL: offersURL,
                                                b0x: b0x,
                                                b0y: b0y,
                                                b1x: b1x,
                                                b1y: b1y)
                order += 1
            }
            completionHandler?(true)
        })
    }

}

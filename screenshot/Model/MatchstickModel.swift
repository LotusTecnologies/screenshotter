//
//  MatchstickModel.swift
//  screenshot
//
//  Created by Gershon Kagan on 1/18/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit
protocol MatchstickModel {
    func prepareMatchsticks()
    func fetchNextIfBelowWatermark()
}

class RecombeeMatchstickModel: NSObject, MatchstickModel {
    func prepareMatchsticks() {
        NetworkingPromise.sharedInstance.createRecombeeUser(userId: AnalyticsUser.current.identifier).then { (dict) -> Void in
            print("dict :\(dict)")
            
            
            }.catch { (error) in
                print("error :\(error)")
        }
        serialQ.async {
            if self.isFetchingNext {
                print("prepareMatchsticks is already fetching next matchsticks. What??")
            }
            self.isFetchingNext = true
            self.fetchMissingImages() // Don't call fetchMissingImages after fetchNextWorkhorse, or its images could be fetched twice
            self.fetchNextWorkhorse()
        }
    }
    
    public func fetchNextIfBelowWatermark() {
        serialQ.async {
            guard self.isFetchingNext == false else {
                return
            }
            self.isFetchingNext = true
            self.fetchNextWorkhorse()
        }
    }
    func fetchNextWorkhorse() {
        let userId = AnalyticsUser.current.identifier
        var params:[String:Any] = [:]
        NetworkingPromise.sharedInstance.recombeeRequest(path: "recomms/users/\(userId)/items/", method: "GET", params: params)
        
    }
    public static let shared = RecombeeMatchstickModel()
    var downloadMatchsitckQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download matchsticks Queue"
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
    
    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.matchsticks.serial")
    let processingQ = DispatchQueue.global(qos: .utility)
    private(set) var isFetchingNext = false
    
    func fetchMissingImages() {
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            let imageUrls = dataModel.retrieveMatchstickImageUrlsWithNoData(managedObjectContext: managedObjectContext)
            for imageUrl in imageUrls {
                self.processingQ.async {
                    self.fetchImageData(imageUrl: imageUrl)
                }
            }
        }
    }
    
    func fetchImageData(imageUrl: String) {
        self.downloadMatchsitckQueue.addOperation(AsyncOperation.init(timeout: 90.0) { (completed) in
            NetworkingPromise.sharedInstance.downloadImageData(urlString: imageUrl)
                .then(on: self.processingQ) { imageData -> Void in
                    DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
                        DataModel.sharedInstance.addImageDataToMatchstick(managedObjectContext: managedObjectContext, imageUrl: imageUrl, imageData: imageData)
                        completed()
                    }
                }.catch(on: self.processingQ) { error in
                    if let err = error as? PMKURLError {
                        switch err {
                        case let .badResponse(request, data, response):
                            let errorString: String
                            let dataCount: Int
                            if let data = data {
                                errorString = String(data: data, encoding: .utf8) ?? "-"
                                dataCount = data.count
                            } else {
                                errorString = "-"
                                dataCount = 0
                            }
                            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                            print("fetchImageData specific catch badResponse data count:\(dataCount)  statusCode:\(statusCode)  errorString:\(errorString)  request:\(request)")
                            let dataModel = DataModel.sharedInstance
                            dataModel.performBackgroundTask { (managedObjectContext) in
                                dataModel.deleteMatchstick(managedObjectContext: managedObjectContext, imageUrl: imageUrl)
                            }
                        case let .invalidImageData(request, data):
                            print("fetchImageData specific catch invalidImageData data count:\(data.count)  request:\(request)")
                        case let .stringEncoding(request, data, response):
                            let errorString: String
                            if let dataString = String(data: data, encoding: .utf8) {
                                errorString = dataString
                            } else {
                                errorString = "-"
                            }
                            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                            print("fetchImageData specific catch stringEncoding data count:\(data.count)  statusCode:\(statusCode)  errorString:\(errorString)  request:\(request)")
                        }
                    } else {
                        print("fetchImageData catch error:\(error)")
                    }
                    completed()
            }
            
        })
    }

}

class AWSMatchstickModel: NSObject, MatchstickModel {
    
    public static let shared = AWSMatchstickModel()
    var downloadMatchsitckQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download matchsticks Queue"
        queue.maxConcurrentOperationCount = 2
        return queue
    }()

    let serialQ = DispatchQueue(label: "io.crazeapp.screenshot.matchsticks.serial")
    let processingQ = DispatchQueue.global(qos: .utility)
    private(set) var isFetchingNext = false
    
    public func prepareMatchsticks() {
        NetworkingPromise.sharedInstance.createRecombeeUser(userId: AnalyticsUser.current.identifier).then { (dict) -> Void in
            print("dict :\(dict)")
            
            
            }.catch { (error) in
                print("error :\(error)")
        }
        serialQ.async {
            if self.isFetchingNext {
                print("prepareMatchsticks is already fetching next matchsticks. What??")
            }
            self.isFetchingNext = true
            self.fetchMissingImages() // Don't call fetchMissingImages after fetchNextWorkhorse, or its images could be fetched twice
            self.fetchNextWorkhorse()
        }
        
    }
    
    public func fetchNextIfBelowWatermark() {
        serialQ.async {
            guard self.isFetchingNext == false else {
                return
            }
            self.isFetchingNext = true
            self.fetchNextWorkhorse()
        }
    }
    
    func fetchNextWorkhorse() {
        let dataModel = DataModel.sharedInstance
        dataModel.nextMatchsticksIfNeeded()
            .then(on: processingQ) { matchstickCount -> Promise<NSDictionary> in
                return NetworkingPromise.sharedInstance.nextMatchsticks()
            }.then(on: processingQ) { dict -> Void in
                if let matchsticksArray = dict["screenshots"] as? [[String : Any]] {
                    dataModel.performBackgroundTask { (managedObjectContext) in
                        // Reverse order received, so we can always take latest saved.
                        for matchstick in matchsticksArray {
                            if let remoteId = matchstick["id"] as? String,
                                let imageUrl = matchstick["image"] as? String,
                                let syteJson = matchstick["syteJson"] as? String {
                                let trackingInfo = matchstick["trackingInfo"] as? String
                                let _ = dataModel.saveMatchstick(managedObjectContext: managedObjectContext,
                                                                 remoteId: remoteId,
                                                                 imageUrl: imageUrl,
                                                                 syteJson: syteJson,
                                                                 trackingInfo:trackingInfo)
                                self.processingQ.async {
                                    self.fetchImageData(imageUrl: imageUrl)
                                }
                            } else {
                                print("Could not parse matchstick:\(matchstick)")
                            }
                        }
                        managedObjectContext.saveIfNeeded()
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
    
    func fetchMissingImages() {
        let dataModel = DataModel.sharedInstance
        dataModel.performBackgroundTask { (managedObjectContext) in
            let imageUrls = dataModel.retrieveMatchstickImageUrlsWithNoData(managedObjectContext: managedObjectContext)
            for imageUrl in imageUrls {
                self.processingQ.async {
                    self.fetchImageData(imageUrl: imageUrl)
                }
            }
        }
    }
    
    func fetchImageData(imageUrl: String) {
        self.downloadMatchsitckQueue.addOperation(AsyncOperation.init(timeout: 90.0) { (completed) in
            NetworkingPromise.sharedInstance.downloadImageData(urlString: imageUrl)
                .then(on: self.processingQ) { imageData -> Void in
                    DataModel.sharedInstance.performBackgroundTask { (managedObjectContext) in
                        DataModel.sharedInstance.addImageDataToMatchstick(managedObjectContext: managedObjectContext, imageUrl: imageUrl, imageData: imageData)
                        completed()
                    }
                }.catch(on: self.processingQ) { error in
                    if let err = error as? PMKURLError {
                        switch err {
                        case let .badResponse(request, data, response):
                            let errorString: String
                            let dataCount: Int
                            if let data = data {
                                errorString = String(data: data, encoding: .utf8) ?? "-"
                                dataCount = data.count
                            } else {
                                errorString = "-"
                                dataCount = 0
                            }
                            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                            print("fetchImageData specific catch badResponse data count:\(dataCount)  statusCode:\(statusCode)  errorString:\(errorString)  request:\(request)")
                            let dataModel = DataModel.sharedInstance
                            dataModel.performBackgroundTask { (managedObjectContext) in
                                dataModel.deleteMatchstick(managedObjectContext: managedObjectContext, imageUrl: imageUrl)
                            }
                        case let .invalidImageData(request, data):
                            print("fetchImageData specific catch invalidImageData data count:\(data.count)  request:\(request)")
                        case let .stringEncoding(request, data, response):
                            let errorString: String
                            if let dataString = String(data: data, encoding: .utf8) {
                                errorString = dataString
                            } else {
                                errorString = "-"
                            }
                            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                            print("fetchImageData specific catch stringEncoding data count:\(data.count)  statusCode:\(statusCode)  errorString:\(errorString)  request:\(request)")
                        }
                    } else {
                        print("fetchImageData catch error:\(error)")
                    }
                    completed()
            }
            
        })
    }

}


//
//  ClarifaiLocalPredictOperation.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import Clarifai_Apple_SDK

class ClarifaiLocalPredictOperation: Operation {
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    func executing(_ executing: Bool) {
        _executing = executing
    }
    
    func finish(_ finished: Bool) {
        _finished = finished
    }
    
    private let image: UIImage
    private let completion: ([Output]?, Error?) -> ()

    init(withImage:UIImage, completion:@escaping ([Output]?, Error?) -> Void) {
        self.image = withImage
        self.completion = completion
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        let localImage = Image(image: self.image)
        let dataAsset = DataAsset(image: localImage)
        let input = Input(dataAsset: dataAsset)
        let generalModel = Clarifai.sharedInstance().generalModel
        generalModel.predict([input]) { (outputs, error) in
            self.completion(outputs, error)
            self.executing(false)
            self.finish(true)
        }
    }
    
}



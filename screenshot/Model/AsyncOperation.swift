//
//  AsyncOperation.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class AsyncOperation: Operation {
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
    
    private let executionBlock: ((@escaping() -> ()) -> ())
    private let timeout:TimeInterval?
   
    init(timeout:TimeInterval?, completion:@escaping ((@escaping() -> ()) -> ())) {
        self.executionBlock = completion
        self.timeout = timeout
    }
    
    private func finishedExecuting(){
        self.executing(false)
        self.finish(true)
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        
        executing(true)
        let date = Date()

        if let timeout = timeout {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + timeout, execute: {
                if !self.isFinished {
                    self.executing(false)
                    self.finish(true)
//                    print("operation completed - timeout \(date.timeIntervalSinceNow)")

                }
            })
        }
        self.executionBlock({
            if !self.isFinished {
                self.executing(false)
                self.finish(true)
//                print("operation completed \(date.timeIntervalSinceNow)")
                
            }else{
//                print("operation called completion after already complted timeout: \(date.timeIntervalSinceNow) \(self.timeout)")
            }
        })
    }
}

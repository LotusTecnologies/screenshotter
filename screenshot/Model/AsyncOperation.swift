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
    init(withBlock:@escaping ((@escaping() -> ()) -> ())) {
        self.executionBlock = withBlock
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
        self.executionBlock({
            self.executing(false)
            self.finish(true)
        })
    }
}

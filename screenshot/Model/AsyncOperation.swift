//
//  AsyncOperation.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let AsyncOperationTagMonitorCenterDidChange = Notification.Name(rawValue: "io.crazeapp.screenshot.AsyncOperationTagMonitorCenterDidChange")
}
protocol AsyncOperationMonitorDelegate : class {
    func asyncOperationMonitorDidStart(_ monitor:AsyncOperationMonitor)
    func asyncOperationMonitorDidStop(_ monitor:AsyncOperationMonitor)
}

class AsyncOperationMonitor {
    weak var delegate:AsyncOperationMonitorDelegate?
    private(set) var didStart = false
    let tags:[AsyncOperationTag]
    
    init(tags:[AsyncOperationTag], delegate:AsyncOperationMonitorDelegate) {
        self.tags = tags
        self.delegate = delegate
        self.didStart = self.calculateDidStart()
        
        NotificationCenter.default.addObserver(self, selector: #selector(asyncOperationDidChange(_:)), name: .AsyncOperationTagMonitorCenterDidChange, object: nil)
    }
    private func calculateDidStart() -> Bool{
        var count = 0
        self.tags.forEach { count +=  AsyncOperationMonitorCenter.shared.countFor(tag: $0) }
        
        return count > 0
    }
    @objc private func asyncOperationDidChange(_ notification:Notification){
        if let userInfo = notification.userInfo, let changedTags = userInfo["tags"] as? [AsyncOperationTag] {
            var didChangeTag = false
            for t  in changedTags {
                if tags.contains(t) {
                    didChangeTag = true
                }
            }
            if didChangeTag {
                let oldValue = self.didStart
                let newValue = calculateDidStart()
                if oldValue != newValue {
                    DispatchQueue.main.async {
                        self.didStart = newValue
                        if newValue {
                            self.delegate?.asyncOperationMonitorDidStart(self)
                        }else{
                            self.delegate?.asyncOperationMonitorDidStop(self)
                        }
                    }
                }
            }
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

class AsyncOperationMonitorCenter {
    static let shared = AsyncOperationMonitorCenter()
    
    private var runningTags:[AsyncOperationTag.TagType:[String:Int]] = [:]
    
    private func typeDict(_ type:AsyncOperationTag.TagType) -> [String:Int] {
        if let dict = self.runningTags[type]{
            return dict
        }else{
            let dict:[String:Int] = [:]
            self.runningTags[type] = dict
            return dict
        }
    }
    
    public func registerStarted(tags:[AsyncOperationTag]) {
        var startedTags:[AsyncOperationTag] = []
        
        tags.forEach { (tag) in
            var categoryDict:[String:Int] = self.typeDict(tag.type)
            
            var count = categoryDict[tag.value, default:0]
            if count == 0 {
                startedTags.append(tag)
            }
            count = count + 1
            
            self.runningTags[tag.type]?[tag.value] = count
        }
        
        self.tagStarted(startedTags)
    }
    
    public func registerStopped(tags:[AsyncOperationTag]) {
        var endedTags:[AsyncOperationTag] = []
        
        tags.forEach { (tag) in
            var categoryDict:[String:Int] = self.typeDict(tag.type)
            
            var count = categoryDict[tag.value, default:1] // getting 1 at this point is a bug!
            count = count - 1
            self.runningTags[tag.type]?[tag.value] = count
            
            if count == 0 {
                endedTags.append(tag)
            }
            
        }
        self.tagsEnded(endedTags)
    }
    
    public func countFor(tag:AsyncOperationTag) -> Int{
        let categoryDict:[String:Int] = self.typeDict(tag.type)
        let count = categoryDict[tag.value] ?? 0
        return count
        
    }
    
    func tagsEnded(_ tags:[AsyncOperationTag]) {
        NotificationCenter.default.post(name: .AsyncOperationTagMonitorCenterDidChange, object: nil, userInfo: ["tags":tags])
    }
    
    func tagStarted(_ tags:[AsyncOperationTag]) {
        NotificationCenter.default.post(name: .AsyncOperationTagMonitorCenterDidChange, object: nil, userInfo: ["tags":tags])
    }
    
}


class AsyncOperationTag: Equatable {
    enum TagType : String {
        case assetId
        case shoppableId
    }
    var type:TagType
    var value:String
    
    init(type:TagType, value:String) {
        self.type = type
        self.value = value
    }
    
    public static func == (lhs: AsyncOperationTag, rhs: AsyncOperationTag) -> Bool{
        return lhs.type == rhs.type && lhs.value == lhs.value
    }
    
}
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
    
    private var executionBlock: ((@escaping() -> ()) -> ())?
    private let timeout:TimeInterval?
    private let tags:[AsyncOperationTag]
    
    convenience init(timeout:TimeInterval?, completion:@escaping ((@escaping() -> ()) -> ())) {
        self.init(timeout: timeout, tags: [], completion: completion)
    }
    
    init(timeout:TimeInterval?, tags:[AsyncOperationTag], completion:@escaping ((@escaping() -> ()) -> ())) {
        self.tags = tags
        self.executionBlock = completion
        self.timeout = timeout
        super.init()
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
        //        let date = Date()
        AsyncOperationMonitorCenter.shared.registerStarted(tags: self.tags)
        if let timeout = timeout {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + timeout, execute: {
                if !self.isFinished {
                    self.executing(false)
                    self.finish(true)
                    AsyncOperationMonitorCenter.shared.registerStopped(tags: self.tags)
                    //print("operation completed - timeout \(date.timeIntervalSinceNow)")
                }
            })
        }
        if let block = self.executionBlock {
            block({
                if !self.isFinished {
                    self.executing(false)
                    self.finish(true)
                    AsyncOperationMonitorCenter.shared.registerStopped(tags: self.tags)
                    //print("operation completed \(date.timeIntervalSinceNow)")
                    
                }else{
                    //print("operation called completion after already complted timeout: \(date.timeIntervalSinceNow) \(self.timeout)")
                }
            })
        }else{
            print("CRITICAL bug in asyncOperation")
            self.executing(false)
            self.finish(true)
            AsyncOperationMonitorCenter.shared.registerStopped(tags: self.tags)
        }
        self.executionBlock = nil
    }
}

extension AsyncOperation {
    convenience init(timeout:TimeInterval?, assetId:String?, shoppableId:String?, completion:@escaping ((@escaping() -> ()) -> ())) {
        var tags:[AsyncOperationTag] = []
        if let assetId = assetId {
            tags.append(AsyncOperationTag.init(type: .assetId, value: assetId))
        }
        if let shoppableId = shoppableId {
            tags.append(AsyncOperationTag.init(type: .shoppableId, value: shoppableId))
        }
        self.init(timeout: timeout, tags: tags, completion: completion)
    }
}

extension AsyncOperationMonitor {
    convenience init(assetId:String?, shoppableId:String?, delegate:AsyncOperationMonitorDelegate) {
        var tags:[AsyncOperationTag] = []
        if let assetId = assetId {
            tags.append(AsyncOperationTag.init(type: .assetId, value: assetId))
        }
        if let shoppableId = shoppableId {
            tags.append(AsyncOperationTag.init(type: .shoppableId, value: shoppableId))
        }
        self.init(tags: tags, delegate: delegate)
    }
    
}


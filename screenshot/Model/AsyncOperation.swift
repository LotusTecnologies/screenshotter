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
    let queueUUIDs:[UUID]
    init(tags:[AsyncOperationTag], queues:[AsyncOperationQueue], delegate:AsyncOperationMonitorDelegate) {
        self.tags = tags
        self.delegate = delegate
        self.queueUUIDs = queues.map{ $0.uuid }
        self.didStart = self.calculateDidStart()

        NotificationCenter.default.addObserver(self, selector: #selector(asyncOperationDidChange(_:)), name: .AsyncOperationTagMonitorCenterDidChange, object: nil)
    }
    
    private func calculateDidStart() -> Bool{
        var count = 0
        self.tags.forEach { (tag) in
            self.queueUUIDs.forEach({ (uuid) in
                count +=  AsyncOperationMonitorCenter.shared.countFor(tag: tag, queue: uuid)
            })
        }
        return count > 0
    }
    @objc private func asyncOperationDidChange(_ notification:Notification){
        if let userInfo = notification.userInfo, let changedTags = userInfo["tags"] as? [AsyncOperationTag], let queueUUID = userInfo["queueUUID"] as? UUID {
            if self.queueUUIDs.contains(queueUUID) {
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
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

class AsyncOperationMonitorCenter {
    static let shared = AsyncOperationMonitorCenter()
    
    private var runningTags:[UUID:[AsyncOperationTag.TagType:[String:Int]]] = [:]
    
    
    
    public func registerStarted(_ op:AsyncOperation) {
        if let queueUUID = op.queueUuid {
            var queueDict = self.runningTags[queueUUID] ?? [:]
            for tag in op.tags {
                var tagDict = queueDict[tag.type] ?? [:]
                tagDict[tag.value] = (tagDict[tag.value] ?? 0) + 1
                queueDict[tag.type] = tagDict
            }
            self.runningTags[queueUUID] = queueDict
            NotificationCenter.default.post(name: .AsyncOperationTagMonitorCenterDidChange, object: nil, userInfo: ["tags":op.tags,"queueUUID":(op.queueUuid ?? "")])
        }

    }
    
    public func registerStopped(_ op:AsyncOperation) {
        if let queueUUID = op.queueUuid {
            var queueDict = self.runningTags[queueUUID] ?? [:]
            for tag in op.tags {
                var tagDict = queueDict[tag.type] ?? [:]
                tagDict[tag.value] = (tagDict[tag.value] ?? 1) - 1
                queueDict[tag.type] = tagDict
            }
            self.runningTags[queueUUID] = queueDict
            NotificationCenter.default.post(name: .AsyncOperationTagMonitorCenterDidChange, object: nil, userInfo: ["tags":op.tags,"queueUUID":(op.queueUuid ?? "")])
        }
    }
    
    public func countFor(tag:AsyncOperationTag, queue:UUID) -> Int{
        return self.runningTags[queue]?[tag.type]?[tag.value] ?? 0
    }
    
    func tagsEnded(_ tags:[AsyncOperationTag]) {
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

class AsyncOperationQueue : OperationQueue {
    fileprivate let uuid = UUID.init()
    
    override func addOperation(_ op: Operation) {
        if let op = op as? AsyncOperation {
            op.queueUuid = self.uuid
            AsyncOperationMonitorCenter.shared.registerStarted(op)
        }
        super.addOperation(op)
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
    
    fileprivate let uuid = UUID.init()
    fileprivate var queueUuid:UUID?

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
    fileprivate let tags:[AsyncOperationTag]
    
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
            AsyncOperationMonitorCenter.shared.registerStopped(self)
            return
        }
        
        executing(true)
        //        let date = Date()
        if let timeout = timeout {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + timeout, execute: {
                if !self.isFinished {
                    self.executing(false)
                    self.finish(true)
                    AsyncOperationMonitorCenter.shared.registerStopped(self)
                    //print("operation completed - timeout \(date.timeIntervalSinceNow)")
                }
            })
        }
        if let block = self.executionBlock {
            block({
                if !self.isFinished {
                    self.executing(false)
                    self.finish(true)
                    AsyncOperationMonitorCenter.shared.registerStopped(self)
                    //print("operation completed \(date.timeIntervalSinceNow)")
                    
                }else{
                    //print("operation called completion after already complted timeout: \(date.timeIntervalSinceNow) \(self.timeout)")
                }
            })
        }else{
            print("CRITICAL bug in asyncOperation")
            self.executing(false)
            self.finish(true)
            AsyncOperationMonitorCenter.shared.registerStopped(self)
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
    convenience init(assetId:String?, shoppableId:String?, queues:[AsyncOperationQueue], delegate:AsyncOperationMonitorDelegate) {
        var tags:[AsyncOperationTag] = []
        if let assetId = assetId {
            tags.append(AsyncOperationTag.init(type: .assetId, value: assetId))
        }
        if let shoppableId = shoppableId {
            tags.append(AsyncOperationTag.init(type: .shoppableId, value: shoppableId))
        }
        self.init(tags: tags, queues:queues, delegate: delegate)
    }
    
}


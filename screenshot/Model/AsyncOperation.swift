//
//  AsyncOperation.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/4/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let AsyncOperationTagMonitorCenterDidChange = Notification.Name(rawValue: "io.crazeapp.screenshot.AsyncOperationTagMonitorCenterDidChange")
}
protocol AsyncOperationMonitorDelegate : class {
    func asyncOperationMonitorDidChange(_ monitor:AsyncOperationMonitor)
}

class AsyncOperationMonitor {
    weak var delegate:AsyncOperationMonitorDelegate?
    private(set) var didStart = false
    let tags:[AsyncOperationTag]
    let queueUUIDs:[UUID]
    init(tags:[AsyncOperationTag], queues:[AsyncOperationQueue], delegate:AsyncOperationMonitorDelegate?) {
        self.tags = tags
        self.delegate = delegate
        let queueUUIDs = queues.map{ $0.uuid }
        self.queueUUIDs = queueUUIDs
        self.didStart = self.calculateDidStart(tags: tags, queueUUIDS: queueUUIDs)

        NotificationCenter.default.addObserver(self, selector: #selector(asyncOperationDidChange(_:)), name: .AsyncOperationTagMonitorCenterDidChange, object: nil)
    }
    
    private func calculateDidStart(tags:[AsyncOperationTag], queueUUIDS:[UUID]) -> Bool{
        var count = 0
        tags.forEach { (tag) in
            queueUUIDs.forEach({ (uuid) in
                count +=  AsyncOperationMonitorCenter.shared.countFor(tag: tag, queue: uuid)
            })
        }
        return count > 0
    }

    
    private func calculateDidStart() -> Bool{
       return self.calculateDidStart(tags: self.tags, queueUUIDS: self.queueUUIDs)
    }
    @objc private func asyncOperationDidChange(_ notification:Notification){
        if let userInfo = notification.userInfo, let changedTags = userInfo["tags"] as? [AsyncOperationTag], let queueUUID = userInfo["queueUUID"] as? UUID {
            if self.queueUUIDs.contains(queueUUID) {
                var didChangeTag = false
                for t in changedTags {
                    if tags.contains(t) {
                        didChangeTag = true
                    }
                }
                if didChangeTag {
                    let oldValue = self.didStart
                    let newValue = calculateDidStart()
                    if oldValue != newValue {
                        self.didStart = newValue
                        self.delegate?.asyncOperationMonitorDidChange(self)
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
    
    
    
    public func registerStarted(queueUUID:UUID?, tags:[AsyncOperationTag]?) {
        DispatchQueue.mainAsyncIfNeeded {
            if let queueUUID = queueUUID, let tags = tags {
                var queueDict = self.runningTags[queueUUID] ?? [:]
                
                for tag in tags {
                    var tagDict = queueDict[tag.type] ?? [:]
                    tagDict[tag.value] = (tagDict[tag.value] ?? 0) + 1
                    queueDict[tag.type] = tagDict
                    
                }
                self.runningTags[queueUUID] = queueDict
                NotificationCenter.default.post(name: .AsyncOperationTagMonitorCenterDidChange, object: nil, userInfo: ["tags":tags,"queueUUID":queueUUID])
            }
        }

    }
    
    public func registerStopped(queueUUID:UUID?, tags:[AsyncOperationTag]?) {
        DispatchQueue.mainAsyncIfNeeded {
            
            if let queueUUID = queueUUID, let tags = tags {
                var queueDict = self.runningTags[queueUUID] ?? [:]
                
                for tag in tags {
                    var tagDict = queueDict[tag.type] ?? [:]
                    tagDict[tag.value] = (tagDict[tag.value] ?? 1) - 1
                    queueDict[tag.type] = tagDict
                }
                
                self.runningTags[queueUUID] = queueDict
                NotificationCenter.default.post(name: .AsyncOperationTagMonitorCenterDidChange, object: nil, userInfo: ["tags":tags,"queueUUID":queueUUID])
            }
        }
    }
    
    public func countFor(tag:AsyncOperationTag, queue:UUID) -> Int{
        return self.runningTags[queue]?[tag.type]?[tag.value] ?? 0
    }
    
}


class AsyncOperationTag: Equatable {
    enum TagType : String {
        case assetId
        case shoppableId
        case productNumber
        case filterChange
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
    let uuid = UUID.init()
    
    private static var observerContext = 0
    
    var operationPrioritySorting:((AsyncOperation, AsyncOperation) -> Bool?)? {
        didSet{
            setAllOperationPriority(operations:self.operations)
        }
    }
    override init() {
        super.init()
        self.addObserver(self, forKeyPath: "operations", options: .new, context: &AsyncOperationQueue.observerContext)
        
    }
    deinit {
        self.removeObserver(self, forKeyPath: "operations", context: &AsyncOperationQueue.observerContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &AsyncOperationQueue.observerContext {
            setAllOperationPriority(operations:self.operations)
        }else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func setAllOperationPriority(operations:[Operation]) {
        if let sort = self.operationPrioritySorting {
            let sortedOperations = operations.filter{ $0.isCancelled == false && $0.isFinished == false && $0.isExecuting == false}.sorted { (op1, op2) -> Bool in
                if let op1 = op1 as? AsyncOperation,
                    let op2 = op2 as? AsyncOperation{
                    if let result = sort(op1, op2) {
                        return result
                    }
                }
                return op1.hash > op2.hash
            }
            
            var priorities:[Operation.QueuePriority] =  [.veryHigh, .high, .normal, .low, .veryLow]
            sortedOperations.forEach { (op) in
                if let priority = priorities.first{
                    op.queuePriority = priority
                    priorities.remove(at: 0)
                }else{
                    op.queuePriority = .veryLow
                }
            }
        }
    }
    
    override func addOperation(_ op: Operation) {
        if let op = op as? AsyncOperation {
            op.queueUuid = self.uuid
            AsyncOperationMonitorCenter.shared.registerStarted(queueUUID: uuid, tags: op.tags)
        }
        let array = self.operations + [op]
        setAllOperationPriority(operations: array)
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

    var userInfo:[AnyHashable:Any] = [:]
    
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
    let tags:[AsyncOperationTag]
    
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
        let tags = self.tags
        let localQueueUUID = self.queueUuid
        guard isCancelled == false else {
            finish(true)
            AsyncOperationMonitorCenter.shared.registerStopped(queueUUID: localQueueUUID, tags: tags)
            return
        }
        
        executing(true)
        //        let date = Date()
        if let timeout = timeout {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + timeout, execute: {
                if !self.isFinished {
                    self.executing(false)
                    self.finish(true)
                    AsyncOperationMonitorCenter.shared.registerStopped(queueUUID: localQueueUUID, tags: tags)
                    //print("operation completed - timeout \(date.timeIntervalSinceNow)")
                }
            })
        }
        if let block = self.executionBlock {
            block({
                if !self.isFinished {
                    self.executing(false)
                    self.finish(true)
                    AsyncOperationMonitorCenter.shared.registerStopped(queueUUID: localQueueUUID, tags: tags)
                    //print("operation completed \(date.timeIntervalSinceNow)")
                    
                }else{
                    //print("operation called completion after already complted timeout: \(date.timeIntervalSinceNow) \(self.timeout)")
                }
            })
        }else{
            print("CRITICAL bug in asyncOperation")
            self.executing(false)
            self.finish(true)
            AsyncOperationMonitorCenter.shared.registerStopped(queueUUID: localQueueUUID, tags: tags)
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
        if let assetId = assetId {
            userInfo = ["assetId":assetId]
        }
    }
    
    convenience init(timeout:TimeInterval?, partNumbers:[String], completion:@escaping ((@escaping() -> ()) -> ())) {
        var tags:[AsyncOperationTag] = []
        partNumbers.forEach { tags.append(AsyncOperationTag.init(type: .productNumber, value: $0)) }

        self.init(timeout: timeout, tags: tags, completion: completion)
    }

}

extension AsyncOperationMonitor {
    convenience init(assetId:String?, shoppableId:String?, queues:[AsyncOperationQueue], delegate:AsyncOperationMonitorDelegate?) {
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


//
//  GlobalDateTools.swift
//  Screenshop
//
//  Created by Jonathan Rose on 7/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

// this is used for InboxMessage to no create new calendars and formatters for every item in list
class GlobalDateTools: NSObject {
    public static let shared = GlobalDateTools()
    private var privateGregorianCalendar:Calendar?
    private var privateMostRecentMidnight:Date?
    private var privateMostRecentJan1:Date?


    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(significantTimeChange(_:)), name: .UIApplicationSignificantTimeChange, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @objc func significantTimeChange(_ notification:Notification){
        self.privateGregorianCalendar = nil
        self.privateMostRecentJan1 = nil
        self.privateMostRecentMidnight = nil
    }
    
    lazy var gregorianCalendar:Calendar = {
        if self.privateGregorianCalendar == nil {
            self.privateGregorianCalendar = Calendar.init(identifier: .gregorian)
        }
        return self.privateGregorianCalendar ?? Calendar.current
    }()
    
    lazy var mostRecentMidnight:Date = {
        if self.privateMostRecentJan1 == nil {
            self.privateMostRecentJan1 = self.gregorianCalendar.startOfDay(for: Date())
        }
        return self.privateMostRecentJan1 ?? self.gregorianCalendar.startOfDay(for: Date())
    }()
    
    lazy var mostRecentJan1:Date = {
        if self.privateMostRecentJan1 == nil {
            var comp = self.gregorianCalendar.dateComponents([.year], from: Date())
            comp.day = 1
            comp.month = 1
            self.privateMostRecentJan1 = self.gregorianCalendar.date(from: comp)
        }
        return self.privateMostRecentJan1 ?? Date()
    }()
    
    lazy var shortDateFormatter:DateFormatter = {
        let df = DateFormatter.init()
        df.dateFormat = "MMM d"
        return df
    }()
    
    lazy var longDateFormatter:DateFormatter = {
        let df = DateFormatter.init()
        df.dateFormat = "MMM d, yyyy"
        return df
    }()
    
}

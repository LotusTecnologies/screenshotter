//
//  InboxMessage+craze.swift
//  Screenshop
//
//  Created by Jonathan Rose on 7/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData

extension InboxMessage {
    var sectionHeader:String {
        get {
            if self.isExpired {
                return "Expired"
            }else if let date = self.date {
                let oneDay:TimeInterval = 60*60*24
                let mostRecentMidnight = GlobalDateTools.shared.mostRecentMidnight
                let mostRecentJan1 = GlobalDateTools.shared.mostRecentJan1
                
                if date > mostRecentMidnight {
                    return "Today".localized
                }else if date > date.addingTimeInterval(-1 * oneDay) {
                    return "Yesterday".localized
                }else if date > date.addingTimeInterval(-2 * oneDay) {
                    return "2 days ago".localized
                }else if date > date.addingTimeInterval(-3 * oneDay) {
                    return "3 days ago".localized
                }else if date > date.addingTimeInterval(-4 * oneDay) {
                    return "4 days ago".localized
                }else if date > date.addingTimeInterval(-5 * oneDay) {
                    return "5 days ago".localized
                }else if date > date.addingTimeInterval(-6 * oneDay) {
                    return "6 days ago".localized
                }else if date > mostRecentJan1 {
                    let formatter = GlobalDateTools.shared.shortDateFormatter
                    return formatter.string(from: date)
                }else{
                    let formatter = GlobalDateTools.shared.longDateFormatter
                    return formatter.string(from: date)
                }
            }else{
                 // error?
                return ""
            }
        }
    }
}

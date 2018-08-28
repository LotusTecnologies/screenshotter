//
//  Date+craze.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/17/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation

extension Date {
    func laterDate(_ compareToDate:Date) -> Date{
        return (self as NSDate).laterDate(compareToDate) as Date
    }
}


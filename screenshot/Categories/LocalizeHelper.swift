//
//  LocalizeHelper.swift
//  screenshot
//
//  Created by Corey Werner on 12/11/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }
    
    func localized(withFormat arguments: CVarArg..., comment: String? = nil) -> String {
        return String(format: localized(comment: comment), arguments: arguments)
    }
}

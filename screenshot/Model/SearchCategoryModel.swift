//
//  SearchCategoryModel.swift
//  Screenshop
//
//  Created by Corey Werner on 8/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

struct SearchRoot: Decodable {
    let men: [SearchBranch]
    let women: [SearchBranch]
}

struct SearchBranch: Decodable {
    let title: String?
    let image: String?
    let keyword: String?
    let subcategories: [SearchBranch]?
}

enum SearchClass: String, Decodable {
    case men
    case women
    
    init?(intValue: Int) {
        switch intValue {
        case 0:  self = .men
        case 1:  self = .women
        default: return nil
        }
    }
    
    var intValue: Int {
        switch self {
        case .men:   return 0
        case .women: return 1
        }
    }
    
    var possessiveTitle: String {
        switch self {
        case .men:   return "search.class.men".localized
        case .women: return "search.class.women".localized
        }
    }
}

class SearchCategoryModel {
    static let shared = SearchCategoryModel()
    private(set) var root: SearchRoot?
    
    func fetchCategories() {
        NetworkingPromise.sharedInstance.fetchSearchCategories()
            .then { searchRoot in
                self.root = searchRoot
            }
            .catch { error in
                
        }
    }
}

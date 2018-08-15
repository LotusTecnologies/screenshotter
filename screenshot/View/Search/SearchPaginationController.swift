//
//  SearchPaginationController.swift
//  Screenshop
//
//  Created by Corey Werner on 8/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol SearchPaginationControllerDelegate: NSObjectProtocol {
    func searchPaginationControllerKeywords(_ controller: SearchPaginationController) -> String?
    func searchPaginationController(_ controller: SearchPaginationController, items: [AmazonItem], page: Int)
}

class SearchPaginationController {
    weak var delegate: SearchPaginationControllerDelegate?
    
    private var didFiltersChange = false
    var sort: ProductsOptionsSort = .similar {
        willSet {
            if newValue != sort {
                didFiltersChange = true
            }
        }
    }
    var gender: ProductsOptionsGender = .auto {
        willSet {
            if newValue != gender {
                didFiltersChange = true
            }
        }
    }
    var size: ProductsOptionsSize = .adult {
        willSet {
            if newValue != size {
                didFiltersChange = true
            }
        }
    }
    
    private(set) var keywords: String?
    private(set) var page = 0
    private var totalPages: Int?
    var maxPages: Int {
        return min(10, totalPages ?? 10) // Amazon max page request
    }
    private var pagedItems: [Int:[AmazonItem]] = [:]
    
    var items: [AmazonItem] {
        return pagedItems.sorted(by: { $0.key < $1.key }).reduce([], { $0 + $1.value })
    }
    
    func search(_ keywords: String) {
        if self.keywords != keywords || didFiltersChange {
            self.keywords = keywords
            didFiltersChange = false
            pagedItems = [:]
            page = 1
        }
        else {
            page += 1
        }
        
        if page > maxPages {
            page = maxPages
            return
        }
        
        NetworkingPromise.sharedInstance.searchAmazon(keywords: keywords, page: page, options: (sort, gender, size))
            .then { [weak self] amazonResponse -> Void in
                guard let strongSelf = self else {
                    return
                }
                
                if keywords == strongSelf.delegate?.searchPaginationControllerKeywords(strongSelf) {
                    guard let amazonItems = amazonResponse.items else {
                        return
                    }
                    
                    let page = amazonResponse.itemPage ?? 1
                    
                    strongSelf.totalPages = amazonResponse.totalPages
                    strongSelf.pagedItems[page] = amazonItems
                    strongSelf.delegate?.searchPaginationController(strongSelf, items: amazonItems, page: page)
                }
            }
            .catch { [weak self] error in
                guard let strongSelf = self else {
                    return
                }
                
                if keywords == strongSelf.delegate?.searchPaginationControllerKeywords(strongSelf) {
                    strongSelf.delegate?.searchPaginationController(strongSelf, items: [], page: 1)
                }
        }
    }
    
    func next() {
        guard let keywords = keywords else {
            return
        }
        search(keywords)
    }
}

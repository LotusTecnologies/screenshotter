//
//  SearchController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchController: UISearchController {
    let _searchBar = SearchBar()
    
    override var searchBar: UISearchBar {
        return _searchBar
    }
}

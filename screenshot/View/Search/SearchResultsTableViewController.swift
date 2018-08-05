//
//  SearchResultsTableViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 8/2/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchResultsTableViewController: UITableViewController {
    var amazonItems: [AmazonItem]? {
        didSet {
            if isViewLoaded {
//                tableView?.contentOffset = CGPoint(x: 0, y: -(tableView?.safeAreaInsets.top ?? 0))
                tableView?.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

// MARK: - Data Source

extension SearchResultsTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return amazonItems?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? SearchResultTableViewCell, let amazonItem = amazonItems?[indexPath.row] {
            cell.imageView?.image = UIImage(named: "FavoriteX")
            cell.textLabel?.text = amazonItem.asin
//            cell.detailTextLabel?.text = "Subtitle"
            
            cell.detailTextLabel?.attributedText = NSAttributedString(string: "Subtitle", attributes: [
                .foregroundColor: UIColor.red
                ])
        }
        
        return cell
    }
}

// MARK: - Delegate

extension SearchResultsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

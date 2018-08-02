//
//  SearchResultsTableViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 8/2/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchResultsTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

// MARK: - Data Source

extension SearchResultsTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? SearchResultTableViewCell {
            cell.imageView?.image = UIImage(named: "FavoriteX")
            cell.textLabel?.text = "Title"
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

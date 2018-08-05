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
                tableView?.contentOffset = {
                    var offset: CGPoint = .zero
                    
                    if #available(iOS 11.0, *) {
                        offset.y = -(tableView?.safeAreaInsets.top ?? 0)
                    }
                    else {
                        offset.y = -(tableView?.contentInset.top ?? 0)
                    }
                    
                    return offset
                }()
                
                tableView?.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.keyboardDismissMode = .onDrag
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
            let imageURL = URL(string: amazonItem.smallImage?.urlString ?? "")
            let placeholderImage = UIImage(named: "DefaultProduct")
            cell.imageView?.sd_setImage(with: imageURL, placeholderImage: placeholderImage)
            
            cell.textLabel?.text = amazonItem.asin
//            cell.detailTextLabel?.text = "Subtitle"
            
            let price = amazonItem.offers.first?.offerListing.first?.price?.formattedPrice ?? ""
            
            cell.detailTextLabel?.attributedText = NSAttributedString(string: price, attributes: [
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

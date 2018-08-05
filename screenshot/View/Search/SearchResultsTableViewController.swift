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
            cell.productImageView.sd_setImage(with: imageURL, placeholderImage: placeholderImage)
            
            cell.textLabel?.text = amazonItem.itemAttributes?.brand
            
            let description = amazonItem.itemAttributes?.title ?? ""
            let price = amazonItem.offers.first?.offerListing.first?.price?.formattedPrice ?? ""
            let salePrice = amazonItem.offers.first?.offerListing.first?.salePrice?.formattedPrice
            cell.detailTextLabel?.attributedText = attributedText(description: description, price: price, salePrice: salePrice)
        }
        
        return cell
    }
    
    private func attributedText(description: String, price: String, salePrice: String?) -> NSAttributedString {
        var prices = price
        
        if let salePrice = salePrice {
            prices += " \(salePrice)"
        }
        
        let string = "\(prices) - \(description)"
        let attributedString = NSMutableAttributedString(string: string, attributes: [
            .foregroundColor: UIColor.gray3
            ])
        
        if let salePrice = salePrice {
            let priceRange = NSString(string: string).range(of: price)
            let salePriceRange = NSString(string: string).range(of: salePrice)
            
            if priceRange.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor, value: UIColor.gray7, range: priceRange)
                attributedString.addAttribute(.strikethroughColor, value: UIColor.gray7, range: priceRange)
                attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: priceRange)
            }
            if salePriceRange.location != NSNotFound {
                attributedString.addAttribute(.foregroundColor, value: UIColor.crazeRed, range: salePriceRange)
            }
        }
        
        return attributedString
    }
}

// MARK: - Delegate

extension SearchResultsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

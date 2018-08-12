//
//  SearchResultsViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 8/2/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchResultsViewController: UITableViewController {
    var amazonItems: [AmazonItem]? {
        didSet {
            if let amazonItems = amazonItems {
                state = amazonItems.isEmpty ? .empty : .results
            }
            else {
                state = .loading
            }
            
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
    
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    private let emptyLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        tableView.backgroundColor = view.backgroundColor
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.keyboardDismissMode = .onDrag
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .gray7
        view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        NSLayoutConstraint(item: loadingIndicator, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.7, constant: 0).isActive = true
        
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "search.results.empty".localized
        emptyLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        emptyLabel.textColor = .gray3
        emptyLabel.adjustsFontSizeToFitWidth = true
        emptyLabel.minimumScaleFactor = 0.7
        view.addSubview(emptyLabel)
        emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        NSLayoutConstraint(item: emptyLabel, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.7, constant: 0).isActive = true
        emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        syncState()
    }
    
    // MARK: State
    
    private enum State {
        case loading
        case results
        case empty
    }
    
    private var state: State = .loading {
        didSet {
            syncState()
        }
    }
    
    private func syncState() {
        switch state {
        case .loading:
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            emptyLabel.isHidden = true
            
        case .results:
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            emptyLabel.isHidden = true
            
        case .empty:
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            emptyLabel.isHidden = false
        }
    }
}

// MARK: - Data Source

extension SearchResultsViewController {
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
            let price = amazonItem.offers?.first?.offerListing?.first?.price?.formattedPrice ?? ""
            let salePrice = amazonItem.offers?.first?.offerListing?.first?.salePrice?.formattedPrice
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

extension SearchResultsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

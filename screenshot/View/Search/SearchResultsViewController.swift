//
//  SearchResultsViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 8/2/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController {
    var amazonItems: [AmazonItem]? {
        didSet {
            if let amazonItems = amazonItems {
                state = amazonItems.isEmpty ? .empty : .results
            }
            else {
                state = .loading
            }
            
            if isViewLoaded {
                tableView.contentOffset = {
                    var offset: CGPoint = .zero
                    
                    if #available(iOS 11.0, *) {
                        offset.y = -(tableView.safeAreaInsets.top ?? 0)
                    }
                    else {
                        offset.y = -(tableView.contentInset.top ?? 0)
                    }
                    
                    return offset
                }()
                
                tableView.reloadData()
            }
        }
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    private let emptyLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = view.backgroundColor
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .gray5
        view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        NSLayoutConstraint(item: loadingIndicator, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.8, constant: 0).isActive = true
        
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "search.results.empty".localized
        emptyLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        emptyLabel.textColor = .gray3
        emptyLabel.adjustsFontSizeToFitWidth = true
        emptyLabel.minimumScaleFactor = 0.7
        view.addSubview(emptyLabel)
        emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        NSLayoutConstraint(item: emptyLabel, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.8, constant: 0).isActive = true
        emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        syncState()
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
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
            tableView.isHidden = true
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            emptyLabel.isHidden = true
            
        case .results:
            tableView.isHidden = false
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            emptyLabel.isHidden = true
            
        case .empty:
            tableView.isHidden = true
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            emptyLabel.isHidden = false
        }
    }
}

// MARK: - Data Source

extension SearchResultsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return amazonItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? SearchResultTableViewCell, let amazonItem = amazonItems?[indexPath.row] {
            let imageURL = URL(string: amazonItem.smallImage?.urlString ?? "")
            let placeholderImage = UIImage(named: "DefaultProduct")
            cell.productImageView.sd_setImage(with: imageURL, placeholderImage: placeholderImage)
            
            cell.textLabel?.text = title(amazonItem: amazonItem)
            cell.detailTextLabel?.attributedText = detailAttributedText(amazonItem: amazonItem)
        }
        
        return cell
    }
    
    private func title(amazonItem: AmazonItem) -> String? {
        if let string = amazonItem.itemAttributes?.brand?.nonEmptyValue {
            return string
        }
        else {
            let model = amazonItem.itemAttributes?.model?.nonEmptyValue
            let group = amazonItem.itemAttributes?.productGroup?.nonEmptyValue
            
            if let model = model, let group = group {
                return "\(model) - \(group)"
            }
            else {
                return model ?? group
            }
        }
    }
    
    private func detailAttributedText(amazonItem: AmazonItem) -> NSAttributedString? {
        let description = amazonItem.itemAttributes?.title?.nonEmptyValue
        var price = amazonItem.offerSummary?.lowestNewPrice?.formattedPrice.nonEmptyValue
        var salePrice: String?
        var prices = price
        
        if let offer = amazonItem.offers?.first?.offerListing?.first {
            price = offer.price?.formattedPrice.nonEmptyValue ?? price
            salePrice = offer.salePrice?.formattedPrice.nonEmptyValue
            
            if price == salePrice {
                salePrice = nil
            }
            
            if let price = price, let salePrice = salePrice {
                prices = "\(price) \(salePrice)"
            }
            else {
                prices = price
            }
        }
        
        var string: String?
        
        if let prices = prices, let description = description {
            string = "\(prices) - \(description)"
        }
        else {
            string = prices ?? description
        }
        
        if let string = string {
            let attributedString = NSMutableAttributedString(string: string, attributes: [
                .foregroundColor: UIColor.gray3
                ])
            
            if let price = price, let salePrice = salePrice {
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
        
        return nil
    }
}

// MARK: - Delegate

extension SearchResultsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let amazonItem = amazonItems?[indexPath.row] else {
            return
        }
        
        OpenWebPage.present(urlString: amazonItem.detailPageURL, fromViewController: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

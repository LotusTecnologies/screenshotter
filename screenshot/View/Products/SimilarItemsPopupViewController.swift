//
//  RecoveryLostSalePopupViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 7/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import GameKit

class SimilarItemsPopupViewController: UIViewController {

    private let productCollectionViewManager = ProductCollectionViewManager()
    var products:[Product] = [] {
        didSet{
            collectionView.reloadData()
        }
    }
    let collectionView = CollectionView.init(frame: .zero, collectionViewLayout: {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        return layout
    }())
    let dismissBlock:(()->())

    init(dismissAction:@escaping (()->()) ) {
        self.dismissBlock = dismissAction

        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .background
        
        let titleLabel = UILabel.init()
        titleLabel.textColor = .black
        titleLabel.text = "Similar Items"
        titleLabel.font = UIFont.screenshopFont(.quicksandMedium, size: 23.0)
        titleLabel.minimumScaleFactor = 0.3
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        view.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: .padding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ProductsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant:.padding).isActive = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.background
        collectionView.contentInset = .init(top: 0, left: .padding, bottom: 0, right: .padding)
        
        let closeButton = UIButton.init(type: .custom)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "FavoriteX"), for: .normal)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        closeButton.addTarget(self, action: #selector(dissmissAction(_:)), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        closeButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
        
    }
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.collectionView)
        let collectionView = self.collectionView
        if let indexPath = collectionView.indexPathForItem(at: point),  let cell = collectionView.cellForItem(at: indexPath){
            
            if let cell = cell as? ProductsCollectionViewCell, let imageView = cell.productImageView {
                CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var size = CGSize()
        size.width = UIScreen.main.bounds.size.width * 0.9
        size.height = ProductsCollectionViewCell.cellHeight(for: size.width/2.3, withActionButton: true) + 50

        self.preferredContentSize = size
    }

    @objc func dissmissAction(_ sender:Any){
        dismissBlock()
    }
}

extension SimilarItemsPopupViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let columns = CGFloat(2.3)
        let width = collectionView.bounds.size.width / columns
        let height = ProductsCollectionViewCell.cellHeight(for: width, withActionButton: true)
        return CGSize.init(width: width, height: height)
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.products.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let product = self.products[indexPath.row]
        let cell = self.productCollectionViewManager.collectionView(collectionView, cellForItemAt: indexPath, with: product)
        if let cell = cell as? ProductsCollectionViewCell {
            cell.actionButton.isHidden = true
            cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)

        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = self.products[indexPath.row]
        Analytics.trackFeatureLowerPricesClicked(product: product)
        self.presentProduct(product, atLocation: .saleRecoveryPrompt)
    }
    @objc func productCollectionViewCellFavoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = collectionView.indexPath(for: event) else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        let product = self.products[indexPath.row]

        product.setFavorited(toFavorited: isFavorited)
        
        if isFavorited {
            Analytics.trackProductFavorited(product: product, page: .similarItemsPopup)
            LocalNotificationModel.shared.registerCrazeFavoritedPriceAlert(id: product.id, merchant: product.merchant, lastPrice: product.floatPrice)
        }else{
            Analytics.trackProductUnfavorited(product: product, page: .similarItemsPopup)
            LocalNotificationModel.shared.deregisterCrazeFavoritedPriceAlert(id: product.id, merchant: product.merchant)
        }
    }

}

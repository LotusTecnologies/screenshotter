//
//  ProductsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

extension ProductsViewController {
    @objc func setupShoppableToolbar() {
        self.shoppablesToolbar = {
            let margin:CGFloat = 8.5 // Anything other then 8 will display horizontal margin
            let shoppableHeight:CGFloat = 60
            
            let toolbar = ShoppablesToolbar.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: margin*2+shoppableHeight))
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            toolbar.delegate = self
            toolbar.shoppableToolbarDelegate = self
            toolbar.barTintColor = .white
            toolbar.isHidden = self.shouldHideToolbar()
            self.view.addSubview(toolbar)
            
            toolbar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
            toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            toolbar.heightAnchor.constraint(equalToConstant: toolbar.bounds.size.height).isActive = true
            return toolbar;
        }()
    }
    @objc func setupCollectionView(){
        self.collectionView = {
            let minimumSpacing = self.collectionViewMinimumSpacing()
            
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x;
            layout.minimumLineSpacing = minimumSpacing.y;
            
            let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)

            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self;
            collectionView.dataSource = self;
            collectionView.contentInset = UIEdgeInsets.init(top: self.shoppablesToolbar.bounds.size.height, left: 0.0, bottom: minimumSpacing.y, right: 0.0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets.init(top: self.shoppablesToolbar.bounds.size.height, left: 0.0, bottom: 0.0, right: 0.0)
            
            collectionView.backgroundColor = self.view.backgroundColor;
            // TODO: set the below to interactive and comment the dismissal in -scrollViewWillBeginDragging.
            // Then test why the control view (products options view) jumps before being dragged away.
            collectionView.keyboardDismissMode = .onDrag;
            collectionView.register(ProductsTooltipCollectionViewCell.self, forCellWithReuseIdentifier: "tooltip");
            collectionView.register(ProductCollectionViewCell.self, forCellWithReuseIdentifier: "cell");


            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            return collectionView
        }()
    }
    @objc func setupRatingView(){
//        self.rateView = {
//            let view = ProductsRateView.init()
//            view.translatesAutoresizingMaskIntoConstraints = false
//            view.voteUpButton.add
//            [view.voteUpButton addTarget:self action:@selector(productsRatePositiveAction) forControlEvents:UIControlEventTouchUpInside];
//            [view.voteDownButton addTarget:self action:@selector(productsRateNegativeAction) forControlEvents:UIControlEventTouchUpInside];
//            [view.talkToYourStylistButton addTarget:self action:@selector(talkToYourStylistAction) forControlEvents:UIControlEventTouchUpInside];
//            
//            return view;
//        }()
    }
}

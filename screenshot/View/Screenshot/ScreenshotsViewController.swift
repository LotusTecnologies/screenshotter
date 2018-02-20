//
//  ScreenshotsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import SafariServices
import FBSDKCoreKit


extension ScreenshotsViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.shiftIndexSections(by: 2)
        change.applyChanges(collectionView: self.collectionView)
        self.syncHelperViewVisibility()

    }
    
    @objc func setupFetchedResultsController(){
        self.screenshotFrcManager = DataModel.sharedInstance.screenshotFrc(delegate: self)
        
    }
    @objc func screenshotFrc() -> NSFetchedResultsController<Screenshot>? {
        return (self.screenshotFrcManager as? FetchedResultsControllerManager<Screenshot>)?.fetchedResultsController
        
    }
}

extension ScreenshotsViewController : ProductsBarControllerDelegate {
    func productBarShouldHide(_ controller: ProductsBarController) {
        if self.collectionView.numberOfItems(inSection: ScreenshotsSection.product.rawValue) == 1{
            self.collectionView.deleteItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.product.rawValue)])
        }
    }
    
    func productBarShouldShow(_ controller: ProductsBarController) {
        if self.collectionView.numberOfItems(inSection: ScreenshotsSection.product.rawValue) == 0{
            self.collectionView.insertItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.product.rawValue)])
        }
    }
    
    func productBar(_ controller: ProductsBarController, didTap product: Product) {
        if !self.isEditing {
            OpenProductPage.present(product: product, fromViewController: self, analyticsKey: "ProductBar")
        }else{
            if self.toUnfavoriteAndUnViewProductObjectIDs.contains(product.objectID){
                self.toUnfavoriteAndUnViewProductObjectIDs.remove(product.objectID)
            }else{
                self.toUnfavoriteAndUnViewProductObjectIDs.add(product.objectID)
            }
            if let a = self.toUnfavoriteAndUnViewProductObjectIDs as? [NSManagedObjectID] {
                controller.toUnfavoriteAndUnViewProductObjectIDs = a
            }
            self.updateDeleteButtonCount()
        }
    }
}

//Helper view
extension ScreenshotsViewController {
    @objc func insertScreenshotHelperView() {
        
        let hasPresented = UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
        if !hasPresented && self.collectionView.numberOfItems(inSection: ScreenshotsSection.image.rawValue) == 1{
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
            if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let backgroundView = UIView()
                
                self.collectionView.backgroundView = backgroundView;
                
                let contentView = UIView()
                contentView.translatesAutoresizingMaskIntoConstraints = false
                backgroundView.addSubview(contentView)
                
                contentView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:layout.minimumLineSpacing).isActive = true
                contentView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant:-layout.minimumInteritemSpacing).isActive = true
                contentView.widthAnchor.constraint(equalTo: backgroundView.widthAnchor,multiplier:0.5, constant:-layout.minimumInteritemSpacing * 1.5).isActive = true
                contentView.heightAnchor.constraint(equalTo: backgroundView.widthAnchor,multiplier:Screenshot.ratio.height, constant:0).isActive = true
                
                
                let titleLabel = UILabel()
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.text = "screenshots.helperView.title".localized
                titleLabel.font = UIFont.systemFont(ofSize: 22, weight: UIFontWeightSemibold)
                titleLabel.numberOfLines = 0
                contentView.addSubview(titleLabel)
                titleLabel.topAnchor.constraint(equalTo:contentView.topAnchor).isActive = true
                titleLabel.leadingAnchor.constraint(equalTo:contentView.leadingAnchor).isActive = true
                titleLabel.trailingAnchor.constraint(equalTo:contentView.trailingAnchor).isActive = true
                
                
                let descriptionLabel = UILabel()
                descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
                descriptionLabel.text = "screenshots.helperView.byline".localized
                descriptionLabel.font = UIFont.systemFont(ofSize: 22, weight: UIFontWeightLight)
                
                descriptionLabel.numberOfLines = 0
                contentView.addSubview(descriptionLabel)
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Geometry.padding).isActive = true
                descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
                descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
                
                
                let imageView = UIImageView.init(image: UIImage.init(named: "TutorialReadyArrow"))
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleAspectFit
                contentView.addSubview(imageView)
                imageView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor).isActive = true
                imageView.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor).isActive = true
                imageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
                imageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor).isActive = true
            }
        }
    }
    
    @objc func removeScreenshotHelperView(){
        if self.collectionView.backgroundView != nil {
           self.collectionView.backgroundView?.removeFromSuperview()
            self.collectionView.backgroundView = nil
        }
    }
}


//Edit actions
extension ScreenshotsViewController {
    @objc func editButtonAction() {
        
        let isEditing = !self.isEditing
        
        if !isEditing {
            // Needs to be before setEditing
            self.deselectDeletedScreenshots()
        }
        self.setEditing(isEditing, animated: true)
        
    }
    @objc open override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        if (self.tabBarController != nil && editing) {
            var bottom:CGFloat = 0.0
            
            if #available(iOS 11.0, *) {
                if let safeAreaInsetsBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                    bottom = safeAreaInsetsBottom / 2.0
                }
            }
            if self.deleteButton == nil {
                 let deleteButton = ScreenshotsDeleteButton.init()
                deleteButton.autoresizingMask = [.flexibleWidth,.flexibleHeight]
                deleteButton.translatesAutoresizingMaskIntoConstraints = true
                deleteButton.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
                self.deleteButton = deleteButton
            }
            
            self.deleteButton.alpha = 0
            self.deleteButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: bottom, right: 0)
            
            self.deleteButton.frame = self.tabBarController!.tabBar.bounds;
            self.tabBarController?.tabBar.addSubview(self.deleteButton)
            
        }
        let removeDeleteButton = {
            if (self.tabBarController != nil && !editing) {
                self.deleteButton.removeFromSuperview()
                self.updateDeleteButtonCount()
            }
        }
        
        let cellEditing = {
            for index in self.collectionView.indexPathsForVisibleItems {
                if let cell = self.collectionView.cellForItem(at: index) as? ScreenshotCollectionViewCell {
                    cell.isEditing = editing;
                    self.syncScreenshotCollectionViewCellSelectedState(cell)

                }
            }
            
            
            if (self.hasNewScreenshot()) {
                //                TODO: fix this
                self.collectionView.reloadSections(IndexSet.init(integer: 1))
            }
            
            self.deleteButton.alpha = editing ? 1.0: 0.0
        }
        
        if (animated) {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                
                cellEditing();
                ///     putting `removeDeleteButton` here instead of in the completion
                //      prevents animation on the button fading away,
                //      but ALSO fixes a bug where if you take edit cancel
                //      edit cancel very fast you can get into a state
                //      where there no delete button in edit mode
                removeDeleteButton();
            })
        }
        else {
            cellEditing();
            removeDeleteButton();
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = !editing;
        
        if (editing) {
            self.editButtonItem.title = "generic.cancel".localized
            
            self.deleteScreenshotObjectIDs = []
            self.toUnfavoriteAndUnViewProductObjectIDs = []
        }else {
            self.productsBarController.toUnfavoriteAndUnViewProductObjectIDs = []
        }
    }
    
    @objc func deselectDeletedScreenshots() {
        
        // Deselect all cells
        self.collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
        
        
        self.deleteScreenshotObjectIDs = []
        self.toUnfavoriteAndUnViewProductObjectIDs = []
        self.productsBarController.toUnfavoriteAndUnViewProductObjectIDs = self.toUnfavoriteAndUnViewProductObjectIDs as! [NSManagedObjectID];
    }
    
    @objc func updateDeleteButtonCount () {

        self.deleteButton.deleteCount = self.toUnfavoriteAndUnViewProductObjectIDs.count + self.deleteScreenshotObjectIDs.count;
    }
    
    @objc func deleteButtonAction(){
        self.setEditing(false, animated: true)
        self.editButtonItem.isEnabled = false
        if (self.deleteScreenshotObjectIDs.count + self.toUnfavoriteAndUnViewProductObjectIDs.count > 0) {
            DataModel.sharedInstance.hide(screenshotOIDArray: self.deleteScreenshotObjectIDs as! [NSManagedObjectID])
            DataModel.sharedInstance.unfavoriteAndUnview(productObjectIDs: self.toUnfavoriteAndUnViewProductObjectIDs as! [NSManagedObjectID])
            
        }
    }

}

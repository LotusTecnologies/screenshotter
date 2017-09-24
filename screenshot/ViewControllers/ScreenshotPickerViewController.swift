//
//  ScreenshotPickerViewController.swift
//  screenshot
//
//  Created by Corey Werner on 9/18/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import Photos

class ScreenshotPickerNavigationController: UINavigationController {
    private(set) public var screenshotPickerViewController: ScreenshotPickerViewController!
    private(set) public var cancelButton: UIBarButtonItem!
    private(set) public var doneButton: UIBarButtonItem!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        cancelButton = UIBarButtonItem.init(barButtonSystemItem: .cancel, target: nil, action: nil)
        doneButton = UIBarButtonItem.init(barButtonSystemItem: .done, target: nil, action: nil)
        doneButton.tintColor = UIColor.crazeRed
        doneButton.isEnabled = false
        
        screenshotPickerViewController = ScreenshotPickerViewController.init(nibName: nil, bundle: nil)
        screenshotPickerViewController.title = "Add Your Screenshots"
        screenshotPickerViewController.navigationItem.leftBarButtonItem = cancelButton
        screenshotPickerViewController.navigationItem.rightBarButtonItem = doneButton
        viewControllers = [screenshotPickerViewController]
    }
}

class ScreenshotPickerViewController: BaseViewController {
    fileprivate var collectionView: UICollectionView!
    fileprivate var helperView: HelperView!
    fileprivate var screenshots: PHAssetCollection?
    fileprivate var assets: PHFetchResult<PHAsset>?
    fileprivate var selectedIndexPaths: [IndexPath] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
        
        if let collection = collections.firstObject {
            screenshots = collection
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        
        collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = view.backgroundColor
        collectionView.allowsMultipleSelection = true
        collectionView.register(PickerCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let verPadding = CGFloat(40)
        let horPadding = CGFloat(Geometry.padding())
        
        helperView = HelperView.init()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsetsMake(verPadding, horPadding, verPadding, horPadding)
        helperView.titleLabel.text = "No Photos!"
        helperView.subtitleLabel.text = "Start taking screenshots of fashion items to fill up your gallery!"
        view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        helperView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let imageView = UIImageView.init(image: UIImage.init(named: "ScreenshotsNoPermissionGraphic"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        helperView.contentView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: helperView.contentView.topAnchor, constant: verPadding).isActive = true
        imageView.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadAssets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !PermissionsManager.shared().hasPermission(for: .photo) {
            let alertController = UIAlertController.init(title: "Shop Your Photos", message: "Pick screenshots from your gallery to scan for items to shop!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction.init(title: "No Thanks", style: .cancel, handler: { (action) in
                if let cancelButton = self.navigationItem.leftBarButtonItem,
                    let cancelAction = cancelButton.action,
                    let cancelTarget = cancelButton.target
                {
                    UIApplication.shared.sendAction(cancelAction, to: cancelTarget, from: self, for: nil)
                }
            }))
            alertController.addAction(UIAlertAction.init(title: "Add Photos", style: .default, handler: { (action) in
                if let alertController = PermissionsManager.shared().deniedAlertController(for: .photo, opened: nil) {
                    self.present(alertController, animated: true, completion: nil)
                }
            }))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc private func applicationWillEnterForeground() {
        if view.window != nil {
            reloadAssets()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Assets
    
    private func reloadAssets() {
        if let collection = screenshots {
            let hadAssets = assets != nil
            
            assets = PHAsset.fetchAssets(in: collection, options: nil)
            
            if hadAssets {
                collectionView.reloadData()
            }
            
            helperView.isHidden = (assets?.count ?? 0) > 0
        }
    }
    
    public func selectedAssets() -> [PHAsset] {
        var selectedAssets: [PHAsset] = []
        
        assets?.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if self.selectedIndexPaths.contains(IndexPath.init(item: index, section: 0)) {
                selectedAssets.append(asset)
            }
        })
        
        return selectedAssets
    }
}

extension ScreenshotPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PickerCollectionViewCell
        
        if let asset = assets?[indexPath.item] {
            PHImageManager.default().requestImage(for: asset, targetSize: collectionViewItemSize(), contentMode: .aspectFill, options: nil) { (image, info) in
                cell.imageView.image = image
            }
        }
        
        return cell
    }
}

extension ScreenshotPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPaths.append(indexPath)
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let index = selectedIndexPaths.index(of: indexPath) {
            selectedIndexPaths.remove(at: index)
        }
        
        if (selectedIndexPaths.count == 0) {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
}

extension ScreenshotPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionViewItemSize() -> CGSize {
        let columnCount = CGFloat(4)
        let interitemSpacing = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        var size = CGSize.zero
        size.width = (view.bounds.size.width - (columnCount * interitemSpacing)) / columnCount
        size.height = size.width
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionViewItemSize()
    }
}

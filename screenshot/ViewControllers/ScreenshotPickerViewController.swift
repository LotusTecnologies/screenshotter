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
        
        screenshotPickerViewController = ScreenshotPickerViewController.init(nibName: nil, bundle: nil)
        screenshotPickerViewController.title = "Add Your Screenshots"
        screenshotPickerViewController.navigationItem.leftBarButtonItem = cancelButton
        screenshotPickerViewController.navigationItem.rightBarButtonItem = doneButton
        viewControllers = [screenshotPickerViewController]
    }
}

class ScreenshotPickerViewController: BaseViewController {
    fileprivate var collectionView: UICollectionView!
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
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = view.backgroundColor
        collectionView.allowsMultipleSelection = true
        collectionView.register(PickerCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let collection = screenshots {
            assets = PHAsset.fetchAssets(in: collection, options: nil)
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
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let index = selectedIndexPaths.index(of: indexPath) {
            selectedIndexPaths.remove(at: index)
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

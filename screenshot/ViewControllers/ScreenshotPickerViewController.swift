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
    private var internalDoneButton: UIBarButtonItem!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        doneButton = UIBarButtonItem()
        internalDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        internalDoneButton.tintColor = UIColor.crazeRed
        internalDoneButton.isEnabled = false
        
        screenshotPickerViewController = ScreenshotPickerViewController(nibName: nil, bundle: nil)
        screenshotPickerViewController.title = "Add Photos"
        screenshotPickerViewController.navigationItem.leftBarButtonItem = cancelButton
        screenshotPickerViewController.navigationItem.rightBarButtonItem = internalDoneButton
        viewControllers = [screenshotPickerViewController]
        
        navigationBar.shadowImage = UIImage()
    }
    
    func doneAction() {
        let assets = screenshotPickerViewController.selectedAssets()
        AssetSyncModel.sharedInstance.syncSelectedPhotos(assets: assets)
        
        if let action = doneButton.action {
            UIApplication.shared.sendAction(action, to: doneButton.target, from: self, for: nil)
        }
        
        let title = screenshotPickerViewController.selectedSegmentTitle()
        track("Imported Photos", properties: ["Section":title, "Count":assets.count])
    }
}

class ScreenshotPickerViewController: BaseViewController {
    fileprivate var collectionView: UICollectionView!
    fileprivate var helperView: HelperView!
    fileprivate var segments: UISegmentedControl!
    fileprivate var assets: PHFetchResult<PHAsset>?
    fileprivate var selectedIndexPaths: [IndexPath] = []
    fileprivate var isScreenshotsOnly = true
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.delegate = self
        view.addSubview(toolbar)
        toolbar.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        segments = UISegmentedControl(items: ["Screenshots", "Gallery"])
        segments.translatesAutoresizingMaskIntoConstraints = false
        segments.tintColor = UIColor.crazeGreen
        segments.selectedSegmentIndex = 0
        segments.addTarget(self, action: #selector(segmentsChanged), for: .valueChanged)
        toolbar.items = [UIBarButtonItem(customView: segments)]
        
        if #available(iOS 11.0, *) {} else {
            segments.topAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.topAnchor).isActive = true
            segments.leadingAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.leadingAnchor).isActive = true
            segments.bottomAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.bottomAnchor).isActive = true
            segments.trailingAnchor.constraint(equalTo: toolbar.layoutMarginsGuide.trailingAnchor).isActive = true
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = view.backgroundColor
        collectionView.allowsMultipleSelection = true
        collectionView.contentInset = UIEdgeInsetsMake(toolbar.intrinsicContentSize.height, 0, 0, 0)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
        collectionView.register(PickerCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.insertSubview(collectionView, belowSubview: toolbar)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let verPadding = CGFloat.extendedPadding
        let horPadding = CGFloat.padding
        
        helperView = HelperView()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsetsMake(verPadding, horPadding, verPadding, horPadding)
        helperView.titleLabel.text = "No Photos!"
        helperView.subtitleLabel.text = "Start taking screenshots of fashion items to fill up your gallery!"
        helperView.contentImage = UIImage(named: "ScreenshotsNoPermissionGraphic")
        helperView.isScrollable = false
        view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: toolbar.bottomAnchor).isActive = true
        helperView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let p = CGFloat.padding
            
            let fab = FloatingActionButton()
            fab.translatesAutoresizingMaskIntoConstraints = false
            fab.setImage(UIImage(named: "FABCamera"), for: .normal)
            fab.backgroundColor = UIColor.crazeRed
            fab.contentEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20)
            fab.adjustsImageWhenHighlighted = false
            fab.addTarget(self, action: #selector(cameraButtonAction), for: .touchUpInside)
            view.addSubview(fab)
            fab.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -p / 2).isActive = true
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p / 2).isActive = true
        }
        
        reloadAssets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !PermissionsManager.shared().hasPermission(for: .photo) {
            presentPhotoPermissionsAlert()
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
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = screenshotsOnlyOrExcludedPredicate()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        if collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        }
        
        selectedIndexPaths.removeAll()
        syncDoneEnabledState()
        
        collectionView.reloadData()
        helperView.isHidden = (assets?.count ?? 0) > 0
    }
    
    public func selectedAssets() -> [PHAsset] {
        var selectedAssets: [PHAsset] = []
        
        assets?.enumerateObjects({ (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if self.selectedIndexPaths.contains(IndexPath(item: index, section: 0)) {
                selectedAssets.append(asset)
            }
        })
        
        return selectedAssets
    }
    
    private func screenshotsOnlyOrExcludedPredicate() -> NSPredicate {
        let has = isScreenshotsOnly ? "" : "NOT"
        return NSPredicate(format: "\(has) ((mediaSubtype & %d) != 0)", PHAssetMediaSubtype.photoScreenshot.rawValue)
    }
    
    // MARK: Segment
    
    @objc private func segmentsChanged() {
        prepareSegmentReload()
        track("Tapped \(selectedSegmentTitle()) Picker List")
    }
    
    fileprivate func setSegmentsIndex(_ index: Int) {
        segments.selectedSegmentIndex = index
        prepareSegmentReload()
    }
    
    private func prepareSegmentReload() {
        isScreenshotsOnly = segments.selectedSegmentIndex == 0 ? true : false
        reloadAssets()
    }
    
    fileprivate func selectedSegmentTitle() -> String {
        return segments.titleForSegment(at: segments.selectedSegmentIndex)!
    }
    
    // MARK: Photo
    
    private func presentPhotoPermissionsAlert() {
        let alertController = UIAlertController(title: "Shop Your Photos", message: "Pick screenshots from your gallery to scan for items to shop!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "No Thanks", style: .cancel, handler: { (action) in
            if let cancelButton = self.navigationItem.leftBarButtonItem,
                let cancelAction = cancelButton.action,
                let cancelTarget = cancelButton.target
            {
                UIApplication.shared.sendAction(cancelAction, to: cancelTarget, from: self, for: nil)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Add Photos", style: .default, handler: { (action) in
            if let alertController = PermissionsManager.shared().deniedAlertController(for: .photo, opened: nil) {
                self.present(alertController, animated: true, completion: nil)
            }
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Camera
    
    @objc private func cameraButtonAction() {
        if PermissionsManager.shared().hasPermission(for: .camera) {
            presentCameraViewController()
            
        } else if !PermissionsManager.shared().hasPermission(for: .photo) {
            presentPhotoPermissionsAlert()
            
        } else {
            PermissionsManager.shared().requestPermission(for: .camera, openSettingsIfNeeded: true, response: { (granted) in
                if granted {
                    self.presentCameraViewController()
                }
            })
        }
    }
    
    private func presentCameraViewController() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Navigation Bar
    
    fileprivate func syncDoneEnabledState() {
        navigationItem.rightBarButtonItem?.isEnabled = (selectedIndexPaths.count > 0)
    }
}

extension ScreenshotPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            UIImageWriteToSavedPhotosAlbum(pickedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            
            track("Created Photo")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
        
        track("Canceled Photo Creation")
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            dismiss(animated: true, completion: nil)
            
            let alertController = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alertController, animated: true)
            
        } else {
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems
            
            setSegmentsIndex(1)
            
            if let selectedIndexPaths = selectedIndexPaths {
                for selectedIndexPath in selectedIndexPaths {
                    selectItem(at: selectedIndexPath.item + 1)
                }
            }
            
            selectItem(at: 0)
            dismiss(animated: true, completion: nil)
            
            if selectedIndexPaths?.count == 0,
                let doneButton = navigationItem.rightBarButtonItem,
                let action = doneButton.action
            {
                UIApplication.shared.sendAction(action, to: doneButton.target, from: self, for: nil)
            }
        }
    }
    
    private func selectItem(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
        collectionView(collectionView, didSelectItemAt: indexPath)
    }
}

// MARK: - Collection View Data Source

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

// MARK: - Collection View Delegate

extension ScreenshotPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPaths.append(indexPath)
        syncDoneEnabledState()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let index = selectedIndexPaths.index(of: indexPath) {
            selectedIndexPaths.remove(at: index)
        }
        
        syncDoneEnabledState()
    }
}

// MARK: - Collection View Delegate Flow Layout

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

// MARK: - Toolbar

extension ScreenshotPickerViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

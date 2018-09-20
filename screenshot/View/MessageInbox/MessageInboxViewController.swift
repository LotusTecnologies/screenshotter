//
//  MessageInboxViewController.swift
//  Screenshop
//
//  Created by Jonathan Rose on 7/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData
import SDWebImage

class MessageInboxViewController: UIViewController {
    fileprivate let collectionView = CollectionView(frame: .zero, collectionViewLayout: {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 1.0
        return layout
    }())

    var messageInboxFRC:FetchedResultsControllerManager<InboxMessage>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageInboxFRC = DataModel.sharedInstance.inboxMessageFrc(delegate: self)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: .padding, left: 0, bottom: .padding, right: 0)
        collectionView.register(MessageInboxCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(MessageInboxHeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: 0, bottom: .extendedPadding, right: 0) // Needed for emptyListView

        collectionView.emptyView = HelperView()
        syncEmptyViewWithNotificationState()
        
        self.view.backgroundColor = .gray9
        self.title = "inbox.title".localized
        let closeX = UIImage(named: "FavoriteX")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: closeX, style: .plain, target: self, action: #selector(back(_:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(syncEmptyViewWithNotificationState), name: .permissionsManagerDidUpdate, object: nil)

        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
    }
    @objc func back(_ sender:Any){
        self.dismiss(animated: true, completion: nil)
        InboxMessage.markAllAsRead()
        
    }
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: point), let cell = self.collectionView.cellForItem(at: indexPath) as? MessageInboxCollectionViewCell{
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: cell.embossedView.imageView)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.syncEmptyViewWithNotificationState()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MessageInboxViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.applyChanges(collectionView: collectionView)
    }
    
    
}

extension MessageInboxViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if InboxMessage.inboxEnabled() {
            return self.messageInboxFRC?.numberOfSections() ?? 0
        }
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if InboxMessage.inboxEnabled() {
            return self.messageInboxFRC?.numberOfItems(in: section) ?? 0
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let cell = cell as? MessageInboxCollectionViewCell {
            cell.embossedView.imageView.sd_cancelCurrentAnimationImagesLoad()
            let placeHolder = UIImage.init(named:"DefaultProduct")
            cell.embossedView.imageView.image = placeHolder
            if let message = messageInboxFRC?.object(at: indexPath) {
                cell.embossedView.imageView.sd_cancelCurrentImageLoad()
                if let actionString = message.actionType, let _ = InboxMessage.ActionType.init(rawValue: actionString){
                    
                    if let urlString = message.image, let url = URL.init(string: urlString) {
                        let isExpired = message.isExpired
                        cell.embossedView.imageView.sd_setImage(with: url, placeholderImage: placeHolder, options:  [.retryFailed, .highPriority], completed: { (image, error, cache, url) in
                            if let currentURL = cell.embossedView.imageView.sd_imageURL() {
                                if currentURL == url {
                                    if isExpired {
                                        if let grayscale = image?.grayscaleImage() {
                                            cell.embossedView.imageView.image = grayscale
                                        }
                                    }
                                }
                            }
                        })
                    }
                    cell.titleLabel.attributedText = MessageInboxCollectionViewCell.attributedStringFor(taggedString: message.title, isExpired: message.isExpired)
                    cell.actionButton.setTitle(message.buttonText, for: .normal)
                    cell.buttonColor = .crazeGreen
                }else{
                    var image = UIImage.init(named: "InboxUnsupportedMessageIcon")
                    if message.isExpired {
                        image = image?.grayscaleImage()
                    }
                    cell.embossedView.imageView.image = image
                    let text = "inbox.unsupported.message.markup".localized
                    let buttonText = "inbox.unsupported.button".localized
                    cell.titleLabel.attributedText = MessageInboxCollectionViewCell.attributedStringFor(taggedString: text, isExpired: message.isExpired)
                    cell.actionButton.setTitle(buttonText, for: .normal)
                    let pinkColor = UIColor.init(hex: "#ED145A")
                    cell.buttonColor = pinkColor
                }
                
               
                
                cell.badge.isHidden = !message.isNew
                cell.actionButton.addTarget(self, action: #selector(inboxMessageCollectionViewCellAction(_:event:)), for: .touchUpInside)
                cell.isExpired = message.isExpired

               
            }
            
            

        }
        return cell
    }
    @objc func inboxMessageCollectionViewCellAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = self.collectionView.indexPath(for: event) else {
            return
        }
        if let message = messageInboxFRC?.object(at: indexPath) {
            var tracking:[String:String] = [:]
            if let trackingJSON = message.trackingJSON,  let trackingJsonData = trackingJSON.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: trackingJsonData, options: []), let validJson = json as? [String:String]{
                tracking = validJson
            }
            var order:Int? = nil
            if let location = self.collectionView.layoutAttributesForItem(at: indexPath)?.frame.minY {
                order = Int(round((location - CGFloat(indexPath.section + 1)*44.0) / MessageInboxCollectionViewCell.height))
            }
            Analytics.trackInboxTappedMessage(tracking: tracking, action: message.actionType, isExpired: message.isExpired, order: order)
            if let action = message.actionType, let actionEnum = InboxMessage.ActionType.init(rawValue: action) {
                switch actionEnum {
                case .link:
                    if let urlString = message.actionValue,  let url = URL.init(string: urlString){
                        if OpenWebPage.safari.canOpen(url: url){
                            OpenWebPage.present(urlString: urlString, fromViewController: self)
                            message.markAsRead()
                        }
                    }
                case .screenshot:
                    if let urlString = message.actionValue,  let _ = URL.init(string: urlString){
                        AssetSyncModel.sharedInstance.addScreenshotFrom(source: .inbox, urlString: urlString, callback: { (screenshot) in
                            Analytics.trackOpenedScreenshot(screenshot: screenshot, source: .inbox)
                            let productsViewController = ProductsViewController.init(screenshot: screenshot)
                            productsViewController.hidesBottomBarWhenPushed = true
                            //This is so 'back' doens't say 'shop photo' which looks weird when the tile is notfications
                            self.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "", style: .plain, target: nil, action: nil)
                            self.navigationController?.pushViewController(productsViewController, animated: true)
                            message.markAsRead()
                        })
                    }
                case .product:
                    if let productId = message.actionValue {
                        let cell = collectionView.cellForItem(at: indexPath) as? MessageInboxCollectionViewCell
                        let actionButton = cell?.actionButton
                        let actionText = message.buttonText
                        ProductDetailViewController.create(productId: productId, startedLoadingFromServer: {
                            actionButton?.isLoading = true
                            actionButton?.setTitle(nil, for: .normal)

                        }, completion: { (viewController) in
                            if let viewController = viewController {
                                let navigationController = ModalNavigationController(rootViewController: viewController)
                                self.present(navigationController, animated: true, completion: nil)
                            }
                            actionButton?.setTitle(actionText, for: .normal)
                            actionButton?.isLoading = false
                            
                        })
                        message.markAsRead()

                    }
                case .similarLooks:
                    if let urlString = message.actionValue,  let _ = URL.init(string: urlString){
                        AssetSyncModel.sharedInstance.addScreenshotFrom(source: .inbox, urlString: urlString, callback: { (screenshot) in
                            
                            let vc = ScreenshotSimilarLooksViewController.init(screenshot: screenshot)
                            Analytics.trackOpenedScreenshot(screenshot: screenshot, source: .inbox)
                            self.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "", style: .plain, target: nil, action: nil)
                            self.navigationController?.pushViewController(vc, animated: true)
                            message.markAsRead()
                        })
                    }
                case .campaign:
                    // actionValue is unused
                    let vc = CampaignPromotionViewController.init(modal: false)
                    vc.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "generic.back".localized, style: .plain, target: nil, action: nil)
                    vc.navigationItem.title = "Boohoo";
                    self.navigationController?.pushViewController(vc, animated: true)
                    message.markAsRead()
                }
            }else{
                if let url = URL.init(string: "https://itunes.apple.com/us/app/screenshop-by-craze/id1254964391"), UIApplication.shared.canOpenURL(url){
                    UIApplication.shared.openInChrome(url: url)
                }
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        if kind == UICollectionElementKindSectionHeader {
             if let cell = cell as? MessageInboxHeaderCollectionReusableView {
                if let message = messageInboxFRC?.object(at: indexPath) {
                    cell.textLabel.text = message.sectionHeader
                }
            }
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: collectionView.bounds.size.width, height: MessageInboxCollectionViewCell.height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.init(width: 0, height: 44)
    }
}

//Empty view:
extension MessageInboxViewController {
    
    @objc func syncEmptyViewWithNotificationState(){
        if let empty = collectionView.emptyView as? HelperView{
            if !InboxMessage.inboxEnabled()
            {
                empty.titleLabel.text = "inbox.empty.title".localized
                empty.subtitleLabel.text = "inbox.empty.error.subTitle".localized
                empty.contentImage = UIImage.init(named: "empytInboxMailIconError")

                if empty.controlView.subviews.count == 0 {
                    let button = MainButton()
                    button.setTitleColor(.white, for: .normal)
                    button.backgroundColor = .crazeGreen
                    button.setTitle("inbox.empty.error.button".localized, for: .normal)
                    button.addTarget(self, action: #selector(enabledNotificationButtonPressed(_:)), for: .touchUpInside)
                    button.translatesAutoresizingMaskIntoConstraints = false
                    empty.controlView.addSubview(button)
                    button.topAnchor.constraint(equalTo: empty.controlView.topAnchor).isActive = true
                    button.leadingAnchor.constraint(equalTo: empty.controlView.leadingAnchor).isActive = true
                    button.trailingAnchor.constraint(equalTo: empty.controlView.trailingAnchor).isActive = true
                    button.bottomAnchor.constraint(equalTo: empty.controlView.bottomAnchor).isActive = true
                }
                empty.controlView.isHidden = false
            }else{
                empty.titleLabel.text = "inbox.empty.title".localized
                empty.subtitleLabel.text = "inbox.empty.subTitle".localized
                empty.contentImage = UIImage.init(named: "empytInboxMailIcon")
                empty.controlView.isHidden = true
            }
        }
    }
    @objc func enabledNotificationButtonPressed(_ sender:Any){
        if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToEmail) {
            let vc = GDPRViewController.init()
            let navVC = UINavigationController.init(rootViewController: vc)
            let closeX = UIImage(named: "FavoriteX")
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: closeX, style: .plain, target: self, action: #selector(dismissGDPRView(_:)))
            self.present(navVC, animated: true, completion: nil)
        }else if PermissionsManager.shared.permissionStatus(for: .push) != .authorized {
            PermissionsManager.shared.requestPermission(for: .push, openSettingsIfNeeded: true)
        }
    }
    @objc func dismissGDPRView(_ sender:Any){
        self.dismiss(animated: true) {
            if PermissionsManager.shared.permissionStatus(for: .push) == .undetermined {
                PermissionsManager.shared.requestPermission(for: .push, openSettingsIfNeeded: false, response: { (granted) in
                    self.collectionView.reloadData()
                })
            }
            self.collectionView.reloadData()
        }
    }
}

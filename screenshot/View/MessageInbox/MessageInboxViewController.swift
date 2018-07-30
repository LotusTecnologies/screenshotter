//
//  MessageInboxViewController.swift
//  Screenshop
//
//  Created by Jonathan Rose on 7/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class MessageInboxViewController: UIViewController {
    fileprivate let collectionView = UICollectionView(frame: .zero, collectionViewLayout: {
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
        
        self.view.backgroundColor = .gray9
        self.title = "Notifications"
        let closeX = UIImage(named: "FavoriteX")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: closeX, style: .plain, target: self, action: #selector(back(_:)))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "debug", style: .plain, target: self, action: #selector(debug(_:)))
    }
    @objc func back(_ sender:Any){
        self.dismiss(animated: true, completion: nil)
    }
    @objc func debug(_ sender:Any){
        DataModel.sharedInstance.performBackgroundTask { (context) in
            for i in 0...20 {
                let message = InboxMessage(context: context)
                let date = Date.init(timeIntervalSinceNow: TimeInterval(-i*12*60*60))
//                let expire = Date().addingTimeInterval(-10* 24*60*60)
                message.date = date
                message.title = "Hey \(String.randomFemaleName()) from \(String.randomCity()) wants to meet you"
                message.buttonText = String.randomMaleName()
//                message.expireDate = expire
//                message.isExpired = expire > date
            }
            context.saveIfNeeded()
        }
    }

}

extension MessageInboxViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.applyChanges(collectionView: collectionView)
    }
    
    
}

extension MessageInboxViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {

        return self.messageInboxFRC?.numberOfSections() ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messageInboxFRC?.numberOfItems(in: section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let cell = cell as? MessageInboxCollectionViewCell {
            cell.imageView.imageView.sd_cancelCurrentAnimationImagesLoad()
            let placeHolder = UIImage.init(named:"DefaultProduct")
            cell.imageView.imageView.image = placeHolder
            if let message = messageInboxFRC?.object(at: indexPath) {
                if let urlString  = message.image, let url = URL.init(string: urlString){
                    cell.imageView.imageView.sd_setImage(with: url, placeholderImage: placeHolder, options: [.retryFailed, .highPriority], completed: nil)

                }
                cell.badge.isHidden = !message.isNew
                cell.titleLabel.attributedText = MessageInboxCollectionViewCell.attributedStringFor(taggedString: message.title)
                cell.actionButton.setTitle(message.buttonText, for: .normal)

            }
            
            

        }
        return cell
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

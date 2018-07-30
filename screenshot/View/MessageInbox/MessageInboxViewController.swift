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
    }
    @objc func back(_ sender:Any){
        self.dismiss(animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

extension MessageInboxViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.applyChanges(collectionView: collectionView)
    }
    
    
}

extension MessageInboxViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1;
//        return self.messageInboxFRC?.numberOfSections() ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
//        return self.messageInboxFRC?.numberOfItems(in: section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let cell = cell as? MessageInboxCollectionViewCell {
            let url = URL.init(string: "https://s3.amazonaws.com/screenshop-ordered-matchsticks/2.jpg")
            cell.imageView.imageView.contentMode = .center
            cell.imageView.imageView.sd_setImage(with: url, placeholderImage: nil, options: [.retryFailed, .highPriority], completed: nil)
            cell.badge.isHidden = false
            cell.titleLabel.attributedText = MessageInboxCollectionViewCell.taggedStringForAttributedString(taggedString: "<blue>get it <underline>now</underline> at <red><bold>20%</bold> off!</red> what are you waiting for?</blue>")
            cell.actionButton.setTitle("lets go", for: .normal)

        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        if kind == UICollectionElementKindSectionHeader {
             if let cell = cell as? MessageInboxHeaderCollectionReusableView {
                cell.textLabel.text = "Today"
                
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

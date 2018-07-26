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
        collectionView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        collectionView.scrollsToTop = false
        collectionView.register(MessageInboxCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
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

extension MessageInboxViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.messageInboxFRC?.numberOfSections() ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messageInboxFRC?.numberOfItems(in: section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let cell = cell as? MessageInboxCollectionViewCell {
            
        }
        return cell
    }
    
    
}

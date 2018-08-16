//
//  ScreenshotSimilarLooksViewController.swift
//  Screenshop
//
//  Created by Jonathan Rose on 8/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ScreenshotSimilarLooksViewController: BaseViewController {
    var screenshot:Screenshot

    var relatedLooksManager:RelatedLooksManager = {
       let r = RelatedLooksManager()
        r.minimumDelay = 0
        return r
    }()
    var collectionView:CollectionView = {
        let layout = UICollectionViewFlowLayout()
        let minimumSpacing = ScreenshotSimilarLooksViewController.collectionViewInteritemOffset()
        layout.minimumInteritemSpacing = minimumSpacing.x
        layout.minimumLineSpacing = minimumSpacing.y
        let c = CollectionView.init(frame: .zero, collectionViewLayout: layout)
        c.register(ScreenshotSimilarLooksCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        return c
    }()
    var timer:Timer?
    static func collectionViewInteritemOffset() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let x: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        let y: CGFloat = .padding - shadowInsets.top - shadowInsets.bottom
        return CGPoint.init(x: x, y: y)
    }
    init(screenshot: Screenshot) {
        self.screenshot = screenshot
        super.init(nibName: nil, bundle: nil)
        self.title = "products.related_looks.headline".localized
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        self.relatedLooksManager.delegate = self
        let minimumSpacing = ScreenshotSimilarLooksViewController.collectionViewInteritemOffset()

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0.0, bottom: minimumSpacing.y, right: 0.0)
        collectionView.backgroundColor = self.view.backgroundColor

        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.collectionView)
        self.collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        self.relatedLooksManager.loadRelatedLooksIfNeeded()
        
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(reCheckVisibleCells), userInfo: nil, repeats: true)

        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
    }
    deinit {
        self.timer?.invalidate()
    }
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: point), let cell = self.collectionView.cellForItem(at: indexPath) as? ScreenshotSimilarLooksCollectionViewCell{
            
            [cell.embossedView.imageView, cell.product1ImageView, cell.product2ImageView].forEach { (v) in
                if v.bounds.contains(v.convert(point, from: self.collectionView)) {
                    CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: v)
                }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
extension ScreenshotSimilarLooksViewController : UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize.zero
        let columns = CGFloat(2)
        let padding = CGFloat.padding
        size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
        size.height = ScreenshotSimilarLooksCollectionViewCell.cellHeight(for: size.width)

        return size
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let minimumSpacing:CGPoint = ScreenshotSimilarLooksViewController.collectionViewInteritemOffset()
        return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 30, right: minimumSpacing.x)
    }
}
extension ScreenshotSimilarLooksViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.relatedLooksManager.numberOfItems()
    }
    
    @objc func reCheckVisibleCells() {
        for cell in self.collectionView.visibleCells {
            if let indexPath = self.collectionView.indexPath(for: cell), let relatedLook = self.relatedLooksManager.relatedLook(at: indexPath.row), let cell = cell as? ScreenshotSimilarLooksCollectionViewCell, !cell.isLoaded , let s = DataModel.sharedInstance.mainMoc().screenshotWith(assetId: relatedLook){
                self.setup(cell: cell, screenshot: s)
            }
        }
    }
    
    func setup(cell:ScreenshotSimilarLooksCollectionViewCell, screenshot:Screenshot){
        if let products = (screenshot.shoppables as? Set<Shoppable>)?.compactMap({ (s) -> [Product]? in
            return (s.products as? Set<Product>)?.filter{ $0.isSale() }.sorted(by: { $0.order > $1.order })
        }){
            var product2:Product? = nil
            if let product1 = products.first?.first{
                if products.count > 1 {
                    product2 = products[1].first
                }
                if product2 == nil {
                    if products.first?.count ?? 0 > 1 {
                        product2 = products.first?[1]
                    }
                }
                if let product2 = product2 {
                    if let imageURL = product1.imageURL, let url = URL.init(string: imageURL){
                        cell.product1ImageView.sd_setImage(with: url)
                    }
                    if let imageURL = product2.imageURL,let url = URL.init(string: imageURL){
                        cell.product2ImageView.sd_setImage(with: url)
                    }
                    cell.product1Title.text = product1.calculatedDisplayTitle
                    cell.product2Title.text = product2.calculatedDisplayTitle
                    cell.product1Byline.attributedText = product1.priceAndSalePriceAttributedString(fontSize:11)
                    cell.product2Byline.attributedText = product2.priceAndSalePriceAttributedString(fontSize:11)
                    cell.isLoaded = true
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let relatedLook = self.relatedLooksManager.relatedLook(at: indexPath.row)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let cell = cell as? ScreenshotSimilarLooksCollectionViewCell {
            cell.embossedView.imageView.sd_cancelCurrentImageLoad()
            cell.product1ImageView.sd_cancelCurrentImageLoad()
            cell.product2ImageView.sd_cancelCurrentImageLoad()
            cell.product1ImageView.image = nil
            cell.product2ImageView.image = nil
            cell.product1Title.text = ""
            cell.product2Title.text = ""
            cell.product1Byline.text = ""
            cell.product2Byline.text = ""
            cell.isLoaded = false
            if let relatedLook = relatedLook,  let url = URL.init(string: relatedLook) {
                cell.embossedView.imageView.sd_setImage(with: url)
                
                if let s = DataModel.sharedInstance.mainMoc().screenshotWith(assetId: relatedLook) {
                    self.setup(cell: cell, screenshot: s)
                }else{
                    AssetSyncModel.sharedInstance.addFromRelatedLook(urlString: relatedLook)

                }
            }
        }
        return cell

    }
}
extension ScreenshotSimilarLooksViewController : RelatedLooksManagerDelegate {
    func relatedLooksManagerReloadSection(_ relatedLooksManager:RelatedLooksManager){
        self.collectionView.reloadData()
    }
    func relatedLooksManagerGetShoppable(_ relatedLooksManager: RelatedLooksManager) -> Shoppable? {
        return self.screenshot.shoppables?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "b0x", ascending: true), NSSortDescriptor(key: "b0y", ascending: true), NSSortDescriptor(key: "b1x", ascending: true), NSSortDescriptor(key: "b1y", ascending: true), NSSortDescriptor(key: "offersURL", ascending: true)]).first as? Shoppable
    }
    func relatedLooksManager(_ relatedLooksManager:RelatedLooksManager, present viewController:UIViewController){
        self.present(viewController, animated: true, completion: nil)
    }
}


//
//  ScreenshotSimilarLooksViewController.swift
//  Screenshop
//
//  Created by Jonathan Rose on 8/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import Cache
import PromiseKit

class ScreenshotSimilarLooksViewController: BaseViewController {
    var screenshot:Screenshot

    var productsCache:Storage<[[String:Any]]>? = {
        let diskConfig = DiskConfig(
            // The name of disk storage, this will be used as folder name within directory
            name: "similarLooksTopToSaleProduct",
            // Expiry date that will be applied by default for every added object
            // if it's not overridden in the `setObject(forKey:expiry:)` method
            expiry: .date(Date().addingTimeInterval(1 * TimeInterval.oneDay)),
            // Maximum size of the disk cache storage (in bytes)
            maxSize: 10000,
            // Where to store the disk cache. If nil, it is placed in `cachesDirectory` directory.
            directory: try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                    appropriateFor: nil, create: true).appendingPathComponent("MyPreferences"),
            // Data protection is used to store files in an encrypted format on disk and to decrypt them on demand
            protectionType: .complete
        )
        let memoryConfig = MemoryConfig(
            expiry: .date(Date().addingTimeInterval(2*60)),
            countLimit: 50,
            totalCostLimit: 0
        )
        let transformer = Transformer<[[String:Any]]>.init(toData: { (array) -> Data in
            if JSONSerialization.isValidJSONObject(array), let data = try? JSONSerialization.data(withJSONObject: array, options: []) {
                return data
            }else{
                return "[]".data(using: .utf8) ?? Data.init()
            }
        }, fromData: { (data) -> [[String : Any]] in
            if let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]], let a = array {
                return a
            }
            return []
        })
        
        let storage = try? Storage(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: transformer
        )
        
        return storage;
    }()
    var downloadPromises:[String:Promise<[[String:Any]]>] = [:]
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
        c.register(SpinnerCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-spinner")
        c.register(ErrorCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-error")
        return c
    }()

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
        
        

        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
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
        if let _ = self.relatedLooksManager.relatedLooks?.error {
           
        }else if let _ = self.relatedLooksManager.relatedLook(at: indexPath.row) {
            var size = CGSize.zero
            let columns = CGFloat(2)
            let padding = CGFloat.padding
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
            size.height = ScreenshotSimilarLooksCollectionViewCell.cellHeight(for: size.width)
            
            return size
        }else{
            
        }
        
        let minimumSpacing:CGPoint = ScreenshotSimilarLooksViewController.collectionViewInteritemOffset()
        let tabBar = self.tabBarController?.tabBar.bounds.size.height ?? 0
        return collectionView.bounds.insetBy(dx: minimumSpacing.x, dy: minimumSpacing.y).insetBy(dx: collectionView.contentInset.left + collectionView.contentInset.right, dy: collectionView.contentInset.top + collectionView.contentInset.bottom + tabBar).size
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
    
    @objc func didPressRetryRelatedLooks(_ sender:Any) {
        self.relatedLooksManager.didPressRetryRelatedLooks(sender)
    }
    
    func downloadForRelatedLook(imageUrl:String) -> Promise<[[String:Any]]>{
        if let promise = downloadPromises[imageUrl]{
            if promise.isPending || promise.isFulfilled {
                return promise
            }
        }
        let p = Promise<[[String:Any]]>.init(resolvers: { (fulfil, reject) in
            if let productsCache = self.productsCache {
            productsCache.async.object(forKey: imageUrl, completion: { (result) in
                switch result {
                case .value(let array):
                    fulfil(array)
                case .error( _):
                    NetworkingPromise.sharedInstance.similarLooksTopToSaleProduct(imageUrl: imageUrl).then { (arrayOfTopProducts) -> Void in
                        self.productsCache?.async.setObject(arrayOfTopProducts, forKey: imageUrl, completion: { (_) in
                            fulfil(arrayOfTopProducts)
                        })
                    }
                }
            })
            }else{
                reject(NSError.init(domain: "ScreenshotSimilarLooksViewController", code: #line, userInfo: [:]))
            }
        })
        downloadPromises[imageUrl] = p
        return p
      
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let error = self.relatedLooksManager.relatedLooks?.error {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks-error", for: indexPath) as? ErrorCollectionViewCell {
                if self.relatedLooksManager.isErrorRetryable(error:error) {
                    cell.button.setTitle("generic.retry".localized, for: .normal)
                    cell.button.addTarget(self, action: #selector(didPressRetryRelatedLooks(_:)), for: .touchUpInside)
                    cell.label.text = "products.related_looks.error.connection".localized
                }else{
                    cell.button.setTitle("generic.dismiss".localized, for: .normal)
                    cell.button.addTarget(self, action: #selector(didPressRetryRelatedLooks(_:)), for: .touchUpInside)
                    cell.label.text = "products.related_looks.error.no_looks".localized
                }
                return cell
            }
        }else if let relatedLook = self.relatedLooksManager.relatedLook(at: indexPath.row) {
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
                cell.imageUrl = relatedLook
                cell.isLoaded = false
                if let url = URL.init(string: relatedLook) {
                    cell.embossedView.imageView.sd_setImage(with: url)
                    self.downloadForRelatedLook(imageUrl: relatedLook).then { (products) -> Void in
                        if products.count > 1 && cell.imageUrl == relatedLook{
                            let product1 = products[0];
                            let product2 = products[1];
                            cell.product1Title.text = self.calculatedDisplayTitle(product1)
                            cell.product2Title.text = self.calculatedDisplayTitle(product2)
                            cell.product1Byline.attributedText = self.priceAndSalePriceAttributedString(product1, fontSize:11)
                            cell.product2Byline.attributedText = self.priceAndSalePriceAttributedString(product2, fontSize:11)
                            if let urlString = product1["imageUrl"] as? String, let url = URL.init(string: urlString) {
                                cell.product1ImageView.sd_setImage(with: url, completed: nil)
                            }
                            if let urlString = product2["imageUrl"] as? String, let url = URL.init(string: urlString) {
                                cell.product2ImageView.sd_setImage(with: url, completed: nil)
                            }
                            cell.isLoaded = true
                        }
                    }
                }
            }
            return cell
        }else{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks-spinner", for: indexPath) as? SpinnerCollectionViewCell{
                cell.spinner.color = .gray3
                return cell
            }
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        return cell

    }
    
    func calculatedDisplayTitle(_ dict:[String:Any]) ->String{
        if let displayBrand = dict["brand"] as? String,
            !displayBrand.isEmpty {
            return displayBrand
        } else if let merchant = dict["merchant"] as? String{
            return merchant
        }
        return ""
    }
    func priceAndSalePriceAttributedString(_ dict:[String:Any], fontSize:CGFloat) -> NSAttributedString{
        let string = NSMutableAttributedString.init()
        let originalPrice = dict["originalPrice"] as? String
        let price = dict["price"] as? String
        let font = UIFont.screenshopFont(.hind, size: fontSize)
        if let originalPrice = originalPrice {
            string.append( NSAttributedString.init(string: originalPrice, attributes: [.strikethroughStyle:NSUnderlineStyle.styleSingle.rawValue, .foregroundColor: UIColor.gray, .font:font ]) )
            string.append(NSAttributedString.init(string: " ", attributes: [ : ]) )
            if let price = price {
                string.append(NSAttributedString.init(string: price, attributes: [.foregroundColor: UIColor.crazeRed, .font:font   ]) )
            }
            
        }else{
            if let price = price {
                string.append(NSAttributedString.init(string: price, attributes: [ .foregroundColor: UIColor.gray , .font:font ]) )
            }
        }
        
        
        return string
    }
}
extension ScreenshotSimilarLooksViewController : RelatedLooksManagerDelegate {
    func relatedLooksManagerReloadSection(_ relatedLooksManager:RelatedLooksManager){
        self.collectionView.reloadData()
    }
    func relatedLooksManagerGetShoppable(_ relatedLooksManager: RelatedLooksManager) -> Shoppable? {
        return self.screenshot.firstShoppable
    }
    func relatedLooksManager(_ relatedLooksManager:RelatedLooksManager, present viewController:UIViewController){
        self.present(viewController, animated: true, completion: nil)
    }
}


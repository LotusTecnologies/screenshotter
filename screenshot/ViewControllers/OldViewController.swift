//
//  OldViewController.swift
//  screenshot
//
//  Created by Gershon Kagan on 8/8/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import MobileCoreServices // kUTTypeImage

class OldViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var resultantJsonLabel: UILabel!
    @IBOutlet weak var openButton: UIButton!

    let imageMediaType = kUTTypeImage as String;

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(uploadLastScreenshot), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        uploadLastScreenshot()
    }
    
    // MARK: - Actions
    
    @IBAction func openButtonClick(_ sender: UIButton) {
        let tabBarController: MainTabBarController = MainTabBarController()
        present(tabBarController, animated: true, completion: nil)
    }

    // MARK: - Helper
    
    func uploadLastScreenshot() {
        activityIndicator.startAnimating()
        
        AssetSyncModel.sharedInstance.uploadLastScreenshot { (success: Bool) in
            DispatchQueue.main.async(execute: {
                self.activityIndicator.stopAnimating()
                if success,
                  let screenshot = DataModel.sharedInstance.lastSavedScreenshotMain(),
                  let shoppables = screenshot.shoppables,
                  shoppables.count > 0 {
                    let viewBounds = self.view.bounds
                    let imageView = UIImageView(frame: viewBounds)
                    if let imageData = screenshot.imageData {
                        imageView.image = UIImage(data: imageData as Data)
                    } else {
                        MatchModel.shared().latestScreenshot(callback: { (image: UIImage?) in
                            if let image = image {
                                DispatchQueue.main.async(execute: {
                                    imageView.image = image
                                })
                            }
                        })
                    }
                    self.view.addSubview(imageView)
                    for shoppable in shoppables {
                        guard let shop = shoppable as? Shoppable else {
                                print("OldViewController uploadLastScreenshot error parsing b0, b1")
                                continue
                        }
                        print("b0x:\(shop.b0x)  b0y:\(shop.b0y)  b1x:\(shop.b1x)  b1y:\(shop.b1y)");
                        let frame = shop.frame(size: viewBounds.size)
                        print("frame:\(NSStringFromCGRect(frame))");
                        let shoppableView = UIView(frame: frame)
                        shoppableView.backgroundColor = UIColor(white: 0, alpha: 0.20)
                        shoppableView.layer.borderWidth = 1
                        shoppableView.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
                        imageView.addSubview(shoppableView)
                    }
                }
            })
        }
    }

}

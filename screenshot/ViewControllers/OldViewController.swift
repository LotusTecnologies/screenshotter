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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        uploadLastScreenshot()
    }
    
    // MARK: - Actions
    
    @IBAction func openButtonClick(_ sender: UIButton) {
        let tabBarController: MainTabBarController = MainTabBarController()
        present(tabBarController, animated: true, completion: nil)
    }

    // MARK: - Helper
    
    func uploadLastScreenshot() {
        resultantJsonLabel.text = nil;
        activityIndicator.startAnimating()
        
        let logString = NSMutableString()
        let matchModel = MatchModel.shared()!
        matchModel.logClarifaiSyteInitial(logString, completionHandler: { (response: URLResponse, responseObject: Any?, error: Error?) in
            guard error == nil,
              let responseObjectDict = responseObject as? [String : AnyObject],
              let uploadedURLString = responseObjectDict.keys.first,
              let shoppables = responseObjectDict[uploadedURLString] as? [[String : AnyObject]] else {
                logString.append("logClarifaiSyteInitial error:\(error)")
                self.finishWith(text: logString as String)
                return
            }
            logString.append("logClarifaiSyteInitial response:\(response)\nresponseObject:\(responseObject ?? ""))")
            let viewBounds = self.view.bounds
            let viewWidth = viewBounds.size.width
            let viewHeight = viewBounds.size.height
            let imageView = UIImageView(frame: viewBounds)
            imageView.image = matchModel.lastScreenshot
            self.view.addSubview(imageView)
            for shoppable in shoppables {
                guard let b0 = shoppable["b0"] as? [Any],
                  let b1 = shoppable["b1"] as? [Any],
                  let b0x = b0[0] as? CGFloat,
                  let b0y = b0[1] as? CGFloat,
                  let b1x = b1[0] as? CGFloat,
                  let b1y = b1[1] as? CGFloat else {
                    logString.append("logClarifaiSyteInitial error parsing b0, b1")
                    break
                }
                print("b0x:\(b0x)  b0y:\(b0y)  b1x:\(b1x)  b1y:\(b1y)");
                let frame = CGRect(x: b0x * viewWidth, y: b0y * viewHeight, width: (b1x - b0x) * viewWidth, height: (b1y - b0y) * viewHeight)
                print("frame:\(NSStringFromCGRect(frame))");
                let shoppableView = UIView(frame: frame)
                shoppableView.backgroundColor = UIColor(white: 0, alpha: 0.20)
                shoppableView.layer.borderWidth = 1
                shoppableView.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor
                imageView.addSubview(shoppableView)
            }
            self.finishWith(text: logString as String)
        })
    }

    func finishWith(text: String) {
        DispatchQueue.main.async(execute: {
            self.activityIndicator.stopAnimating()
            self.resultantJsonLabel.text = text
            print(text)
        })
    }

}

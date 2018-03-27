//
//  LoadingViewController.swift
//  screenshot
//
//  Created by Corey Werner on 11/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class LoadingViewController: UIViewController {
    let loader = Loader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        loader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loader)
        loader.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loader.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loader.startAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        loader.stopAnimation()
    }
    
    
    func storeLoadingFailed(){
        let alert = UIAlertController.init(title: "error.database_cant_load.title".localized, message: "error.database_cant_load.message".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "error.database_cant_load.button.try_again".localized, style: .default, handler: { (a) in
            AppDelegate.shared.asyncLoadStore()
        }))
        alert.addAction(UIAlertAction.init(title: "error.database_cant_load.button.reset_app".localized, style: .default, handler: { (a) in
            let alert = UIAlertController.init(title: "error.database_cant_load.button.reset_app.title".localized, message: "error.database_cant_load.button.reset_app.message".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "error.database_cant_load.button.reset_app.button.reset".localized, style: .destructive, handler: { (a) in
                let _ = DataModel.sharedInstance.deleteDatabase()
                AppDelegate.shared.asyncLoadStore()
            }))
            alert.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction.init(title: "error.database_cant_load.button.contact_support".localized, style: .default, handler: { (a) in
           
            if  let mailURL = URL.init(string: "mailto://support@screenshopit.com"), UIApplication.shared.canOpenURL(mailURL) {
                UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
            } else if let url = URL.googleMailUrl(to: "support@screenshopit.com", body: "", subject: "Help, I can't enter the app"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }else{
                let alert = UIAlertController.init(title: nil, message: "Email support at: \n support@screenshopit.com".localized, preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}

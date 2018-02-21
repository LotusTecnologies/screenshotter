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
}

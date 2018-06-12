//
//  GameViewController.swift
//  screenshot
//
//  Created by Corey Werner on 2/21/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import SpriteKit

class GameViewController: BaseViewController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene else {
            return
        }
        
        let gameView = SKView()
        gameView.translatesAutoresizingMaskIntoConstraints = false
        gameView.ignoresSiblingOrder = true
        view.addSubview(gameView)
        gameView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        gameView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        gameView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        gameView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        scene.scaleMode = .aspectFill
        gameView.presentScene(scene)
    }
}

//
//  ScreenshotSimilarLooksViewController.swift
//  Screenshop
//
//  Created by Jonathan Rose on 8/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ScreenshotSimilarLooksViewController: UIViewController {

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
    }()
    
    static func collectionViewInteritemOffset() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let x: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        let y: CGFloat = .padding - shadowInsets.top - shadowInsets.bottom
        return CGPoint.init(x: x, y: y)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

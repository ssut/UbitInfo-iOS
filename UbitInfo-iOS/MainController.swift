//
//  MainController.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/20/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//

import UIKit

class MainController: UITabBarController {
    @IBOutlet var tabbar: UITabBar
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let offset: CGFloat = 7
        for item in tabbar.items {
            var i = item as UITabBarItem
            i.imageInsets = UIEdgeInsetsMake(offset, 0, -offset, 0)
            i.title = nil
            
            i.image = UIImage(named: "+.png")
        }
    }
}

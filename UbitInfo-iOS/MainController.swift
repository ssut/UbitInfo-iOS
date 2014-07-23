//
//  MainController.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/20/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//

import UIKit

var mainControllerLoadCompleted: Bool = false
class MainController: UITabBarController {
    @IBOutlet var tabbar: UITabBar!
    
    var hud: MBProgressHUD = MBProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let offset: CGFloat = 7.0
        for item in self.tabbar.items {
            var i = item as UITabBarItem
            i.imageInsets = UIEdgeInsetsMake(offset, 0, -offset, 0)
            i.title = nil
            i.image = UIImage(named: "+.png")
        }
        
        // HUD
        self.hud = MBProgressHUD(view: self.view)
        self.hud.labelText = localizedString("main.loggingIn")
        self.view.addSubview(hud)
        
        if let user = DataManager.instance.getData("user") as? Dictionary<String, String> {
            if let userId: String = user["userId"] {
                if let userPass: String = user["userPass"] {
                    if userId == "" || userPass == "" {
                        mainControllerLoadCompleted = true
                        return
                    }
                    self.hud.show(true)
                    HttpClient.instance.login(userId, userPass: userPass, callback: {
                        (success: Bool, error: String) in
                        if !success {
                            HttpClient.instance.logout()
                            println("Main: Login Failed")
                            
                            self.hud.customView = UIImageView(image: UIImage(named: "Close-Line.png"))
                            self.hud.mode = MBProgressHUDModeCustomView
                            self.hud.labelText = localizedString("main.loginFailed")
                            self.hud.hide(true, afterDelay: 0.7)
                        } else {
                            println("Main: Login Success")
                            
                            self.hud.customView = UIImageView(image: UIImage(named: "Checkmark.png"))
                            self.hud.mode = MBProgressHUDModeCustomView
                            self.hud.labelText = localizedString("main.loggedIn")
                            self.hud.hide(true, afterDelay: 0.7)
                        }
                        
                        mainControllerLoadCompleted = true
                    })
                } else {
                    mainControllerLoadCompleted = true
                    return
                }
            } else {
                mainControllerLoadCompleted = true
                return
            }
        } else {
            mainControllerLoadCompleted = true
            return
        }
    }
}

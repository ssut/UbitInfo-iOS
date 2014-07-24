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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tabBarSize: CGFloat = 45
        let offset: CGFloat = 3.0
        let width: CGFloat = self.view.frame.size.width
        let height: CGFloat = self.view.frame.size.height
        
        let tabBarItemIcon: Array = ["Notifications", "List-Boxes", "Calendar-Month", "Profile-Line"]
        
        self.tabBar.frame.origin.y = tabBarSize
        self.tabBar.frame = CGRectMake(0, height - tabBarSize, width, tabBarSize)
        var loop: Int = 0
        for item in self.tabBar.items {
            var i = item as UITabBarItem
            i.imageInsets = UIEdgeInsetsMake(offset, 0, -offset, 0)
            i.title = nil
            i.image = UIImage(named: tabBarItemIcon[loop] + ".png")
            i.enabled = false
            loop++
        }
        
        if let user = DataManager.instance.getData("user") as? Dictionary<String, String> {
            if let userId: String = user["userId"] {
                if let userPass: String = user["userPass"] {
                    if userId == "" || userPass == "" {
                        self.toggleTabBarEnabled(true)
                        mainControllerLoadCompleted = true
                        return
                    }
                    
                    SVProgressHUD.showWithStatus(localizedString("main.loggingIn"))
                    HttpClient.instance.login(userId, userPass: userPass, callback: {
                        (success: Bool, error: String) in
                        if !success {
                            HttpClient.instance.logout()
                            println("Main: Login Failed")
                            
                            SVProgressHUD.dismiss()
                            SVProgressHUD.showErrorWithStatus(localizedString("main.loginFailed"))
                        } else {
                            println("Main: Login Success")
                            
                            SVProgressHUD.dismiss()
                            SVProgressHUD.showSuccessWithStatus(localizedString("main.loggedIn"))
                        }
                        
                        self.toggleTabBarEnabled(true)
                        mainControllerLoadCompleted = true
                    })
                } else {
                    self.toggleTabBarEnabled(true)
                    mainControllerLoadCompleted = true
                    return
                }
            } else {
                self.toggleTabBarEnabled(true)
                mainControllerLoadCompleted = true
                return
            }
        } else {
            self.toggleTabBarEnabled(true)
            mainControllerLoadCompleted = true
            return
        }
    }
    
    func toggleTabBarEnabled(enabled: Bool) {
        for item in self.tabBar.items {
            var i = item as UITabBarItem
            i.enabled = enabled
        }
    }}

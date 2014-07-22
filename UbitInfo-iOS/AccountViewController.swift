//
//  AccountViewController.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/20/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//

import Foundation
import UIKit

class AccountViewController: XLFormViewController {
    var values: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
    var hud: MBProgressHUD = MBProgressHUD()
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        
        self.view.endEditing(true)
        
        // HUD
        self.hud = MBProgressHUD(view: self.view)
        self.view.addSubview(hud)
        
        if HttpClient.instance.loggedIn {
            drawUserView()
        } else {
            drawGuestView()
        }
    }
    
    func updateFormValues() {
        let sectionCount: Int = self.form.formSections.count
        for index in 0..<sectionCount {
            var section = self.form.formSectionAtIndex(UInt(index))
            if !section.isMultivaluedSection {
                let rowCount: Int = section.formRows.count
                for rowIndex in 0..<rowCount {
                    var row: XLFormRowDescriptor = section.formRows[rowIndex] as XLFormRowDescriptor
                    if row.tag != "" {
                        let tag = row.tag as String
                        self.values[tag] = row.value ? row.value : nil
                    }
                }
            } else {
                var multiValuedValuesArray: NSMutableArray = NSMutableArray()
                let rowCount: Int = section.formRows.count
                for rowIndex in 0..<rowCount {
                    var row: XLFormRowDescriptor = section.formRows[rowIndex] as XLFormRowDescriptor
                    multiValuedValuesArray.addObject(row.value)
                }
                let tag = section.multiValuedTag as String
                self.values[tag] = multiValuedValuesArray
            }
        }
    }
    
    func drawGuestView() {
        var form: XLFormDescriptor = XLFormDescriptor.formDescriptorWithTitle("Login")
        var section: XLFormSectionDescriptor = XLFormSectionDescriptor.formSection() as XLFormSectionDescriptor
        var row: XLFormRowDescriptor
        
        form.addFormSection(section)
        
        row = XLFormRowDescriptor.formRowDescriptorWithTag("id", rowType: "text", title: "")
        row.cellConfigAtConfigure.setObject("UbitInfo ID", forKey: "textField.placeholder")
        section.addFormRow(row)
        
        row = XLFormRowDescriptor.formRowDescriptorWithTag("password", rowType: "password", title: "")
        row.cellConfigAtConfigure.setObject("UbitInfo PW", forKey: "textField.placeholder")
        section.addFormRow(row)
        
        self.form = form
        
        var button: UIBarButtonItem = UIBarButtonItem(title: "Login", style: UIBarButtonItemStyle.Plain, target: self, action: "login:")
        self.navigationItem.rightBarButtonItem = button
        
        self.viewWillAppear(false)
    }
    
    func drawUserView() {
        var button: UIBarButtonItem = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.Plain, target: self, action: "logout:")
        self.navigationItem.rightBarButtonItem = button
        
        var form: XLFormDescriptor = XLFormDescriptor.formDescriptorWithTitle("Account")
        var section: XLFormSectionDescriptor = XLFormSectionDescriptor.formSection() as XLFormSectionDescriptor
        var row: XLFormRowDescriptor
        
        form.addFormSection(section)
        
        row = XLFormRowDescriptor.formRowDescriptorWithTag("pfImage", rowType: "textView", title: "")
        section.addFormRow(row)
        
        var imageView = UIImageView()
        imageView.imageURL = NSURL(string: "https://ubit.info/@images/jubility/10_0")
        imageView.frame = CGRectMake(0, 0, 80, 80)
        imageView.contentMode = UIViewContentMode.Center
        self.tableView.tableHeaderView = imageView
        
        // watch imageView.image -- KVO has a problem at removeObserver
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while true {
                println(imageView)
                if imageView != nil {
                    if imageView.image != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            imageView.image = scaleImage(imageView.image, CGSizeMake(80, 80))
                            imageView.setNeedsDisplay()
                        }
                        break
                    }
                } else {
                    break
                }
                
                NSThread.sleepForTimeInterval(0.1)
            }
            return
        }
        
        self.form = form
        
        getUserInfo()
        self.viewWillAppear(false)
    }
    
    func login(sender: AnyObject) {
        updateFormValues()
        
        // check id field
        if !self.values["id"] || (self.values["id"] as AnyObject? as? String) == "" {
            var message = UIAlertView(title: "Error", message: "Please input Ubitinfo ID", delegate: self, cancelButtonTitle: "OK")
            message.show()
        }
        
        // check password field
        else if !self.values["password"] || (self.values["password"] as AnyObject? as? String) == "" {
            var message = UIAlertView(title: "Error", message: "Please input Ubitinfo PW", delegate: self, cancelButtonTitle: "OK")
            message.show()
        }

        // login
        else {
            let userId = self.values["id"] as AnyObject? as? String
            let userPass = self.values["password"] as AnyObject? as? String
            
            self.hud.mode = MBProgressHUDModeIndeterminate
            self.hud.show(true)
            HttpClient.instance.login(userId!, userPass: userPass!, callback: {
                (success: Bool, message: String) in
                if !success {
                    self.hud.mode = MBProgressHUDModeText
                    self.hud.labelText = message
                    self.hud.hide(true, afterDelay: 1)
                } else {
                    self.hud.customView = UIImageView(image: UIImage(named: "Checkmark.png"))
                    self.hud.mode = MBProgressHUDModeCustomView
                    self.hud.labelText = "Login Success"
                    self.hud.hide(true, afterDelay: 1)
                    
                    self.form = nil
                    self.reloadFormRow(nil)
                    self.tableView.reloadData()
                    self.viewDidLoad()
                    self.viewWillAppear(true)
                    self.view.setNeedsDisplay()
                }
            })
        }
    }
    
    func logout(sender: AnyObject) {
        HttpClient.instance.logout()
        self.tableView.tableHeaderView = nil
        self.form = nil
        self.reloadFormRow(nil)
        self.tableView.reloadData()
        self.viewDidLoad()
        self.viewWillAppear(true)
        self.view.setNeedsDisplay()
    }
    
    func getUserInfo() {
        HttpClient.instance.getUserQuery(QUERY_INFO,
            queryParam: nil,
            callback: {
                (success: Bool, data: Dictionary<String, AnyObject?>?) in
                println(success)
            })
    }
}

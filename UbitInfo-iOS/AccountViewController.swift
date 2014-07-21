//
//  AccountViewController.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/20/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//

import UIKit

class AccountViewController: XLFormViewController {
    var values: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
    var hud: MBProgressHUD = MBProgressHUD()
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        
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
            var section = self.form.formSectionAtIndex(index)
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
            
            self.hud.show(true)
            HttpClient.instance.login(userId!, userPass: userPass!, callback: {
                (success: Bool, message: String) in
                if !success {
                    self.hud.mode = MBProgressHUDModeText
                    self.hud.labelText = message
                    self.hud.hide(true, afterDelay: 3)
                } else {
                    self.hud.customView = UIImageView(image: UIImage(named: "Checkmark.png"))
                    self.hud.mode = MBProgressHUDModeCustomView
                    self.hud.labelText = "Completed"
                    self.hud.hide(true, afterDelay: 3)
                    
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
        self.tableView.reloadData()
        self.viewDidLoad()
        self.viewWillAppear(true)
        self.view.setNeedsDisplay()
    }
}

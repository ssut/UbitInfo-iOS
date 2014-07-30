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
    var tableValues: Array<Array<String>> = Array<Array<String>>()
    
    @IBOutlet var userSimpleInfoName: UILabel!
    @IBOutlet var userSimpleInfoJubilityImage: UIImageView!
    @IBOutlet var userSimpleInfoJubilityIndicator: UIActivityIndicatorView!
    @IBOutlet var userSimpleInfoUpdated: UILabel!
    @IBOutlet var userSimpleInfo: UIView!
    override func viewDidLoad()  {
        super.viewDidLoad()
        self.view.endEditing(true)
        self.tableView.tableHeaderView = nil
        self.refreshControl = nil
        
        if HttpClient.instance.loggedIn {
            self.tableView!.addSubview(refreshControl)
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
        var form: XLFormDescriptor = XLFormDescriptor.formDescriptorWithTitle(localizedString("account.login"))
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
        
        var button: UIBarButtonItem = UIBarButtonItem(title: localizedString("account.login"), style: UIBarButtonItemStyle.Plain, target: self, action: "login:")
        self.navigationItem.rightBarButtonItem = button
        
        self.viewWillAppear(false)
    }
    
    func drawUserView() {
        var button: UIBarButtonItem = UIBarButtonItem(title: localizedString("account.logout"), style: UIBarButtonItemStyle.Plain, target: self, action: "logout:")
        self.navigationItem.rightBarButtonItem = button
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: "getUserInfoWithControl:", forControlEvents: UIControlEvents.ValueChanged)
        
        self.form = nil
        
        getUserInfo(true)
        self.tableView.tableHeaderView = self.userSimpleInfo
        self.tableView.setNeedsDisplay()
        self.viewWillAppear(false)
    }
    
    func login(sender: AnyObject) {
        updateFormValues()
        
        // check id field
        if !self.values["id"] || (self.values["id"] as AnyObject? as? String) == "" {
            var message = UIAlertView(title: localizedString("global.error"), message: localizedString("account.error.inputID"), delegate: self, cancelButtonTitle: "OK")
            message.show()
        }
        
        // check password field
        else if !self.values["password"] || (self.values["password"] as AnyObject? as? String) == "" {
            var message = UIAlertView(title: localizedString("global.error"), message: localizedString("account.error.inputPW"), delegate: self, cancelButtonTitle: "OK")
            message.show()
        }

        // login
        else {
            let userId = self.values["id"] as AnyObject? as? String
            let userPass = self.values["password"] as AnyObject? as? String
            
            SVProgressHUD.show()
            HttpClient.instance.login(userId!, userPass: userPass!, callback: {
                (success: Bool, message: String) in
                if !success {
                    SVProgressHUD.showErrorWithStatus(message)
                } else {
                    SVProgressHUD.showSuccessWithStatus(localizedString("account.loginOK"))
                    
                    self.form = nil
                    self.reloadFormRow(nil)
                    self.viewDidLoad()
                    self.tableView.reloadData()
                    self.viewWillAppear(true)
                    self.view.setNeedsDisplay()
                }
            })
        }
    }
    
    func logout(sender: AnyObject) {
        HttpClient.instance.logout()
        self.form = nil
        self.reloadFormRow(nil)
        self.viewDidLoad()
        self.tableView.reloadData()
        self.viewWillAppear(true)
        self.view.setNeedsDisplay()
    }
    
    func getUserInfo(direct: Bool) {
        self.userSimpleInfoJubilityImage.image = nil
        self.userSimpleInfoName.text = ""
        
        userSimpleInfoJubilityIndicator.startAnimating()
        self.refreshControl.beginRefreshing()
        HttpClient.instance.getUserQuery(QUERY_INFO,
            queryParam: nil,
            callback: {
                (success: Bool, message: String, data: Dictionary<String, JSONValue?>?) in
                if !success {
                    SCLAlertView().showTitle(self,
                        title: localizedString("global.error"),
                        subTitle: message,
                        duration: 0,
                        completeText: "OK",
                        style: .Error)
                    return
                }
                
                self.drawUserInfo(data as Dictionary<String, JSONValue?>)
                self.refreshControl.endRefreshing()
            }
        )
    }
    
    func drawUserInfo(data: Dictionary<String, JSONValue?>) {
        userSimpleInfoUpdated.text = "Updated at " + NSDate().toString("yyyy-MM-dd HH:mm:ss")
        
        let jubilityImagePath = data["info"]!!["jubility_image"].string as String
        let jubilityImageURL: NSURL = buildURL(jubilityImagePath).nsurl

        SDWebImageDownloader.sharedDownloader().downloadImageWithURL(
            jubilityImageURL,
            options: nil,
            progress: nil,
            completed: {
                (image: UIImage!, data: NSData!, error: NSError!, finished: Bool) in
                if image != nil && finished == true {
                        self.userSimpleInfoJubilityImage.image = image
                        self.userSimpleInfoJubilityIndicator.stopAnimating()
                }
            }        )
        
        self.userSimpleInfoName.text = data["info"]!!["player_name"].string as String
        
        println(data)
        self.tableValues = Array<Array<String>>()
        
        self.tableValues.append(["a", "b", "c"])
        self.tableView.reloadData()
    }
    
    func getUserInfoWithControl(sender: AnyObject) {
        getUserInfo(false)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        var sections: Int = 0
        if HttpClient.instance.loggedIn {
            sections = 1
        } else {
            sections = super.numberOfSectionsInTableView(tableView)
        }
        
        return sections
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        var rows: Int = 0
        if HttpClient.instance.loggedIn {
            rows = self.tableValues.count
        } else {
            rows = super.tableView(tableView, numberOfRowsInSection: section)
        }
        
        return rows
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        var cell: AccountViewTableCell?
        if HttpClient.instance.loggedIn {
            let reuseIdentifier: String = "Cell"
            cell = tableView?.dequeueReusableCellWithIdentifier(reuseIdentifier) as? AccountViewTableCell
            if cell == nil {
                tableView.registerNib(UINib(nibName: "AccountViewTableCell", bundle: nil), forCellReuseIdentifier: "Cell")
                cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? AccountViewTableCell
            }
            
            var item: Array<String> = self.tableValues[indexPath.row]

            cell!.leftLabel.text = "adsf"    
            cell!.userInteractionEnabled = false
        } else {
            var cell: UITableViewCell?
            cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
        if HttpClient.instance.loggedIn {
            cell.setNeedsUpdateConstraints()
            cell.setNeedsLayout()
        } else {
            super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
        }
    }
}

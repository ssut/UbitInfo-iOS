//
//  FirstViewController.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/19/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//

import UIKit

class UpdateViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var refreshControl: UIRefreshControl!
    var dataArray = NSMutableArray()
    var lastUpdate: NSDate = NSDate()
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: "reload:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView!.addSubview(refreshControl)
        
        reload(true)
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray[section].count
    }
    
    func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        if section == 0 {
            return localizedString("update.title")
        }
        
        return ""
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return self.dataArray.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let reuseIdentifier = "Cell"
        var cell:UITableViewCell? =
        tableView?.dequeueReusableCellWithIdentifier(reuseIdentifier) as? UITableViewCell
        if !cell {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle,
                reuseIdentifier: reuseIdentifier)
        }
        var section: NSArray = dataArray[indexPath.section] as NSArray
        var item = section[indexPath.row] as JSONStatus
        
        let suffix: String = (item.req_result ? localizedString("update.stat_ok") :
                             (item.req_processing ? localizedString("update.stat_doing") :
                             (item.req_checked ? localizedString("update.stat_fail") :
                              localizedString("update.stat_ready"))))
        cell!.detailTextLabel.text = item.created_at.toString("HH:mm ") + suffix
        cell!.textLabel.text = item.bind_id
        
        return cell
    }
    
    func refresh(sender: AnyObject) {
        reload(false)
    }
    
    func reload(direct: Bool) {
        let zero: UInt = 0
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while true {
                if mainControllerLoadCompleted {
                    break
                }

                println("waiting for login")
                NSThread.sleepForTimeInterval(1)
            }
            
            if direct {
                dispatch_async(dispatch_get_main_queue()) {
                    SVProgressHUD.show()
                    return
                }
            }
            
           HttpClient.newManager().GET(URL_STATUS,
                parameters: nil,
                success: {
                    (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                    var items = NSMutableArray()
                    let json = JSONValue(response)["data"]
                    if !json {
                        SCLAlertView().showError(self, title: "Parse Error", subTitle: "Couldn't parser retrieved data.")
                    } else if let elements = json["updates"].array {
                        for item:JSONValue in elements {
                            var status = JSONStatus(
                                updated_at: item["updated_at"].string as String,
                                created_at: item["created_at"].string as String,
                                req_checked: item["req_checked"].bool as Bool,
                                req_auto: item["req_auto"].bool as Bool,
                                req_processing: item["req_processing"].bool as Bool,
                                req_result: item["req_result"].bool as Bool,
                                bind_id: item["bind_id"].string as String
                            )
                            items.addObject(status)
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        SVProgressHUD.dismiss()
                        self.refreshControl.endRefreshing()
                        self.dataArray.removeAllObjects()
                        if json {
                            self.dataArray.addObject(items)
                            self.tableView.reloadData()
                        }
                        
                        return
                    }
                },
                failure: {
                    (operation: AFHTTPRequestOperation!,error: NSError!) in
                    dispatch_async(dispatch_get_main_queue()) {
                        SVProgressHUD.dismiss()
                        self.refreshControl.endRefreshing()
                        SCLAlertView().showTitle(self,
                            title: localizedString("global.error.network.title"),
                            subTitle: localizedString("global.error.network.content"),
                            duration: 0,
                            completeText: "Dismiss",
                            style: .Error)
                        return
                    }
            })
            
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


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
            return "Recent Updates"
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
            cell = UITableViewCell(style: UITableViewCellStyle.Value2,
                reuseIdentifier: reuseIdentifier)
        }
        var section: NSArray = dataArray[indexPath.section] as NSArray
        var item = section[indexPath.row] as JSONStatus
        
        let formatter: NSDateFormatter = NSDateFormatter()
        formatter.dateFormat = " HH:mm"
        let prefix: String = (item.req_result ? "OK" : (item.req_processing ? "DOING" : (item.req_checked ? "FAIL" : "READY" )))
        cell!.textLabel.text = prefix + formatter.stringFromDate(item.created_at)
        cell!.detailTextLabel.text = item.bind_id
        
        return cell
    }
    
    func refresh(sender: AnyObject) {
        reload(false)
    }
    
    func reload(direct: Bool) {
        let zero: UInt = 0
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, zero)) {
            while true {
                if mainControllerLoadCompleted {
                    break
                }

                println("waiting for login")
                NSThread.sleepForTimeInterval(0.2)
            }
            
            if direct {
                dispatch_async(dispatch_get_main_queue()) {
                    MBProgressHUD.showHUDAddedTo(self.view, animated: true)
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
                        TSMessage.showNotificationInViewController(self, title: "Data parse error", subtitle: "Couldn't parse retrieved data. data is malformed?", type: TSMessageNotificationType.Error)
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
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
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
                    TSMessage.showNotificationInViewController(self, title: "Network error", subtitle: "Couldn't connect to the server. Check your network connection.", type: TSMessageNotificationType.Error)
                    println(error.description)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        
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


//
//  DataManager.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/21/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//

import Foundation

class DataManager {
    struct Static {
        static var token: dispatch_once_t = 0
        static var instance: DataManager?
    }
    
    class var instance: DataManager {
    dispatch_once(&Static.token) { Static.instance = DataManager() }
        return Static.instance!
    }
    
    var defaults: NSUserDefaults
    init() {
        self.defaults = NSUserDefaults.standardUserDefaults()
    }
    
    func loadData() {
        self.defaults = NSUserDefaults.standardUserDefaults()
    }
    
    func getData(key: String) -> AnyObject? {
        if let data: AnyObject = self.defaults.objectForKey(key) {
            return data
        }
        return nil
    }
    
    func setData(key: String, data: AnyObject) {
        self.defaults.setObject(data, forKey: key)
        self.saveData()
    }
    
    func saveData() {
        self.defaults.synchronize()
    }
}

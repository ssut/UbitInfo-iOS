//
//  JSON.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/20/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//

import Foundation

class JSONStatus {
    var updated_at: NSDate
    var created_at: NSDate
    var req_checked: Bool
    var req_auto: Bool
    var req_processing: Bool
    var req_result: Bool
    var bind_id: String
    
    init(updated_at: String, created_at: String, req_checked: Bool, req_auto: Bool, req_processing: Bool,
        req_result: Bool, bind_id: String) {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-DD'T'HH:mm:ssz"
        
        self.updated_at = dateFormatter.dateFromString(updated_at)
        self.created_at = dateFormatter.dateFromString(created_at)
        self.req_checked = req_checked
        self.req_auto = req_auto
        self.req_processing = req_processing
        self.req_result = req_result
        self.bind_id = bind_id
    }

}

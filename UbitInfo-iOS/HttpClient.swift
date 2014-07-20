//
//  HttpClient.swift
//  UbitInfo-iOS
//
//  Created by ssut on 7/19/14.
//  Copyright (c) 2014 ssut. All rights reserved.
//
import Foundation

let CLIENT_NAME: String = "UbitInfo-iOS"
let URL_PREFIX: String = "http://ubit.info:3000"
let URL_STATUS = URL_PREFIX + "/!/status"

class HttpClient {
    struct Static {
        static var token: dispatch_once_t = 0
        static var instance: HttpClient?
    }
    
    class var instance: HttpClient {
        dispatch_once(&Static.token) { Static.instance = HttpClient() }
        return Static.instance!
    }
    
    var manager: AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
    
    init() {
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.requestSerializer.setValue(CLIENT_NAME, forHTTPHeaderField: "X-API-Host")
        manager.securityPolicy.allowInvalidCertificates = true
    }
}

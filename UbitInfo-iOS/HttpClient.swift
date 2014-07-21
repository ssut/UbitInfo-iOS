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
let URL_LOGIN = URL_PREFIX + "/!/user/entry"
let URL_TOKEN = URL_PREFIX + "/!/token"

let SUCCESS = ""
let ERR_NETWORK = "Network error"
let ERR_UNKNOWN = "Unknown error"
let ERR_FETCH_TOKEN = "Failed to fetch access token"
let ERR_INVALID_USER = "Username or password is incorrect"
let ERR_NO_USER = "User not found"
let ERR_INVALID_PASS = "Password is invalid"

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
    var loggedIn: Bool = false
    
    init() {
        var contentTypes: NSMutableSet = NSMutableSet()
        contentTypes.addObject("application/json")
        contentTypes.addObject("text/html")
        
        manager.requestSerializer.setValue(CLIENT_NAME, forHTTPHeaderField: "X-API-Host")
        manager.responseSerializer.acceptableContentTypes = contentTypes
        manager.securityPolicy.allowInvalidCertificates = true
    }
    
    func getToken(callback: (String) -> Void) {
        HttpClient.instance.manager.GET(URL_TOKEN,
            parameters: nil,
            success: {
                (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                var json = JSONValue(response)
                var token = ""
                if let t = json["token"].string {
                    token = t
                }
                callback(token)
                return Void()
            },
            failure: {
                (operation: AFHTTPRequestOperation!, error: NSError!) in
                println(error)
                callback("")
                return Void()
            }
        )
        
    }
    
    func login(userId: String, userPass: String, callback: (Bool, String) -> Void) {
        if userId == "" || userPass == "" {
            return
        }
        
        getToken({ (token: String) in
            if token == "" {
                callback(false, ERR_FETCH_TOKEN)
                return Void()
            }
            
            var params = [
                "authenticity_token": token,
                "uid": userId,
                "upw": userPass
            ]
            
            HttpClient.instance.manager.POST(URL_LOGIN,
                parameters: params,
                success: {
                    (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                    var json = JSONValue(response)
                    var code = -1
                    if let c = json["code"].integer {
                        if c == 0 {
                            // set cookie to client -- very dirty code block
                            var cookies =
                            NSHTTPCookie.cookiesWithResponseHeaderFields(operation.response.allHeaderFields?, forURL: NSURL(string: URL_PREFIX))
                            for cookie in cookies {
                                    NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(cookie as NSHTTPCookie)
                            }
                            var config = NSURLSessionConfiguration.defaultSessionConfiguration()
                            config.HTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()

                            // save login data
                            let user: Dictionary<String, String> = [
                                "userId": userId,
                                "userPass": userPass
                            ]
                            DataManager.instance.setData("user", data: user)
                            HttpClient.instance.loggedIn = true
                            callback(true, SUCCESS)
                        } else if c == 1 {
                            callback(false, ERR_NO_USER)
                        } else if c == 2 {
                            callback(false, ERR_INVALID_USER)
                        } else if c == 3 {
                            callback(false, ERR_INVALID_PASS)
                        } else {
                            callback(false, ERR_UNKNOWN)
                        }
                    } else {
                        callback(false, ERR_UNKNOWN)
                    }
                    return Void()
                },
                failure: {
                    (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println(error)
                    callback(false, ERR_NETWORK)
                    return Void()
                }
            )
        })
    }
    
    func logout() {
        self.loggedIn = false
        DataManager.instance.setData("user", data: [
            "userId": "",
            "userPass": ""
        ])
    }
    
    func getUserInfo() {
        if !self.loggedIn {
            return
        }
        
        
    }
}

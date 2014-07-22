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
let URL_CHECK_LOGGED = URL_PREFIX + "/!/check"
let URL_TOKEN = URL_PREFIX + "/!/token"
let URL_USER_INFO = URL_PREFIX + "/%@/info"

let QUERY_INFO = "info"
let QUERY_RECENT = ""
let QUERY_ALL = "all"

let SUCCESS = ""
let ERR_NETWORK = "Network error"
let ERR_UNKNOWN = "Unknown error"
let ERR_FETCH_TOKEN = "Failed to fetch access token"
let ERR_INVALID_USER = "Username or password is incorrect"
let ERR_NO_USER = "User not found"
let ERR_INVALID_PASS = "Password is invalid"
let ERR_INVALID_DATE_FORMAT = "Invalid date format"
let ERR_DATE = "Start date is greater than end date"
let ERR_NO_DATE = "Data not exists"

var UBITINFO_ACCESS_TOKEN: String = ""
class HttpClient {
    struct Static {
        static var token: dispatch_once_t = 0
        static var instance: HttpClient?
    }
    
    class var instance: HttpClient {
        dispatch_once(&Static.token) {
            Static.instance = HttpClient()
        }
        return Static.instance!
    }
    
    var manager: AFHTTPRequestOperationManager?
    var loggedIn: Bool = false
    
    init() {
        if self.manager == nil {
            self.manager = HttpClient.newManager()
        }
    }
    
    class func newManager() -> AFHTTPRequestOperationManager {
        var m: AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()
        m.requestSerializer.setValue(CLIENT_NAME, forHTTPHeaderField: "X-API-Host")
        m.requestSerializer.setValue(UBITINFO_ACCESS_TOKEN, forHTTPHeaderField: "X-API-Token")
        m.securityPolicy.allowInvalidCertificates = true
        
        return m
    }
    
    func updateToken(token: String) {
        let token = token.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        UBITINFO_ACCESS_TOKEN = token
        HttpClient.instance.manager?.requestSerializer.setValue(UBITINFO_ACCESS_TOKEN, forHTTPHeaderField: "X-API-Token")
    }
    
    func deleteToken() {
        HttpClient.instance.updateToken("")
    }
    
    func getToken(callback: (String) -> Void) {
        HttpClient.instance.manager?.GET(URL_TOKEN,
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
            callback(false, "")
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
            
            HttpClient.instance.manager?.POST(URL_LOGIN,
                parameters: params,
                success: {
                    (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                    var json = JSONValue(response)
                    var code = -1
                    if let c = json["code"].integer {
                        if c == 0 {
                            // access token for persistent seession
                            let userToken: String = json["token"].string as String
                            
                            // save login data
                            let user: Dictionary<String, String> = [
                                "userId": userId,
                                "userPass": userPass
                            ]
                            DataManager.instance.setData("user", data: user)
 
                            HttpClient.instance.updateToken(userToken)
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
        
        // delete cookies
        var cookies: Array = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies
        for cookie in cookies {
            let c: NSHTTPCookie = cookie as NSHTTPCookie
            NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(c)
        }
        
        var config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        
        // drop access token
        HttpClient.instance.deleteToken()
    }
    
    func checkLoggedIn(callback: (Bool, String) -> Void) {
        if !self.loggedIn {
            callback(false, "")
            return
        }

        HttpClient.instance.manager?.GET(URL_CHECK_LOGGED,
            parameters: nil,
            success: {
                (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                var json = JSONValue(response)
                if let logged = json["logged_in"].bool {
                    if logged {
                        let userId = json["user_id"].string as String
                        callback(true, userId)
                    } else {
                        HttpClient.instance.logout()
                        callback(false, "")
                    }
                }
                return Void()
            }, failure: {
                (operation: AFHTTPRequestOperation!, error: NSError!) in
                println(error)
                callback(false, "")
                return Void()
            }
        )
    }
    
    func getUserQuery(query: String, queryParam: Array<String>?, callback: (Bool, String, Dictionary<String, AnyObject?>?) -> Void) {
        HttpClient.instance.checkLoggedIn({
            (loggedIn: Bool, userId: String) in
            if !loggedIn {
                callback(false, ERR_NO_USER, nil)
                return
            }
            
            var url: String = ""
            if query == QUERY_INFO {
                url = String(format: URL_USER_INFO, userId)
            }
            HttpClient.instance.manager?.GET(url,
                parameters: nil,
                success: {
                    (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                    var json = JSONValue(response)
                    if let code = json["code"].integer {
                        /*
                            0: success
                            1: user not found
                            2: invalid date format
                            3: start date is greater than end date
                            4: data not exists
                        */
                        if code == 1 {
                            callback(false, ERR_NO_USER, nil)
                            return
                        } else if code == 2 {
                            callback(false, ERR_INVALID_DATE_FORMAT, nil)
                            return
                        } else if code == 3 {
                            callback(false, ERR_DATE, nil)
                            return
                        } else if code == 4 {
                            callback(false, ERR_NO_DATE, nil)
                            return
                        }
                        
                        var userInfo: JSONUserInfo = JSONUserInfo(code: code, data: nil)
                        if let data = json["data"].object {
                            var infoData: Dictionary<String, AnyObject?> = Dictionary<String, AnyObject?>()
                            
                            infoData["data"] = nil
                            if let diff = data["diff"]?.object {
                                infoData["diff"] = [
                                    "exc_diff": diff["exc_diff"]?.integer as Int,
                                    "fc_diff": diff["fc_diff"]?.integer as Int,
                                    "jubility10": diff["jubility10"]?.double as Double,
                                    "jubility9": diff["jubility9"]?.double as Double,
                                    "rank_diff": diff["rank_diff"]?.integer as Int,
                                    "tbs_diff": diff["tbs_diff"]?.integer as Int,
                                    "tune_diff": diff["tune_diff"]?.integer as Int
                                ]
                            }
                            
                            if let info = data["info"]?.object {
                                infoData["info"] = [
                                    "date": info["date"]?.string as String,
                                    "player_name": info["player_name"]?.string as String,
                                    "player_title": info["player_title"]?.string as String,
                                    "player_marker": info["player_marker"]?.integer as Int,
                                    "player_background": info["player_background"]?.integer as Int,
                                    "player_team": info["player_team"]?.string as String,
                                    "play_tune": info["play_tune"]?.integer as Int,
                                    "play_fc": info["play_fc"]?.integer as Int,
                                    "play_exc": info["play_exc"]?.integer as Int,
                                    "play_tbs": info["play_tbs"]?.integer as Int,
                                    "play_tbs_rank": info["play_tbs_rank"]?.integer as Int,
                                    "jubility": info["jubility"]?.double as Double,
                                    "jubility_change": info["jubility_change"]?.double as Double,
                                    "play_date": info["play_date"]?.string? as String,
                                    "play_country": info["play_country"]?.string as String,
                                    "play_place": info["play_place"]?.string as String,
                                    "jubility_image": info["jubility_image"]?.string as String,
                                    "marker_image": info["marker_image"]?.string as String,
                                    "background_image": info["background_image"]?.string as String,
                                    "update_doing": info["update_doing"]?.bool as Bool
                                ]
                            }
                            
                            callback(true, SUCCESS, infoData)
                            return
                        }
                    }
                    callback(false, ERR_UNKNOWN, nil)
                },
                failure: {
                    (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println(error)
                    callback(false, ERR_NETWORK, nil)
                }
            )
        })
    }
}

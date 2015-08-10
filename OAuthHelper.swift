//
//  OAuthHelper.swift
//  OneCampus
//
//  Created by Yao Ming Huang on 2015/6/16.
//  Copyright (c) 2015年 Yao Ming Huang. All rights reserved.
//

import Foundation
//import SwiftyJSON

public class OAuthHelper {
    
    static let ServiceAuthorize: String = "https://auth.ischool.com.tw/oauth/authorize.php"
    
    static let ServiceExchangeAccessToken: String = "https://auth.ischool.com.tw/oauth/token.php"
    
    static let ServiceME: String = "https://auth.ischool.com.tw/services/me.php"
    
    var client_id: String!
    var client_secret: String!
    
    public var redirectUrl: String!
    
    public var scope: String!
    
    public var clientID: String {
        return client_id
    }
    
    public var clientSecret: String {
        return client_secret
    }
    
    public func getAuthorizeUrl() -> String {
        return "\(OAuthHelper.ServiceAuthorize)?client_id=\(self.clientID)&response_type=code&state=redirect_uri%3A%2F&redirect_uri=\(self.redirectUrl)&lang=zh-tw&scope=\(self.scope)"
    }
    
    public func getAuthorizeUrl(linkSignIn:String) -> String {
        return "\(OAuthHelper.ServiceAuthorize)?linkSignIn=\(linkSignIn)&client_id=\(self.clientID)&response_type=code&state=redirect_uri%3A%2F&redirect_uri=\(self.redirectUrl)&lang=zh-tw&scope=\(self.scope)"
    }
    
    public func getAccessTokenAndRefreshToken(code: String, inout error: NSError?) -> (String, String)!{
        
        let before = CFAbsoluteTimeGetCurrent()
        
        let token = HttpClient.Get(getExchangeAccessTokenUrl(code), err: &error)
        
        let span = CFAbsoluteTimeGetCurrent() - before
        println("Get Access Token Time：\(span)")
        
        var json: JSON = JSON(data: token!)
        
        if let access = json["access_token"].string, let refresh = json["refresh_token"].string {
            return (access, refresh)
        } else {
            return nil
        }
    }
    
    public func renewAccessToken(refreshToken: String, inout error: NSError?) -> (String, String)!{
        let url = "\(OAuthHelper.ServiceExchangeAccessToken)?client_id=\(self.clientID)&client_secret=\(self.clientSecret)&redirect_uri=\(self.redirectUrl)&refresh_token=\(refreshToken)&grant_type=refresh_token&response_type=token"
        
        let before = CFAbsoluteTimeGetCurrent()
        
        let token = HttpClient.Get(url, err: &error)
        
        let span = CFAbsoluteTimeGetCurrent() - before
        println("Get Access Token Time：\(span)")
        
        let str = NSString(data: token!, encoding: NSUTF8StringEncoding)
        
        var json: JSON = JSON(data: token!)
        
        if let access = json["access_token"].string, let refresh = json["refresh_token"].string {
            return (access, refresh)
        } else {
            error = NSError(domain: "auth.ischool.com.tw", code: 1,
                userInfo: ["RawUrl": url, NSURLErrorKey: url,NSLocalizedDescriptionKey: json["error_description"].string!])
            
            return nil
        }
    }
    
    public func me(accessToken access: String) -> String {
        let url = "\(OAuthHelper.ServiceME)?access_token=\(access)"
        
        var error: NSError?
        let rsp = HttpClient.Get(url, err: &error)
        var json: JSON = JSON(data: rsp!)
        
        return json["uuid"].string!
    }
    
    private func getExchangeAccessTokenUrl(code: String) -> String {
        return "\(OAuthHelper.ServiceExchangeAccessToken)?grant_type=authorization_code&client_id=\(self.clientID)&client_secret=\(self.clientSecret)&redirect_uri=\(self.redirectUrl)&code=\(code)"
    }
    
    init(clientId cid: String, clientSecret cs: String, redirectUrl ru: String = "http://_blank", scope s: String = "User.Mail,User.BasicInfo,1Campus.Notification.Read,1Campus.Notification.Send,*:sakura") {
        self.client_id = cid
        self.client_secret = cs
        self.redirectUrl = ru
        self.scope = s
    }
}
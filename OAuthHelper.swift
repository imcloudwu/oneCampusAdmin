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
    
    public func getAccessTokenAndRefreshToken(code: String) throws -> (String, String){
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        
        let before = CFAbsoluteTimeGetCurrent()
        
        let token: NSData?
        do {
            token = try HttpClient.Get(getExchangeAccessTokenUrl(code))
        } catch let error1 as NSError {
            error = error1
            token = nil
        }
        
        let span = CFAbsoluteTimeGetCurrent() - before
        print("Get Access Token Time：\(span)")
        
        var json: JSON = JSON(data: token!)
        
        if let access = json["access_token"].string, let refresh = json["refresh_token"].string {
            return (access, refresh)
        } else {
            throw error
        }
    }
    
    public func renewAccessToken(refreshToken: String) throws -> (String, String){
        let url = "\(OAuthHelper.ServiceExchangeAccessToken)?client_id=\(self.clientID)&client_secret=\(self.clientSecret)&redirect_uri=\(self.redirectUrl)&refresh_token=\(refreshToken)&grant_type=refresh_token&response_type=token"
        
        let before = CFAbsoluteTimeGetCurrent()
        
        let token: NSData?
        do {
            token = try HttpClient.Get(url)
        } catch _ {
            token = nil
        }
        
        let span = CFAbsoluteTimeGetCurrent() - before
        print("Get Access Token Time：\(span)")
        
        let str = NSString(data: token!, encoding: NSUTF8StringEncoding)
        
        var json: JSON = JSON(data: token!)
        
        if let access = json["access_token"].string, let refresh = json["refresh_token"].string {
            return (access, refresh)
        } else {
            throw NSError(domain: "auth.ischool.com.tw", code: 1,
                userInfo: ["RawUrl": url, NSURLErrorKey: url,NSLocalizedDescriptionKey: json["error_description"].string!])
        }
    }
    
    public func me(accessToken access: String) -> String {
        let url = "\(OAuthHelper.ServiceME)?access_token=\(access)"
        
        var error: NSError?
        let rsp: NSData?
        do {
            rsp = try HttpClient.Get(url)
        } catch let error1 as NSError {
            error = error1
            rsp = nil
        }
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
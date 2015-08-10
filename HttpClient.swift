//
//  HTTPClient.swift
//
//  Created by Yao Ming Huang on 2015/6/18.
//  Copyright (c) 2015年 Yao Ming Huang. All rights reserved.
//

import Foundation

public class HttpClient {
    
    public static var TrustServerList: Set<String> = Set<String>()
    
    class func Get(url:String) -> NSData? {
        var err: NSError?
        return Get(url,err: &err)
    }
    
    class func Get(url:String, inout err: NSError?) -> NSData? {
        var response: NSURLResponse?
        var error: NSError?
        
        var request = NSMutableURLRequest()
        
        request.HTTPMethod = "GET"
        request.URL = NSURL(string: url)
        
        var tokenData = NSURLConnection.sendSynchronousRequest(request,returningResponse: &response, error: &error)
        
        err = error
        
        return tokenData
    }
    
    public class func Get(url:String, successCallback: ((response: String) -> Void), errorCallback : ((error: NSError) -> Void)! = nil, prepareCallback: ((request: NSMutableURLRequest) -> Void)! = nil) {
        //success: ((response: String) -> Void)
        //error: ((error: NSError) -> Void)! = nil
        //prepare: ((request: NSURLRequest) -> Void)! = nil
        
        SendRequest(url, successCallback: {data in
            successCallback(response: data)
            
            }, errorCallback: {error in
                errorCallback(error: error)
                
            }, prepareCallback: { request in
                request.HTTPMethod = "GET"
        })
    }
    
    public class func Post(url: String, json: String, successCallback: ((response: String) -> Void), errorCallback : ((error: NSError) -> Void)! = nil, prepareCallback: ((request: NSMutableURLRequest) -> Void)! = nil) {
        Post(url, data: json, contentType: "application/json", successCallback: successCallback, errorCallback: errorCallback, prepareCallback: prepareCallback)
    }
    
    public class func Post(url: String, xml: String, successCallback: ((response: String) -> Void), errorCallback : ((error: NSError) -> Void)! = nil, prepareCallback: ((request: NSMutableURLRequest) -> Void)! = nil) {
        Post(url, data: xml, contentType: "application/xml", successCallback: successCallback, errorCallback: errorCallback, prepareCallback: prepareCallback)
    }
    
    public class func Post(url: String, data: String, contentType: String, successCallback: ((response: String) -> Void), errorCallback : ((error: NSError) -> Void)! = nil, prepareCallback: ((request: NSMutableURLRequest) -> Void)! = nil) {
        
        SendRequest(url, successCallback: {data in
            successCallback(response: data)
            
            }, errorCallback: {error in
                errorCallback(error: error)
                
            }, prepareCallback: { request in
                request.HTTPMethod = "POST"
                request.addValue(contentType, forHTTPHeaderField: "Content-Type")
                request.HTTPBody = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        })
    }
    
    public class func Post(url:String, body:String, inout err: NSError?) -> NSData? {
        var response: NSURLResponse?
        var error: NSError?
        
        var request = NSMutableURLRequest()
        
        request.HTTPMethod = "POST"
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.URL = NSURL(string: url)
        
        var tokenData = NSURLConnection.sendSynchronousRequest(request,returningResponse: &response, error: &error)
        
        err = error
        
        return tokenData
    }
    
    public class func Put(url:String, body:String, inout err: NSError?) -> NSData? {
        var response: NSURLResponse?
        var error: NSError?
        
        var request = NSMutableURLRequest()
        
        request.HTTPMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.URL = NSURL(string: url)
        
        var tokenData = NSURLConnection.sendSynchronousRequest(request,returningResponse: &response, error: &error)
        
        err = error
        
        return tokenData
    }
    
    public class func SendRequest(url:String, successCallback: ((response: String) -> Void), errorCallback : ((error: NSError) -> Void)! = nil, prepareCallback: ((request: NSMutableURLRequest) -> Void)! = nil){
        
        var req = NSMutableURLRequest()
        req.URL = NSURL(string:url)
        
        prepareCallback?(request: req)
        
        let delegate = HttpRequestDelegate(trustList: HttpClient.TrustServerList,
            success: { response in
                let strrsp = NSString(data: response, encoding: NSUTF8StringEncoding)
                successCallback(response: strrsp! as String)
            }, error: { err in
                errorCallback(error: err)
        })
        
        var conn = NSURLConnection(request: req, delegate: delegate, startImmediately: false)
        conn!.start()
    }
    
    class HttpRequestDelegate: NSObject, NSURLConnectionDataDelegate {
        
        private var success_callback: (response: NSData) -> Void
        private var error_callback: ((error: NSError) -> Void)!
        
        private var response_data: NSMutableData!
        
        private var trust_list: Set<String>
        
        init(trustList: Set<String>, success: (rsponse: NSData) -> Void, error: ((error: NSError) -> Void)!){
            self.success_callback = success
            self.error_callback = error
            
            self.trust_list = trustList
            self.response_data = NSMutableData()
        }
        
        func connection(connection: NSURLConnection, didReceiveData data: NSData){
            self.response_data.appendData(data)
        }
        
        func connectionDidFinishLoading(connection: NSURLConnection) {
            self.success_callback(response: self.response_data)
        }
        
        func connection(connection: NSURLConnection, didFailWithError error: NSError) {
            self.error_callback(error: error)
        }
        
        func connection(connection: NSURLConnection, canAuthenticateAgainstProtectionSpace protectionSpace: NSURLProtectionSpace) -> Bool {
            let methodIsServerTrust = protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
            
            let trusted = trust_list.contains(protectionSpace.host)
            
            return trusted && methodIsServerTrust
        }
        
        func connection(connection: NSURLConnection, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if self.trust_list.contains(challenge.protectionSpace.host) {
                    challenge.sender.useCredential(NSURLCredential(forTrust: challenge.protectionSpace.serverTrust), forAuthenticationChallenge: challenge)
                    challenge.sender.continueWithoutCredentialForAuthenticationChallenge(challenge)
                }
            }
        }
    }
}

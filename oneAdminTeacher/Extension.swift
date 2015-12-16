//
//  Extension.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/7/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import Foundation

//extension Optional{
//    func ParseInt() -> Int{
//        if let str = self as? String{
//            return str.toInt() ?? 0
//        }
//
//        return 0
//    }
//}

extension Connection{
    func SendRequest(targetService:String,bodyContent:String,inout _ error: DSFault!) -> String {
        
        var e : DSFault!
        
        var rsp = self.sendRequest(targetService, bodyContent: bodyContent, &e)
        
        dispatch_sync(Global.LockQueue) {
            
            if e != nil{
                RenewRefreshToken(Global.RefreshToken)
                self.connect(self.accessPoint, self.targetContract, SecurityToken.createOAuthToken(Global.AccessToken), &error)
                rsp = self.sendRequest(targetService, bodyContent: bodyContent, &e)
            }
            
            error = e
            
        }
        
        return rsp == nil ? "" : rsp
    }
}

//if failed will return 0
extension String {
    
    var intValue: Int {
        return Int(self) ?? 0
    }
    
    var int16Value: Int16 {
        return Int16(self.intValue)
    }
    
    var doubleValue: Double {
        return (self as NSString).doubleValue
    }
    
    public var dataValue: NSData {
        return self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
    
    public var UrlEncoding: String?{
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
    }
    
    func PadLeft(leng:Int,str:String) -> String{
        
        if (self as NSString).length < leng {
            let l = leng - (self as NSString).length
            
            var s = ""
            
            for i in 0...l{
                s += str
            }
            
            return s + self
        }
        
        return self
    }
}


extension Double {
    
    //四捨五入到小數點第二位(前一位數是偶數時是五捨六入)
//    func toString(precision : Int) -> String {
//        return String(format: "%.\(precision)f", self)
//    }
    
    func Round(precision : Int16) -> Double {
        let x = NSDecimalNumber(string: "\(self)")
        let y = NSDecimalNumber(int: 1)
        
        //小數點第二位四捨五入進位
        let behavior = NSDecimalNumberHandler(roundingMode: NSRoundingMode.RoundPlain, scale: precision, raiseOnExactness: true, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true)
        
        return x.decimalNumberByDividingBy(y, withBehavior: behavior).doubleValue
    }
    
    func ToString(precision : Int16) -> String {
        return String(format: "%.\(precision)f", self)
    }
}

extension NSData {
    public var stringValue: String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)! as String
    }
}

public func <(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedAscending
}

public func ==(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedSame
}

extension NSDate: Comparable { }

//extension JSON {
//    public var arrayStringValue: [String] {
//        get {
//            var value = [String]()
//            
//            for elem in arrayValue{
//                if !elem.stringValue.isEmpty{
//                    value.append(elem.stringValue)
//                }
//            }
//            
//            return value
//        }
//    }
//}

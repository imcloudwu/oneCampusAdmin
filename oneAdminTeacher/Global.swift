//
//  Global.swift
//  oneAdminTeacher
//
//  Created by Cloud on 6/25/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import Foundation
import UIKit

public class Global{
    static var clientID = "b2528ab72e010d32fc751a6c68bb08f6"
    static var clientSecret = "6d530c6bcb880a64064305b6020849ca94e1ee926df193b2aa3d0991014c2579"
    static var ContractName = "1campus.mobile.dominator"
    static var MyPhotoLocalPath = NSHomeDirectory().stringByAppendingString("/Documents/myPhoto.dat")
    static var MyPhoto : UIImage!
    static var MyName : String!
    static var MyEmail : String!
    static var MyDeviceToken : String!
    static var AccessToken : String!
    static var RefreshToken : String!
    static var DsnsList : [DsnsItem]!
    static var CurrentDsns : DsnsItem!
    static var Students = [Student]()
    static var CurrentStudent : Student!
    static var CountProgressTime = [ProgressTimer]()
    static var ClassList : [ClassItem]!
    static var Alert : UIAlertController!
    
    static var LastLoginDateTime : NSDate!
    static var MySchoolList = [DsnsItem]()
    static var MyTeacherList = [TeacherAccount]()
    
    static var SchoolConnector = [String:Connection]()
    
    static var LockQueue = dispatch_queue_create("LockQueue", nil)
    
    static func Reset(){
        MyPhoto = nil
        ClassList = nil
        MySchoolList = [DsnsItem]()
        MyTeacherList = [TeacherAccount]()
        SchoolConnector = [String:Connection]()
        
        let fm = NSFileManager()
        fm.removeItemAtPath(MyPhotoLocalPath, error: nil)
    }
    
//    static func GetTeacherAccountByUUIDs(uuids:[String]) -> [TeacherAccount]{
//        
//        var retVal = [TeacherAccount]()
//        
//        for uuid in uuids{
//            if let teacher = GetTeacherAccountByUUID(uuid){
//                retVal.append(teacher)
//            }
//        }
//        
//        return retVal
//    }
//    
//    static func GetTeacherAccountByUUID(uuid:String) -> TeacherAccount?{
//        
//        for t in MyTeacherList{
//            if t.UUID == uuid{
//                return t
//            }
//        }
//        
//        return nil
//    }
    
    static func DeleteStudent(student:Student){
        var newData = [Student]()
        
        for stu in Students{
            if stu != student{
                newData.append(stu)
            }
        }
        
        if CurrentStudent != nil && CurrentStudent == student{
            CurrentStudent = nil
        }
        
        Students = newData
    }
    
    static func SetAccessTokenAndRefreshToken(token:(accessToken:String,refreshToken:String)!){
        
        self.AccessToken = nil
        self.RefreshToken = nil
        
        if token != nil{
            self.AccessToken = token.accessToken
            self.RefreshToken = token.refreshToken
            
            Keychain.save("refreshToken", data: RefreshToken.dataValue)
        }
    }
}

class ProgressTimer : NSObject{
    var ProgressBar : UIProgressView!
    var Timer : NSTimer?
    private var limitTime : Int
    
    init(progressBar:UIProgressView){
        ProgressBar = progressBar
        ProgressBar.hidden = true
        limitTime = 0
    }

    func StartProgress(){
        Timer?.invalidate()
        Timer = NSTimer.scheduledTimerWithTimeInterval(0.01667, target: self, selector: "timerCallback", userInfo: nil, repeats: true)
        ProgressBar.hidden = false
        ProgressBar.progress = 0.0
    }
    
    func StopProgress(){
        ProgressBar.progress = 1.0
        ProgressBar.hidden = true
        Timer?.invalidate()
        Timer = nil
        limitTime = 0
    }
    
    func timerCallback() {
        
        limitTime++
        
        if limitTime > 1000{
            StopProgress()
            return
        }
        
        //println("still running...\(limitTime)")
        
        if !ProgressBar.hidden{
            if ProgressBar.progress >= 0.95{
                ProgressBar.progress = 0.95
            }
            else{
                ProgressBar.progress += 0.05
            }
        }
    }
}

func SetCommonConnect(dsns:String,con:Connection){
    
    dispatch_sync(Global.LockQueue) {
        
        var err: DSFault!
        
        con.connect(dsns, Global.ContractName, SecurityToken.createOAuthToken(Global.AccessToken), &err)
        Global.SchoolConnector[dsns] = con
    }
}

func GetCommonConnect(dsns:String) -> Connection{
    
    dispatch_sync(Global.LockQueue) {
        
        if Global.SchoolConnector[dsns] == nil{
            
            var err: DSFault!
            
            Global.SchoolConnector[dsns] = Connection()
            
            Global.SchoolConnector[dsns]!.connect(dsns, Global.ContractName, SecurityToken.createOAuthToken(Global.AccessToken), &err)
            
            if err != nil{
                //ShowErrorAlert(vc,"錯誤來自:\(dsns)",err.message)
            }
        }
    }
    
    return Global.SchoolConnector[dsns]!
}

//func GetCommonConnect(dsns:String,con:Connection,vc:UIViewController) -> Connection{
//    
//    dispatch_sync(Global.LockQueue) {
//        
//        if Global.SchoolConnector[dsns] == nil{
//            
//            var err: DSFault!
//            
//            Global.SchoolConnector[dsns] = con
//            
//            Global.SchoolConnector[dsns]!.connect(dsns, Global.ContractName, SecurityToken.createOAuthToken(Global.AccessToken), &err)
//            
//            if err != nil{
//                //ShowErrorAlert(vc,"錯誤來自:\(dsns)",err.message)
//            }
//        }
//    }
//    
//    return Global.SchoolConnector[dsns]!
//    //con.connect(Global.CurrentDsns.AccessPoint, "ischool.teacher.app", SecurityToken.createOAuthToken(Global.AccessToken), &err)
//    //con.connect(dsns, Global.ContractName, SecurityToken.createOAuthToken(Global.AccessToken), &err)
//    
//    //if err != nil{
//        //ShowErrorAlert(vc,"錯誤來自:\(dsns)",err.message)
//    //}
//}

func ShowErrorAlert(vc:UIViewController,title:String,msg:String){
    
    if Global.Alert == nil{
        Global.Alert = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        Global.Alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
    }
    
    Global.Alert.title = title
    Global.Alert.message = msg
    
//    let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.Alert)
//    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
//        if callback != nil{
//            callback()
//        }
//    }))
    
    
    vc.presentViewController(Global.Alert, animated: true, completion: nil)
    
}

//整理出資料的學年度學期並回傳
func GetSemesters<T>(datas:[T]) -> [SemesterItem]{
    
    var retVal = [SemesterItem]()
    var newData = [SemesterProtocol]()
    
    for data in datas{
        if let sp = data as? SemesterProtocol{
            newData.append(sp)
        }
    }
    
    for data in newData{
        let semester = SemesterItem(SchoolYear: data.SchoolYear, Semester: data.Semester)
        if !contains(retVal, semester){
            retVal.append(semester)
        }
    }
    
    if retVal.count > 0{
        retVal.sort({$0 > $1})
    }
    
    return retVal
}

func ChangeContentView(vc:UIViewController){
    var app = UIApplication.sharedApplication().delegate as! AppDelegate
    
    app.centerContainer?.setCenterViewController(vc, withCloseAnimation: true, completion: nil)
    //app.centerContainer?.closeDrawerAnimated(true, completion: nil)
//    app.centerContainer?.closeDrawerAnimated(true, completion: { (finish) -> Void in
//        app.centerContainer?.centerViewController = vc
//        
//        app.centerContainer?.setCenterViewController(<#newCenterViewController: UIViewController!#>, withFullCloseAnimation: <#Bool#>, completion: <#((Bool) -> Void)!##(Bool) -> Void#>)
//    })
    //app.centerContainer?.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
}

func EnableSideMenu(){
    var app = UIApplication.sharedApplication().delegate as! AppDelegate
    
    app.centerContainer?.openDrawerGestureModeMask = MMOpenDrawerGestureMode.PanningCenterView
    app.centerContainer?.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.PanningCenterView | MMCloseDrawerGestureMode.TapCenterView
}

func DisableSideMenu(){
    var app = UIApplication.sharedApplication().delegate as! AppDelegate
    
    app.centerContainer?.openDrawerGestureModeMask = MMOpenDrawerGestureMode.None
    app.centerContainer?.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.None
}

func GetAccessTokenAndRefreshToken(code:String){
    var error : NSError?
    var oautHelper = OAuthHelper(clientId: Global.clientID, clientSecret: Global.clientSecret)
    let token = oautHelper.getAccessTokenAndRefreshToken(code, error: &error)
    //println(token)
    Global.SetAccessTokenAndRefreshToken(token)
    
    //println("AccessToken = \(Global.AccessToken)")
    //println("RefreshToken = \(Global.RefreshToken)")
}

func RenewRefreshToken(refreshToken:String){
    var error : NSError?
    var oautHelper = OAuthHelper(clientId: Global.clientID, clientSecret: Global.clientSecret)
    let token = oautHelper.renewAccessToken(refreshToken, error: &error)
    Global.SetAccessTokenAndRefreshToken(token)
}

//new solution
func GetSchoolName(con:Connection) -> String{
    
    var schoolName = con.accessPoint
    
    var error : DSFault!
    var nserr : NSError?
    
    var rsp = con.SendRequest("main.GetSchoolName", bodyContent: "", &error)
    
    let xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
    
    if let name = xml?.root["Response"]["SchoolName"].first?.stringValue{
        schoolName = name
        
        let di = DsnsItem(name: schoolName, accessPoint: con.accessPoint)
        
        if !contains(Global.MySchoolList, di){
            Global.MySchoolList.append(di)
        }
    }
    
    
    //        //encode成功呼叫查詢
    //        if let encodingName = con.accessPoint.UrlEncoding{
    //
    //            var data = HttpClient.Get("http://dsns.1campus.net/campusman.ischool.com.tw/config.public/GetSchoolList?content=%3CRequest%3E%3CMatch%3E\(encodingName)%3C/Match%3E%3CPagination%3E%3CPageSize%3E10%3C/PageSize%3E%3CStartPage%3E1%3C/StartPage%3E%3C/Pagination%3E%3C/Request%3E")
    //
    //            if let rsp = data{
    //
    //                //println(NSString(data: rsp, encoding: NSUTF8StringEncoding))
    //
    //                var nserr : NSError?
    //
    //                let xml = AEXMLDocument(xmlData: rsp, error: &nserr)
    //
    //                if let name = xml?.root["Response"]["School"]["Title"].stringValue{
    //                    schoolName = name
    //                }
    //            }
    //        }
    
    return schoolName
}

func GetTeacherAccountItem(account:String) -> TeacherAccount?{
    
    if !account.isEmpty{
        for ta in Global.MyTeacherList{
            if ta.Account == account{
                return ta
            }
        }
    }
    
    return nil
}

func GetAllTeacherAccount(schoolName:String,con:Connection){
    
    var err : DSFault!
    var nserr : NSError?
    
    var rsp = con.SendRequest("main.GetAllTeacher", bodyContent: "", &err)
    
    let xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
    
    if let teachers = xml?.root["Teachers"]["Teacher"].all{
        for teacher in teachers{
            let teacherName = teacher["TeacherName"].stringValue
            let teacherAccount = teacher["TeacherAccount"].stringValue
            
            let teacherItem = TeacherAccount(schoolName: schoolName, name: teacherName, account: teacherAccount)
            
            if !contains(Global.MyTeacherList, teacherItem){
                Global.MyTeacherList.append(teacherItem)
            }
        }
    }
    
    //SetTeachersUUID(Global.MyTeacherList)
}

func SetTeachersUUID(source:[TeacherAccount]){
    
    var err : NSError?
    var emailString = ""
    
    for teacher in source{
        if teacher.Account != "" , let account = teacher.Account.UrlEncoding{
            if teacher == source.last{
                emailString += "%22\(account)%22"
            }
            else{
                emailString += "%22\(account)%22" + ","
            }
        }
    }
    
    var rsp = HttpClient.Get("https://auth.ischool.com.tw/services/uuidLookup.php?accounts=[\(emailString)]",err: &err)
    
    //println(NSString(data: rsp!, encoding: NSUTF8StringEncoding))
    
    //null會是空白字串
    var jsons = JSON(data: rsp!)
    
    for teacher in source{
        teacher.UUID = jsons[teacher.Account].stringValue
    }
}

func RegisterForKeyboardNotifications(vc:UIViewController) {
    let notificationCenter = NSNotificationCenter.defaultCenter()
    notificationCenter.addObserver(vc,
        selector: "keyboardWillBeShown:",
        name: UIKeyboardWillShowNotification,
        object: nil)
}








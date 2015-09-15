//
//  CommonStruct.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/7/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import Foundation

//struct DisplayItem{
//    var Title : String
//    var Value : String
//    var OtherInfo : String
//    var ColorAlarm : Bool
//}

class DisplayItem{
    var Title : String
    var Value : String
    var OtherInfo : String
    var OtherInfo2 : String
    var OtherInfo3 : String
    var ColorAlarm : Bool
    
    convenience init(Title:String,Value:String,OtherInfo:String){
        
        self.init(Title:Title,Value:Value,OtherInfo:OtherInfo,OtherInfo2:"",OtherInfo3:"",ColorAlarm:false)
    }
    
    convenience init(Title:String,Value:String,OtherInfo:String,ColorAlarm:Bool){
        
        self.init(Title:Title,Value:Value,OtherInfo:OtherInfo,OtherInfo2:"",OtherInfo3:"",ColorAlarm:ColorAlarm)
    }
    
    init(Title:String,Value:String,OtherInfo:String,OtherInfo2:String,OtherInfo3:String,ColorAlarm:Bool){
        self.Title = Title
        self.Value = Value
        self.OtherInfo = OtherInfo
        self.OtherInfo2 = OtherInfo2
        self.OtherInfo3 = OtherInfo3
        self.ColorAlarm = ColorAlarm
    }
}

protocol SemesterProtocol
{
    var SchoolYear : String { get set }
    var Semester : String { get set }
}

protocol ContainerViewProtocol
{
    var StudentData : Student! { get set }
    var ParentNavigationItem : UINavigationItem? { get set }
}

class TeacherAccount : Equatable{
    var SchoolName : String
    var Name : String
    var Account : String
    var UUID : String
    
    init(schoolName:String,name:String,account:String){
        SchoolName = schoolName
        Name = name
        Account = account
        UUID = ""
    }
    
//    init(uuid:String){
//        SchoolName = ""
//        Name = ""
//        Account = ""
//        UUID = uuid
//    }
}

func ==(lhs: TeacherAccount, rhs: TeacherAccount) -> Bool {
    return lhs.SchoolName == rhs.SchoolName && lhs.Name == rhs.Name && lhs.Account == rhs.Account
}
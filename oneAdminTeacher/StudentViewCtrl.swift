//
//  FirstViewController.swift
//  oneAdminTeacher
//
//  Created by Cloud on 6/12/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class StudentViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var progressTimer : ProgressTimer!
    
    //var Timer : NSTimer!
    
    var _studentData = [Student]()
    var _displayData = [Student]()
    var ClassData : ClassItem!
    
    var _con : Connection!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressTimer = ProgressTimer(progressBar: progressBar)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.title = ClassData.ClassName
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if _displayData.count == 0{
            SetDataToTableView()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _displayData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("studentCell") as! StudentCell
        cell.Photo.image = _displayData[indexPath.row].Photo
        cell.Label1.text = "\(_displayData[indexPath.row].Name)"
        cell.Label2.text = _displayData[indexPath.row].SeatNo == "" ? "" : "座號: \(_displayData[indexPath.row].SeatNo) "
        
        cell.student = _displayData[indexPath.row]
        
        //UILongPressGestureRecognizer
        var longPress = UILongPressGestureRecognizer(target: self, action: "LongPress:")
        longPress.minimumPressDuration = 0.5
        
        cell.addGestureRecognizer(longPress)
        
        return  cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("StudentDetailViewCtrl") as! StudentDetailViewCtrl
        nextView.StudentData = _displayData[indexPath.row]
        
//        if ClassData.Major != "導師"{
//            nextView.IsClassStudent = false
//        }
        
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
    func SetDataToTableView(){
        
        progressTimer.StartProgress()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            
            //self._con = GetCommonConnect(self.ClassData.AccessPoint, self._con, self)
            self._con = GetCommonConnect(self.ClassData.AccessPoint)
            
            self._studentData = self.GetClassStudentData()
//            if self.ClassData.Major == "導師"{
//                self._studentData = self.GetClassStudentData()
//            }
//            else{
//                self._studentData = self.GetCourseStudentData()
//            }
            
            self._displayData = self._studentData
            
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
                self.progressTimer.StopProgress()
            })
        })
    }
    
    func GetClassStudentData() -> [Student]{
        
        var err : DSFault!
        var nserr : NSError?
        
        var retVal = [Student]()
        
        var rsp = _con.SendRequest("main.GetClassStudents", bodyContent: "<Request><All></All><ClassID>\(ClassData.ID)</ClassID></Request>", &err)
        
        //println(rsp)
        
        if err != nil{
            ShowErrorAlert(self,"取得資料發生錯誤",err.message)
            return retVal
        }
        
        let xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
        
        if let students = xml?.root["Response"]["Student"].all {
            for stu in students{
                //println(stu.xmlString)
                let studentID = stu["StudentID"].stringValue
                let className = stu["ClassName"].stringValue
                let studentName = stu["StudentName"].stringValue
                let seatNo = stu["SeatNo"].stringValue
                let studentNumber = stu["StudentNumber"].stringValue
                let gender = stu["Gender"].stringValue
                let mailingAddress = stu["MailingAddress"].xmlString
                let permanentAddress = stu["PermanentAddress"].xmlString
                let contactPhone = stu["ContactPhone"].stringValue
                let permanentPhone = stu["PermanentPhone"].stringValue
                let custodianName = stu["CustodianName"].stringValue
                let fatherName = stu["FatherName"].stringValue
                let motherName = stu["MotherName"].stringValue
                let freshmanPhoto = GetImageFromBase64String(stu["FreshmanPhoto"].stringValue, defaultImg: UIImage(named: "User-100.png"))
                
                let stuItem = Student(DSNS: ClassData.AccessPoint,ID: studentID, ClassID: ClassData.ID, ClassName: className, Name: studentName, SeatNo: seatNo, StudentNumber: studentNumber, Gender: gender, MailingAddress: mailingAddress, PermanentAddress: permanentAddress, ContactPhone: contactPhone, PermanentPhone: permanentPhone, CustodianName: custodianName, FatherName: fatherName, MotherName: motherName, Photo: freshmanPhoto)
                
                retVal.append(stuItem)
            }
        }
        
        retVal.sort{ $0.SeatNo.toInt() < $1.SeatNo.toInt() }

        return retVal
    }
    
//    func GetCourseStudentData() -> [Student]{
//        
//        var err : DSFault!
//        var nserr : NSError?
//        
//        var retVal = [Student]()
//        
//        var rsp = _con.sendRequest("main.GetCourseStudent", bodyContent: "<Request><All></All><CourseID>\(ClassData.ID)</CourseID></Request>", &err)
//        
//        //println(rsp)
//        
//        if err != nil{
//            ShowErrorAlert(self,"取得資料發生錯誤",err.message)
//            return retVal
//        }
//        
//        let xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
//        
//        if let students = xml?.root["Response"]["Student"].all {
//            for stu in students{
//                //println(stu.xmlString)
//                let studentID = stu["StudentID"].stringValue
//                let className = stu["ClassName"].stringValue
//                let studentName = stu["StudentName"].stringValue
//                let seatNo = stu["SeatNo"].stringValue
//                let studentNumber = stu["StudentNumber"].stringValue
//                let gender = stu["Gender"].stringValue
//                let freshmanPhoto = GetImageFromBase64String(stu["FreshmanPhoto"].stringValue, defaultImg: UIImage(named: "User-100.png"))
//                
//                let stuItem = Student(DSNS: ClassData.AccessPoint,ID: studentID, ClassID : ClassData.ID, ClassName: className, Name: studentName, SeatNo: seatNo, StudentNumber: studentNumber, Gender: gender, MailingAddress: "", PermanentAddress: "", ContactPhone: "", PermanentPhone: "", CustodianName: "", FatherName: "", MotherName: "", Photo: freshmanPhoto)
//                
//                retVal.append(stuItem)
//            }
//        }
//        
//        return retVal
//    }
    
    func GetImageFromBase64String(base64String:String,defaultImg:UIImage?) -> UIImage?{
        
        var decodedimage : UIImage?
        
        if let decodedData = NSData(base64EncodedString: base64String, options: NSDataBase64DecodingOptions(rawValue: 0)){
            decodedimage = UIImage(data: decodedData)
        }
        
        return decodedimage ?? defaultImg
    }
    
    func LongPress(sender:UILongPressGestureRecognizer){
        
        if sender.state == UIGestureRecognizerState.Began{
            var cell = sender.view as! StudentCell
            
            let menu = UIAlertController(title: "要對 \(cell.student.Name) 的家長發送訊息嗎?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            
            menu.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
            
            menu.addAction(UIAlertAction(title: "是", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                self.SendMessageToClassParents(cell)
            }))
            
            self.presentViewController(menu, animated: true, completion: nil)
        }
    }
    
    func SendMessageToClassParents(cell : StudentCell){
        
        var err : DSFault!
        let con = GetCommonConnect(cell.student.DSNS)
        
        var rsp = con.sendRequest("main.GetParent", bodyContent: "<Request><StudentID>\(cell.student.ID)</StudentID></Request>", &err)
        
        if err != nil{
            ShowErrorAlert(self, "錯誤", err.message)
        }
        else{
            var nserr : NSError?
            
            var xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
            
            var parentAccounts = [TeacherAccount]()
            
            if let parents = xml?.root["Response"]["Parent"].all {
                for parent in parents{
                    let studentName = parent["StudentName"].stringValue
                    let studentID = parent["StudentID"].stringValue
                    let parentAccount = parent["ParentAccount"].stringValue
                    let className = parent["ClassName"].stringValue
                    let relationship = parent["Relationship"].stringValue
                    
                    var pa = TeacherAccount(schoolName: "", name: studentName + "(" + relationship + ")", account: parentAccount)
                    parentAccounts.append(pa)
                }
            }
            
            SetTeachersUUID(parentAccounts)
            
            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("OutboxSendViewCtrl") as! OutboxSendViewCtrl
            nextView.MyTeacherSelector.Teachers = parentAccounts
            nextView.DataBase = parentAccounts
            
            self.navigationController?.pushViewController(nextView, animated: true)
        }
    }
    
}

struct Student : Equatable{
    var DSNS : String!
    var ID : String!
    var ClassID : String!
    var ClassName : String!
    var Name : String!
    var SeatNo : String!
    var StudentNumber : String!
    var Gender : String!
    var MailingAddress : String!
    var PermanentAddress : String!
    var ContactPhone : String!
    var PermanentPhone : String!
    var CustodianName : String!
    var FatherName : String!
    var MotherName : String!
    var Photo : UIImage!
}

func ==(lhs: Student, rhs: Student) -> Bool {
    return lhs.DSNS == rhs.DSNS && lhs.ID == rhs.ID
}


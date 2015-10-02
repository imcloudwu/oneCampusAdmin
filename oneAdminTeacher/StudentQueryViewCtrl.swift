//
//  StudentQueryViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 9/14/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class StudentQueryViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var noDataLabel: UILabel!
    
    var progressTimer : ProgressTimer!
    
    //var Timer : NSTimer!
    
    var _displayData = [Student]()
    
    var DsnsResult = [String:Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressTimer = ProgressTimer(progressBar: progressBar)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.delegate = self
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Menu-24.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ToggleSideMenu")
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        //self.navigationItem.title = ClassData.ClassName
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _displayData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("studentCell2") as! StudentCell2
        cell.Photo.image = _displayData[indexPath.row].Photo
        cell.Name.text = "\(_displayData[indexPath.row].Name)"
        cell.ClassName.text = "\(_displayData[indexPath.row].ClassName)"
        cell.ClassSeatNo.text = _displayData[indexPath.row].SeatNo == "" ? "" : "座號: \(_displayData[indexPath.row].SeatNo) "
        
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
        
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
    func SetDataToTableView(text:String){
        
        self.noDataLabel.hidden = true
        
        self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top)
        
        progressTimer.StartProgress()
        
        DsnsResult.removeAll(keepCapacity: true)
        
        for dsns in Global.DsnsList{
            DsnsResult[dsns.AccessPoint] = false
        }
        
        var tmp = [Student]()
        
        if Global.DsnsList.count == 0{
            self.progressTimer.StopProgress()
        }
        
        for dsns in Global.DsnsList{
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                
                var con = GetCommonConnect(dsns.AccessPoint)
                tmp += self.GetClassStudentData(con, text: text)
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.DsnsResult[con.accessPoint] = true
                    
                    self._displayData = tmp
                    
                    self.tableView.reloadData()
                    
                    if self.AllDone(){
                        self.progressTimer.StopProgress()
                        
                        if self._displayData.count == 0{
                            self.noDataLabel.hidden = false
                        }
                    }
                    
                })
            })
        }
    }
    
    func AllDone() -> Bool{
        
        for dsns in DsnsResult{
            if !dsns.1{
                return false
            }
        }
        
        return true
    }
    
    func GetClassStudentData(con:Connection ,text:String) -> [Student]{
        
        var err : DSFault!
        var nserr : NSError?
        
        var retVal = [Student]()
        
        var rsp = con.SendRequest("main.QueryStudent", bodyContent: "<Request><All></All><Query>\(text)</Query></Request>", &err)
        
        //println(rsp)
        
        if err != nil{
            //ShowErrorAlert(self,"取得資料發生錯誤",err.message)
            return retVal
        }
        
        let xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
        
        if let students = xml?.root["Response"]["Student"].all {
            for stu in students{
                //println(stu.xmlString)
                let studentID = stu["StudentID"].stringValue
                let className = stu["ClassName"].stringValue
                let classID = stu["ClassID"].stringValue
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
                let freshmanPhoto = GetImageFromBase64String(stu["FreshmanPhoto"].stringValue, UIImage(named: "User-100.png"))
                
                let stuItem = Student(DSNS: con.accessPoint,ID: studentID, ClassID: classID, ClassName: className, Name: studentName, SeatNo: seatNo, StudentNumber: studentNumber, Gender: gender, MailingAddress: mailingAddress, PermanentAddress: permanentAddress, ContactPhone: contactPhone, PermanentPhone: permanentPhone, CustodianName: custodianName, FatherName: fatherName, MotherName: motherName, Photo: freshmanPhoto)
                
                retVal.append(stuItem)
            }
        }
        
        retVal.sort{ $0.SeatNo.toInt() < $1.SeatNo.toInt() }
        
        return retVal
    }
    
    func LongPress(sender:UILongPressGestureRecognizer){
        
        if sender.state == UIGestureRecognizerState.Began{
            var cell = sender.view as! StudentCell2
            
            let menu = UIAlertController(title: "要對 \(cell.student.Name) 的家長發送訊息嗎?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            
            menu.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
            
            menu.addAction(UIAlertAction(title: "是", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                self.SendMessageToClassParents(cell)
            }))
            
            self.presentViewController(menu, animated: true, completion: nil)
        }
    }
    
    func SendMessageToClassParents(cell : StudentCell2){
        
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
    
    //Mark : SearchBar
    func searchBarSearchButtonClicked(searchBar: UISearchBar){
        searchBar.resignFirstResponder()
        self.view.endEditing(true)
        
        SetDataToTableView(searchBar.text)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        //Search(searchText)
    }
    
    func ToggleSideMenu(){
        var app = UIApplication.sharedApplication().delegate as! AppDelegate
        
        app.centerContainer?.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
    
}



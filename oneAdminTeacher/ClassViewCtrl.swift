//
//  ClassViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/10/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//


import UIKit

class ClassViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    //var progressTimer : ProgressTimer!
    var refreshControl : UIRefreshControl!
    
    var _ClassList = [ClassItem]()
    
    var DsnsResult = [String:Bool]()
    
    let redColor = UIColor(red: 244 / 255, green: 67 / 255, blue: 54 / 255, alpha: 1)
    let blueColor = UIColor(red: 33 / 255, green: 150 / 255, blue: 243 / 255, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: "ReloadData", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        let sideMenuBtn = UIBarButtonItem(image: UIImage(named: "Menu-24.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ToggleSideMenu")
        self.navigationItem.leftBarButtonItem = sideMenuBtn
        
        tableView.delegate = self
        tableView.dataSource = self
        self.navigationItem.title = "班級列表"
        self.navigationController?.interactivePopGestureRecognizer.enabled = false
        
        //progressTimer = ProgressTimer(progressBar: progress)
        
        if Global.ClassList != nil {
            _ClassList = Global.ClassList
            //tableView.reloadData()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if _ClassList.count == 0 {
            GetMyClassList()
        }
    }
    
    func ToggleSideMenu(){
        var app = UIApplication.sharedApplication().delegate as! AppDelegate
        
        app.centerContainer?.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
    
    func ReloadData(){
        GetMyClassList()
        self.refreshControl.endRefreshing()
    }
    
    func GetMyClassList() {
        
        self.progress.hidden = false
        
        var tmpList = [ClassItem]()
        
        DsnsResult.removeAll(keepCapacity: false)
        for dsns in Global.DsnsList{
            DsnsResult[dsns.Name] = false
        }
        
        var percent : Float = 1 / Float(DsnsResult.count)
        
        self.progress.progress = 0
        
        for dsns in Global.DsnsList{
            
            //self.progressTimer.StartProgress()
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                
                var con = Connection()
                SetCommonConnect(dsns.AccessPoint, con)
                //con = CommonConnect(dsns.AccessPoint, con, self)
                tmpList += self.GetData(con)
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.DsnsResult[dsns.Name] = true
                    //self.progressTimer.StopProgress()
                    self.progress.progress += percent
                    
                    if self.AllDone(){
                        self.progress.hidden = true
                        
                        if tmpList.count > 0{
                            self.noDataLabel.hidden = true
                        }
                        else{
                            self.noDataLabel.hidden = false
                        }
                    }
                    
                    self._ClassList = tmpList
                    Global.ClassList = tmpList
                    self.tableView.reloadData()
                })
            })
        }
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
//            
//            for dsns in Global.DsnsList{
//                
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
//                    
//                    var con = Connection()
//                    CommonConnect(dsns.AccessPoint, con, self)
//                    tmpList += self.GetClassData(con)
//                    
//                    dispatch_async(dispatch_get_main_queue(), {
//                        
//                        self._ClassList = tmpList
//                        Global.ClassList = tmpList
//                        self.tableView.reloadData()
//                    })
//                })
//            }
//            
//            dispatch_async(dispatch_get_main_queue(), {
//                self.progressTimer.StopProgress()
//            })
//        })
    }
    
    func GetData(con:Connection) -> [ClassItem]{
        
        var retVal = [ClassItem]()
        
        retVal += GetAllClassData(con)
        //retVal += GetCourseData(con)
        
        return retVal
    }
    
    func GetAllClassData(con:Connection) -> [ClassItem]{
        
        var retVal = [ClassItem]()
        
        var err : DSFault!
        var nserr : NSError?
        
        var rsp = con.SendRequest("main.GetAllClass", bodyContent: "", &err)
        
        if err != nil{
            //ShowErrorAlert(self,err,nil)
            return retVal
        }
        
        var xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
        
        if let classes = xml?.root["ClassList"]["Class"].all {
            for cls in classes{
                let ClassID = cls["ClassID"].stringValue
                let ClassName = cls["ClassName"].stringValue
                let GradeYear = cls["GradeYear"].stringValue.toInt() ?? 0
                let TeacherName = cls["TeacherName"].stringValue
                
                retVal.append(ClassItem(ID: ClassID, ClassName: ClassName, AccessPoint: con.accessPoint, GradeYear: GradeYear, Major: TeacherName))
            }
        }
        
        if retVal.count > 0{
            
            let schoolName = GetSchoolName(con)
            GetAllTeacherAccount(schoolName, con)
            
            retVal.insert(ClassItem(ID: "header", ClassName: schoolName, AccessPoint: "", GradeYear: 0, Major: ""), atIndex: 0)
        }
        
        return retVal
    }
    
//    func GetClassData(con:Connection) -> [ClassItem]{
//        
//        var retVal = [ClassItem]()
//        
//        var err : DSFault!
//        var nserr : NSError?
//        
//        var rsp = con.sendRequest("main.GetMyTutorClasses", bodyContent: "", &err)
//        
//        if err != nil{
//            //ShowErrorAlert(self,err,nil)
//            return retVal
//        }
//        
//        var xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
//        
//        if let classes = xml?.root["ClassList"]["Class"].all {
//            for cls in classes{
//                let ClassID = cls["ClassID"].stringValue
//                let ClassName = cls["ClassName"].stringValue
//                let GradeYear = cls["GradeYear"].stringValue.toInt() ?? 0
//                
//                retVal.append(ClassItem(ID: ClassID, ClassName: ClassName, AccessPoint: con.accessPoint, GradeYear: GradeYear, Major: "導師"))
//            }
//        }
//        
//        if retVal.count > 0{
//            retVal.insert(ClassItem(ID: "header", ClassName: GetSchoolName(con), AccessPoint: "", GradeYear: 0, Major: ""), atIndex: 0)
//        }
//        
//        return retVal
//    }
//    
//    func GetCourseData(con:Connection) -> [ClassItem]{
//        
//        var retVal = [ClassItem]()
//        
//        var err : DSFault!
//        var nserr : NSError?
//        
//        var schoolYear = ""
//        var semester = ""
//        
//        //GetSemester first
//        var rsp = con.sendRequest("main.GetCurrentSemester", bodyContent: "", &err)
//        
//        if err != nil{
//            //ShowErrorAlert(self,err,nil)
//            return retVal
//        }
//        
//        var xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
//        
//        if let sy = xml?.root["Response"]["SchoolYear"].first?.stringValue{
//            schoolYear = sy
//        }
//        
//        if let sm = xml?.root["Response"]["Semester"].first?.stringValue{
//            semester = sm
//        }
//        
//        //GetCourseData
//        rsp = con.sendRequest("main.GetMyCourses", bodyContent: "<Request><All></All><SchoolYear>\(schoolYear)</SchoolYear><Semester>\(semester)</Semester></Request>", &err)
//        
//        if err != nil{
//            //ShowErrorAlert(self,err,nil)
//            return retVal
//        }
//        
//        xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
//        
//        if let classes = xml?.root["ClassList"]["Class"].all {
//            for cls in classes{
//                let CourseID = cls["CourseID"].stringValue
//                let CourseName = cls["CourseName"].stringValue
//                let GradeYear = cls["GradeYear"].stringValue.toInt() ?? 0
//                
//                retVal.append(ClassItem(ID: CourseID, ClassName: CourseName, AccessPoint: con.accessPoint, GradeYear: GradeYear, Major: "授課"))
//            }
//        }
//        
//        return retVal
//    }
    
    func AllDone() -> Bool{
        
        for dsns in DsnsResult{
            if !dsns.1{
                return false
            }
        }
        
        return true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _ClassList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let data = _ClassList[indexPath.row]
        
        if data.ID == "header"{
            var cell = tableView.dequeueReusableCellWithIdentifier("summaryItem") as? UITableViewCell
            
            if cell == nil{
                cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "summaryItem")
                cell?.backgroundColor = UIColor(red: 238 / 255, green: 238 / 255, blue: 238 / 255, alpha: 1)
            }
            
            cell?.textLabel?.text = data.ClassName
            return cell!
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ClassCell") as! ClassCell
        cell.ClassName.text = data.ClassName
        cell.Major.text = data.Major
        
//        if data.Major == "導師"{
//            cell.ClassIcon.backgroundColor = redColor
//        }
//        else{
//            cell.ClassIcon.backgroundColor = blueColor
//        }
        
        //字串擷取
        if (data.ClassName as NSString).length > 0{
            let subString = (data.ClassName as NSString).substringToIndex(1)
            cell.ClassIcon.text = subString
        }
        else{
            cell.ClassIcon.text = ""
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let data = _ClassList[indexPath.row]
        
        if data.ID != "header"{
            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("StudentViewCtrl") as! StudentViewCtrl
            nextView.ClassData = _ClassList[indexPath.row]
            self.navigationController?.pushViewController(nextView, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        if _ClassList[indexPath.row].ID == "header"{
            return 30
        }
        
        return 60
    }
}

struct ClassItem{
    var ID : String
    var ClassName : String
    var AccessPoint : String
    var GradeYear : Int
    var Major : String
}

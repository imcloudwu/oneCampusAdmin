//
//  CourseScoreViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/20/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class CourseScoreViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,ContainerViewProtocol {
    
    var StudentData : Student!
    var ParentNavigationItem : UINavigationItem?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var progressTimer : ProgressTimer!
    
    var _displayData = [DisplayItem]()
    
    var _con : Connection!
    
    var _isJH = false
    var _isHS = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressTimer = ProgressTimer(progressBar: progress)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if self._displayData.count > 0{
            return
        }
        
        progressTimer.StartProgress()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            
            //self._con = GetCommonConnect(self.StudentData.DSNS, self._con, self)
            self._con = GetCommonConnect(self.StudentData.DSNS)
            
            self.CheckDSNS()
            
            self._displayData = self.GetScoreData()
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if self._displayData.count > 0{
                   self.noDataLabel.hidden = true
                }
                else{
                    self.noDataLabel.hidden = false
                }
                
                self.tableView.reloadData()
                self.progressTimer.StopProgress()
            })
        })
    }
    
    func GetScoreData() -> [DisplayItem]{
        
        var retVal = [DisplayItem]()
        
        var err : DSFault!
        var nserr : NSError?
        
        var rsp = _con.SendRequest("courseTeacher.GetExamScore", bodyContent: "<Request><Condition><RefStudentId>\(StudentData.ID)</RefStudentId><RefCourseId>\(StudentData.ClassID)</RefCourseId></Condition></Request>", &err)
        
        if err != nil{
            ShowErrorAlert(self,title: "取得定期成績資料發生錯誤",msg: err.message)
            return retVal
        }
        
        var xml: AEXMLDocument?
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        
        if let sceTakes = xml?.root["Response"]["SceTake"].all {
            for sceTake in sceTakes{
                let examName = sceTake["ExamName"].stringValue
                
                var examScore = ""
                var assignmentScore = ""
                
                if _isJH {
                    examScore = sceTake["Extension"]["Extension"]["Score"].stringValue
                }
                else{
                    examScore = sceTake["Score"].stringValue
                }
                
                if _isHS{
                    assignmentScore = sceTake["Extension"]["Extension"]["AssignmentScore"].stringValue
                }
                
                retVal.append(DisplayItem(Title: examName, Value: examScore, OtherInfo: "", ColorAlarm: false))
                
                if assignmentScore != ""{
                    retVal.append(DisplayItem(Title: examName + "(平時)", Value: assignmentScore, OtherInfo: "", ColorAlarm: false))
                }
            }
        }
        
        rsp = _con.SendRequest("courseTeacher.GetCourseScore", bodyContent: "<Request><Condition><RefStudentId>\(StudentData.ID)</RefStudentId><RefCourseId>\(StudentData.ClassID)</RefCourseId></Condition></Request>", &err)
        
        if err != nil{
            ShowErrorAlert(self,title: "取得課程成績資料發生錯誤",msg: err.message)
            return retVal
        }
        
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        let courseScore = xml?.root["Response"]["CourseScore"]["Score"].stringValue
        let ordinarilyScore = xml?.root["Response"]["CourseScore"]["Extension"]["Extension"]["OrdinarilyScore"].stringValue
        
        if !_isJH && courseScore != ""{
            retVal.append(DisplayItem(Title: "課程成績", Value: courseScore!, OtherInfo: "", ColorAlarm: false))
        }
        
        if _isJH && !_isHS && ordinarilyScore != ""{
            retVal.append(DisplayItem(Title: "課程平時成績", Value: ordinarilyScore!, OtherInfo: "", ColorAlarm: false))
        }
        
        return retVal
    }
    
    //new solution
    func CheckDSNS() {
        
        self._isJH = false
        self._isHS = false
        
        //encode成功呼叫查詢
        if let encodingName = StudentData.DSNS.UrlEncoding{
            
            let data = try? HttpClient.Get("http://dsns.1campus.net/campusman.ischool.com.tw/config.public/GetSchoolList?content=%3CRequest%3E%3CMatch%3E\(encodingName)%3C/Match%3E%3CPagination%3E%3CPageSize%3E10%3C/PageSize%3E%3CStartPage%3E1%3C/StartPage%3E%3C/Pagination%3E%3C/Request%3E")
            
            if let rsp = data{
                
                var nserr : NSError?
                
                let xml: AEXMLDocument?
                do {
                    xml = try AEXMLDocument(xmlData: rsp)
                } catch _ {
                    xml = nil
                }
                
                if let coreSystem = xml?.root["Response"]["School"]["CoreSystem"].stringValue{
                    
                    if coreSystem == "國中新竹" || coreSystem == "實驗雙語部"{
                        self._isJH = true
                        self._isHS = true
                    }
                    else if coreSystem == "國中高雄"{
                        self._isJH = true
                    }
                    
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _displayData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let data = _displayData[indexPath.row]
        
        var cell = tableView.dequeueReusableCellWithIdentifier("summaryItem")
        
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "summaryItem")
            cell?.textLabel?.textColor = UIColor(red: 19/255, green: 144/255, blue: 255/255, alpha: 1)
        }
        
        cell!.textLabel?.text = data.Title
        cell!.detailTextLabel?.text = data.Value
//        
//        if data.ColorAlarm{
//            cell!.detailTextLabel?.textColor = UIColor.redColor()
//        }
//        else{
//            cell!.detailTextLabel?.textColor = UIColor.lightGrayColor()
//        }
        
        return cell!
    }
    
    
}

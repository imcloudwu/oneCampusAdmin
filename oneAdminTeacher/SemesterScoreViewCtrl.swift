//
//  SemesterScoreViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/3/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class SemesterScoreViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,ContainerViewProtocol {
    
    var _con : Connection!
    
    var _data = [ScoreInfoItem]()
    var _displayData = [DisplayItem]()
    var _Semesters = [SemesterItem]()
    var _CurrentSemester : SemesterItem!
    var StudentData : Student!
    
    var progressTimer : ProgressTimer!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var ParentNavigationItem : UINavigationItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressTimer = ProgressTimer(progressBar: progress)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: self, action: "ChangeSemester")
        
        //ParentNavigationItem?.rightBarButtonItems?.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: self, action: "ChangeSemester"))
        ParentNavigationItem?.rightBarButtonItems?.append(UIBarButtonItem(image: UIImage(named: "Age-25.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ChangeSemester"))
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if _data.count > 0{
            return
        }
        
        progressTimer.StartProgress()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            
            //self._con = GetCommonConnect(self.StudentData.DSNS, self._con, self)
            self._con = GetCommonConnect(self.StudentData.DSNS)
            self._data = self.GetScoreInfoData()
            self._Semesters = GetSemesters(self._data)
            
            dispatch_async(dispatch_get_main_queue(), {
                if self._Semesters.count > 0{
                     self.noDataLabel.hidden = true
                    self.SetDataToTableView(self._Semesters[0])
                }
                else{
                     self.noDataLabel.hidden = false
                }
                
                self.progressTimer.StopProgress()
            })
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func ChangeSemester(){
        let actionSheet = UIAlertController(title: "請選擇學年度學期", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        for semester in _Semesters{
            actionSheet.addAction(UIAlertAction(title: semester.Description, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.SetDataToTableView(semester)
            }))
        }
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func SetDataToTableView(semester:SemesterItem){
        
        self._CurrentSemester = semester
        
        var currentData:ScoreInfoItem!
        //找出對應的ScoreInfoItem
        for data in _data{
            if data.SchoolYear == semester.SchoolYear && data.Semester == semester.Semester{
                currentData = data
                break
            }
        }
        
        if currentData.IsJH{
            _displayData = GetJhItems(currentData)
        }
        else{
            _displayData = GetShItems(currentData)
        }
        
        tableView.reloadData()
    }
    
    func GetJhItems(currentData:ScoreInfoItem) -> [DisplayItem]{
        
        var retVal = [DisplayItem]()
        
        var underSixtyDomainCount = 0
        
        var domainList = [String]()
        
        for domain in currentData.Domains{
            //把處理過的domain name記下來
            domainList.append(domain.Domain)
            
            retVal.append(domain.GetJhDisplayItem())
            //不及格的領域數量
            if domain.Score.doubleValue < 60{
                underSixtyDomainCount++
            }
            //該領域的科目一起呈現
            for subject in currentData.Subjects{
                if subject.Domain == domain.Domain{
                    
                    retVal.append(subject.GetJhDisplayItem())
                }
            }
        }
        
        //沒處理過的領域,直接列出該科目
        var tmp = [DisplayItem]()
        for subject in currentData.Subjects{
            if !domainList.contains(subject.Domain){
                tmp.append(subject.GetJhDisplayItem())
            }
        }
        
        if tmp.count > 0{
            retVal.append(DisplayItem(Title: "Unknown Domain", Value: "", OtherInfo: "summaryItem", ColorAlarm: false))
            
            for t in tmp{
                retVal.append(t)
            }
        }
        
        retVal.insert(DisplayItem(Title: "課程學期成績", Value: currentData.CourseLearnScore, OtherInfo: "summaryItem", ColorAlarm: currentData.CourseLearnScore.doubleValue < 60), atIndex: 0)
        retVal.insert(DisplayItem(Title: "學習領域成績", Value: currentData.LearnDomainScore, OtherInfo: "summaryItem", ColorAlarm: currentData.LearnDomainScore.doubleValue < 60), atIndex: 0)
        retVal.insert(DisplayItem(Title: "不及格領域數", Value: "\(underSixtyDomainCount)", OtherInfo: "summaryItem", ColorAlarm: false), atIndex: 0)
        
        return retVal
    }
    
    func GetShItems(currentData:ScoreInfoItem) -> [DisplayItem]{
        
        var retVal = [DisplayItem]()
        
        var 實得 = 0
        var 已修 = 0
        var 必修 = 0
        var 選修 = 0
        var 實習 = 0
        var 校訂必修 = 0
        var 校訂選修 = 0
        var 部訂必修 = 0
        var 部訂選修 = 0
        
        for subject in currentData.Subjects{
            
            retVal.append(subject.GetShDisplayItem())
            
            已修 += subject.Credit
            
            if subject.IsReach{
                實得 += subject.Credit
            }
            
            if subject.IsLearning{
                實習 += subject.Credit
            }
            
            if subject.IsSchoolPlan && subject.IsRequire{
                校訂必修 += subject.Credit
            }
            else if subject.IsSchoolPlan && !subject.IsRequire{
                校訂選修 += subject.Credit
            }
            else if !subject.IsSchoolPlan && subject.IsRequire{
                部訂必修 += subject.Credit
            }
            else{
                部訂選修 += subject.Credit
            }
            
        }
        
        必修 = 校訂必修 + 部訂必修
        選修 = 校訂選修 + 部訂選修
        
        let 實得item = DisplayItem(Title: "實得", Value: "\(實得)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        let 已修item = DisplayItem(Title: "已修", Value: "\(已修)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        let 必修item = DisplayItem(Title: "必修", Value: "\(必修)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        let 選修item = DisplayItem(Title: "選修", Value: "\(選修)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        let 實習item = DisplayItem(Title: "實習", Value: "\(實習)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        let 校訂必修item = DisplayItem(Title: "校訂必修", Value: "\(校訂必修)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        let 校訂選修item = DisplayItem(Title: "校訂選修", Value: "\(校訂選修)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        let 部訂必修item = DisplayItem(Title: "部訂必修", Value: "\(部訂必修)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        let 部訂選修item = DisplayItem(Title: "部訂選修", Value: "\(部訂選修)", OtherInfo: "summaryItem", ColorAlarm: false)
        
        retVal.insert(部訂選修item, atIndex: 0)
        retVal.insert(部訂必修item, atIndex: 0)
        retVal.insert(校訂選修item, atIndex: 0)
        retVal.insert(校訂必修item, atIndex: 0)
        retVal.insert(實習item, atIndex: 0)
        retVal.insert(選修item, atIndex: 0)
        retVal.insert(必修item, atIndex: 0)
        retVal.insert(已修item, atIndex: 0)
        retVal.insert(實得item, atIndex: 0)
        
        return retVal
    }
    
    func GetScoreInfoData() -> [ScoreInfoItem]{
        var err : DSFault!
        var nserr : NSError?
        var retVal = [ScoreInfoItem]()
        
        var rsp = _con.SendRequest("semesterScore.GetStudentSemsScore", bodyContent: "<Request><All></All><RefStudentId>\(StudentData.ID)</RefStudentId></Request>", &err)
        
        if err != nil{
            ShowErrorAlert(self,title: "取得資料發生錯誤",msg: err.message)
            return retVal
        }
        
        let xml: AEXMLDocument?
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        
        if let semsSubjScores = xml?.root["Response"]["SemsSubjScore"].all{
            
            for ss in semsSubjScores{
                
                let va = "<root>" + ss["ScoreInfo"].stringValue + "</root>"
                
                let child = try? AEXMLDocument(xmlData: va.dataValue)
                
                let schoolYear = ss.attributes["SchoolYear"]
                let semester = ss.attributes["Semester"]
                
                var scoreInfoItem = ScoreInfoItem(SchoolYear: schoolYear!, Semester: semester!, LearnDomainScore: "", CourseLearnScore: "", Subjects: [SemesterSubjectItem](), Domains: [SemesterDomainItem](), IsJH: false)
                
                //有抓到學習領域成績就以國中處理
                if let learnDomainScore = child?.root["LearnDomainScore"].first?.stringValue ,
                    let courseLearnScore = child?.root["CourseLearnScore"].first?.stringValue{
                    scoreInfoItem.LearnDomainScore = learnDomainScore
                    scoreInfoItem.CourseLearnScore = courseLearnScore
                    scoreInfoItem.IsJH = true
                }
                
                //國中資料解析
                if scoreInfoItem.IsJH{
                    //科目成績
                    if let infos = child?.root["SemesterSubjectScoreInfo"]["Subject"].all{
                        
                        for info in infos {
                            let subject = info.attributes["科目"]
                            let credit = info.attributes["權數"]?.intValue
                            let period = info.attributes["節數"]
                            let domain = info.attributes["領域"]
                            let score = info.attributes["成績"]
                            
                            let subjecItem = SemesterSubjectItem(SchoolYear: schoolYear!, Semester: semester!, Subject: subject!, Domain: domain!, Period: period!, Credit: credit!, Score: score!, IsRequire: false, IsSchoolPlan: false, IsReach: score!.doubleValue > 60, IsLearning: false)
                            
                            scoreInfoItem.Subjects.append(subjecItem)
                            
                        }
                    }
                    //領域成績
                    if let infos = child?.root["Domains"]["Domain"].all{
                        
                        for info in infos {
                            let domain = info.attributes["領域"]
                            let credit = info.attributes["權數"]?.intValue
                            let period = info.attributes["節數"]
                            let score = info.attributes["成績"]
                            
                            let domainItem = SemesterDomainItem(SchoolYear: schoolYear!, Semester: semester!, Domain: domain!, Period: period!, Credit: credit!, Score: score!)
                            
                            scoreInfoItem.Domains.append(domainItem)
                        }
                    }
                
                }
                else{
                    //高中資料解析
                    if let infos = child?.root["SemesterSubjectScoreInfo"]["Subject"].all{
                        
                        for info in infos {
                            let subject = info.attributes["科目"]
                            let credit = info.attributes["開課學分數"]?.intValue
                            let isRequire = info.attributes["修課必選修"] == "必修" ? true : false
                            let isSchoolPlan = info.attributes["修課校部訂"] == "校訂" ? true : false
                            let isReach = info.attributes["是否取得學分"] == "是" ? true : false
                            let isLearning = info.attributes["開課分項類別"] == "實習科目" ? true : false
                            let score = info.attributes["原始成績"]
                            
                            let subjecItem = SemesterSubjectItem(SchoolYear: schoolYear!, Semester: semester!, Subject: subject!, Domain: "", Period: "", Credit: credit!, Score: score!, IsRequire: isRequire, IsSchoolPlan: isSchoolPlan, IsReach: isReach, IsLearning: isLearning)
                            
                            scoreInfoItem.Subjects.append(subjecItem)
                        }
                    }
                }
                
                retVal.append(scoreInfoItem)
            }
            
        }
        
        return retVal
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _displayData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let data = _displayData[indexPath.row]
        
        if data.OtherInfo == "summaryItem"{
            var cell = tableView.dequeueReusableCellWithIdentifier("summaryItem")
            
            if cell == nil{
                cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "summaryItem")
                cell?.textLabel?.textColor = UIColor(red: 19/255, green: 144/255, blue: 255/255, alpha: 1)
            }
            
            cell!.textLabel?.text = data.Title
            cell!.detailTextLabel?.text = data.Value
            
            if data.ColorAlarm{
                cell!.detailTextLabel?.textColor = UIColor.redColor()
            }
            else{
                cell!.detailTextLabel?.textColor = UIColor.lightGrayColor()
            }
            
            return cell!
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("semesterScoreItemCell") as! SemesterScoreItemCell
        cell.Subject.text = data.Title
        cell.Info.text = data.OtherInfo
        cell.Score.text = data.Value
        
        if data.ColorAlarm{
            cell.Score.textColor = UIColor.redColor()
        }
        else{
            cell.Score.textColor = UIColor.blackColor()
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _CurrentSemester?.Description
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        if _displayData[indexPath.row].OtherInfo == "summaryItem"{
            return 30
        }
        
        return 62
    }
    
    
}

struct ScoreInfoItem : SemesterProtocol{
    var SchoolYear : String
    var Semester : String
    var LearnDomainScore : String
    var CourseLearnScore : String
    var Subjects : [SemesterSubjectItem]
    var Domains : [SemesterDomainItem]
    var IsJH : Bool
}

struct SemesterSubjectItem : SemesterProtocol{
    var SchoolYear : String
    var Semester : String
    var Subject : String
    var Domain : String
    var Period : String
    var Credit : Int
    var Score: String
    var IsRequire : Bool
    var IsSchoolPlan : Bool
    var IsReach : Bool
    var IsLearning : Bool
    
    func GetJhDisplayItem() -> DisplayItem{
        let underSixty = Score.doubleValue < 60 ? true : false
        let subpc = "節權數 : \(Period) / \(Credit)"
        
        return DisplayItem(Title: Subject, Value: Score, OtherInfo: subpc, ColorAlarm: underSixty)
    }
    
    func GetShDisplayItem() -> DisplayItem{
        
        var info = IsSchoolPlan ? "校訂" : "部訂"
        info += IsRequire ? "必修" : "選修"
        info += "     學分 : \(Credit)"
        
        return DisplayItem(Title: Subject, Value: Score, OtherInfo: info, ColorAlarm: !IsReach)
    }
}

struct SemesterDomainItem : SemesterProtocol{
    var SchoolYear : String
    var Semester : String
    var Domain : String
    var Period : String
    var Credit : Int
    var Score: String
    
    func GetJhDisplayItem() -> DisplayItem{
        let pc = " \(Period) / \(Credit)"
        return DisplayItem(Title: Domain + pc, Value: Score, OtherInfo: "summaryItem", ColorAlarm: Score.doubleValue < 60)
    }
}
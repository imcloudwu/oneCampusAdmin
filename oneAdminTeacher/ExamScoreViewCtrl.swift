//
//  ExamScoreViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/7/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class ExamScoreViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,ContainerViewProtocol {
    
    var _isJH = false
    var _isHS = false
    var _SubjectScales : Int16 = 2
    var _DomainScales : Int16 = 2
    
    var _con : Connection!
    var _CurrentSemester : SemesterItem!
    var _ExamList = [String]()
    var _CurrentExam = ""
    
    var _data = [ExamScoreItem]()
    var _displayData = [DisplayItem]()
    var _Semesters = [SemesterItem]()
    var StudentData : Student!
    
    var progressTimer : ProgressTimer!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var ExamBtn : UIBarButtonItem!
    
    var ParentNavigationItem : UINavigationItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        progressTimer = ProgressTimer(progressBar: progress)
        
        ExamBtn = UIBarButtonItem(image: UIImage(named: "Edit Property-25.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ChangeExam")
        ExamBtn.enabled = false
        
        //self.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: self, action: "ChangeSemester")]
        //self.navigationItem.rightBarButtonItems?.append(ExamBtn)
        
        //ParentNavigationItem?.rightBarButtonItems?.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: self, action: "ChangeSemester"))
        ParentNavigationItem?.rightBarButtonItems?.append(UIBarButtonItem(image: UIImage(named: "Age-25.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ChangeSemester"))
        ParentNavigationItem?.rightBarButtonItems?.append(ExamBtn)
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: self, action: "ChangeSemester")
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if _data.count > 0{
            return
        }
        
        progressTimer.StartProgress()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            
            //self._con = GetCommonConnect(self.StudentData.DSNS, self._con, self)
            self._con = GetCommonConnect(self.StudentData.DSNS)
            self.CheckDSNS()
            
            if self._isJH{
                self.SetScoreCalcRule()
                self._data = self.GetJHData()
            }
            else{
                self._data = self.GetSHData()
            }
            
            self._Semesters = GetSemesters(self._data)
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if self._Semesters.count > 0{
                    self.noDataLabel.hidden = true
                    self.SelectSemester(self._Semesters[0])
                }
                else{
                    self.noDataLabel.hidden = false
                }
                
                self.progressTimer.StopProgress()
                
            })
        })
    }
    
    func ChangeSemester(){
        let actionSheet = UIAlertController(title: "請選擇學年度學期", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        for semester in _Semesters{
            actionSheet.addAction(UIAlertAction(title: semester.Description, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                
                    self.SelectSemester(semester)
                
            }))
        }
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func ChangeExam(){
        let actionSheet = UIAlertController(title: "請選擇考試別", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        for exam in _ExamList{
            actionSheet.addAction(UIAlertAction(title: exam, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                
                self.SetJHDataToTableView(exam)
                
            }))
        }
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func SelectSemester(semester:SemesterItem){
        
        self._CurrentSemester = semester
        
        if _isJH{
            _ExamList.removeAll(keepCapacity: false)
            
            let datas = GetMatchExamScoreItem(nil)
            
            //datas.sort({$0.DisplayOrder < $1.DisplayOrder})
            
            for data in datas{
                if !_ExamList.contains(data.Exam){
                    _ExamList.append(data.Exam)
                }
            }
            
            if _ExamList.count > 0{
                SetJHDataToTableView(_ExamList[0])
            }
            
            CheckExamBtn()
        }
        else{
            SetSHDataToTableView()
        }
    }
    
    func SetJHDataToTableView(examName : String){
        
        self._CurrentExam = examName
        var displayData = [DisplayItem]()
        
        let matchDatas = GetMatchExamScoreItem(examName)
        let domains = GetDomainList(matchDatas)
        
        //將相同領域的資料排在一起
        var collections = [String:[ExamScoreItem]]()
        for mData in matchDatas{
            if collections[mData.Domain] == nil{
                collections[mData.Domain] = [ExamScoreItem]()
            }
            
            collections[mData.Domain]?.append(mData)
        }
        
        //按領域順序呈現
        for domain in domains{
            
            //displayData.append(DisplayItem(Title: domain.Name, Value: "socre here", OtherInfo: "summaryItem", ColorAlarm: false))
            
            let items : [ExamScoreItem] = collections[domain.Name]!
            
            var sumCredit = Double(0)
            var sumScore = Double(0)
            
            var mustAppendItem = [DisplayItem]()
            
            for item in items{
                let data = item
                var avg = data.GetJHScore()
                
                if !avg.isNaN{
                    
                    avg = avg.Round(_SubjectScales)
                    
                    mustAppendItem.append(DisplayItem(Title: data.Subject, Value: "\(avg.ToString(_SubjectScales))", OtherInfo: "定期 : \(data.Score)", OtherInfo2: "平時 : \(data.AssignmentScore)", OtherInfo3: "權數 : \(data.Credit)", ColorAlarm: avg < 60))
                    
                    sumCredit += data.Credit.doubleValue
                    sumScore += data.Credit.doubleValue * avg
                }
            }
            
            var sumAvg = sumScore / sumCredit
            
            if !sumAvg.isNaN{
                
                sumAvg = sumAvg.Round(_DomainScales)
                displayData.append(DisplayItem(Title: domain.Name, Value: sumAvg.ToString(_DomainScales), OtherInfo: "summaryItem", ColorAlarm: sumAvg < 60))
                
                displayData += mustAppendItem
            }
        }
        
        _displayData = displayData
        
        tableView.reloadData()
    }
    
    func SetSHDataToTableView(){
        
        var displayData = [DisplayItem]()
        
        let matchDatas = GetMatchExamScoreItem(nil)
        let subjects = GetSubjectList(matchDatas)
        
        //將相同課程的資料排在一起
        var collections = [String:[ExamScoreItem]]()
        for mData in matchDatas{
            if collections[mData.CourseID] == nil{
                collections[mData.CourseID] = [ExamScoreItem]()
            }
            
            collections[mData.CourseID]?.append(mData)
        }
        
        //按科目順序呈現
        for subject in subjects{
            
            displayData.append(DisplayItem(Title: subject.Name, Value: "", OtherInfo: "summaryItem", ColorAlarm: false))
            
            let items : [ExamScoreItem] = collections[subject.CourseID]!
            
            //items.sort({$0.DisplayOrder < $1.DisplayOrder})
            
            var lastScore = Double.NaN
            for item in items{
                var result : String!
                let scoreValue = item.GetSHScore()
                
                if lastScore.isNaN || scoreValue.isNaN || scoreValue == lastScore{
                    result = "event"
                }
                else if scoreValue > lastScore{
                    result = "up"
                }
                else{
                    result = "down"
                }
                
                lastScore = scoreValue
                
                displayData.append(DisplayItem(Title: item.Exam, Value: item.Score, OtherInfo: result, ColorAlarm: scoreValue < 60))
            }
        }
        
        _displayData = displayData
        
        tableView.reloadData()
    }
    
    func SetScoreCalcRule(){
        var err : DSFault!
        let rsp = _con.SendRequest("examScore.GetScoreCalcRule", bodyContent: "<Request><StudentID>\(StudentData.ID)</StudentID></Request>", &err)
        
        var nserr : NSError?
        
        let xml: AEXMLDocument?
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        
        if let subjectScales = xml?.root["ScoreCalcRule"]["SubjectScales"].stringValue{
            _SubjectScales = subjectScales.int16Value
        }
        
        if let domainScales = xml?.root["ScoreCalcRule"]["DomainScales"].stringValue{
            _DomainScales = domainScales.int16Value
        }
    }
    
    //取得高中資料
    func GetSHData() -> [ExamScoreItem]{
        
        var retVal = [ExamScoreItem]()
        
        var err : DSFault!
        let rsp = _con.SendRequest("examScore.GetExamScoreSH", bodyContent: "<Request><Condition><StudentID>\(StudentData.ID)</StudentID></Condition></Request>", &err)
        
        var nserr : NSError?
        
        let xml: AEXMLDocument?
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        
        if let semes = xml?.root["ExamScoreList"]["Seme"].all{
            for seme in semes{
                let schoolYear = seme.attributes["SchoolYear"]
                let semester = seme.attributes["Semester"]
                
                if let courses = seme["Course"].all{
                    for course in courses{
                        
                        let courseID = course.attributes["CourseID"]
                        let subject = course.attributes["Subject"]
                        let credit = course.attributes["Credit"]
                        
                        if let exams = course["Exam"].all{
                            for exam in exams{
                                let examDisplayOrder = exam.attributes["ExamDisplayOrder"]?.intValue
                                let examName = exam.attributes["ExamName"]
                                
                                let score = exam["ScoreDetail"].attributes["Score"]
                                
                                let item = ExamScoreItem(SchoolYear: schoolYear!, Semester: semester!, CourseID: courseID!,Domain: "", Subject: subject!, Credit: credit!, Exam: examName!, Score: score!, AssignmentScore: "", DisplayOrder: examDisplayOrder!, ScorePercentage: 0)
                                
                                retVal.append(item)
                            }
                        }
                    }
                    
                }
                
            }
        }
        
        return retVal
    }
    
    //取得國中資料
    func GetJHData() -> [ExamScoreItem]{
     
        var retVal = [ExamScoreItem]()
        
        var err : DSFault!
        let rsp = _con.SendRequest("examScore.GetExamScoreJH", bodyContent: "<Request><Condition><StudentID>\(StudentData.ID)</StudentID></Condition></Request>", &err)
        
        var nserr : NSError?
        
        let xml: AEXMLDocument?
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        
        if let semes = xml?.root["ExamScoreList"]["Seme"].all{
            for seme in semes{
                let schoolYear = seme.attributes["SchoolYear"]
                let semester = seme.attributes["Semester"]
                
                if let courses = seme["Course"].all{
                    
                    for course in courses{
                        
                        let courseID = course.attributes["CourseID"]
                        let subject = course.attributes["Subject"]
                        let credit = course.attributes["Credit"]
                        let domain = course.attributes["Domain"]
                        
                        let scorePercentage = course["FixTime"]["Extension"]["ScorePercentage"].stringValue.doubleValue
                        
                        //針對高雄的資料新增平時成績
                        if !_isHS , let ordinarilyScore = course["FixExtension"]["Extension"]["OrdinarilyScore"].first?.stringValue{
                            let item = ExamScoreItem(SchoolYear: schoolYear!, Semester: semester!, CourseID: courseID!, Domain: domain!, Subject: subject!, Credit: credit!, Exam: "平時成績", Score: ordinarilyScore, AssignmentScore: "", DisplayOrder: 99, ScorePercentage: scorePercentage)
                            
                            retVal.append(item)
                        }
                        
                        if let exams = course["Exam"].all{
                            for exam in exams{
                                let examDisplayOrder = exam.attributes["ExamDisplayOrder"]?.intValue
                                let examName = exam.attributes["ExamName"]
                                var score = ""
                                
                                var assignmentScore = ""
                                
                                if let tmpScore = exam["ScoreDetail"]["Extension"]["Extension"]["Score"].first?.stringValue{
                                    score = tmpScore
                                }
                                
                                if let tmpAssignmentScore = exam["ScoreDetail"]["Extension"]["Extension"]["AssignmentScore"].first?.stringValue{
                                    assignmentScore = tmpAssignmentScore
                                }
                                
                                let item = ExamScoreItem(SchoolYear: schoolYear!, Semester: semester!, CourseID: courseID!, Domain: domain!, Subject: subject!, Credit: credit!, Exam:
                                    examName!, Score: score, AssignmentScore: assignmentScore, DisplayOrder: examDisplayOrder!, ScorePercentage: scorePercentage)
                                
                                retVal.append(item)
                            }
                        }
                    }
                }
            }
        }
        
        return retVal
    }
    
    func GetMatchExamScoreItem(examName:String?) -> [ExamScoreItem]{
        
        var retVal = [ExamScoreItem]()
        
        if examName == nil{
            for data in _data{
                if data.SchoolYear == _CurrentSemester.SchoolYear && data.Semester == _CurrentSemester.Semester{
                    retVal.append(data)
                }
            }
        }
        else{
            for data in _data{
                if data.SchoolYear == _CurrentSemester.SchoolYear && data.Semester == _CurrentSemester.Semester && data.Exam == examName{
                    retVal.append(data)
                }
            }
        }
        
        if _isJH {
            retVal.sortInPlace({$0.DisplayOrder < $1.DisplayOrder})
        }
        
        return retVal
    }
    
    func GetDomainList(sourceDatas:[ExamScoreItem]) -> [Domain]{
        
        var retVal = [Domain]()
        
        for data in sourceDatas{
            let domain = Domain(Name: data.Domain)
            
            if !retVal.contains(domain){
                retVal.append(domain)
            }
        }
        
        return retVal
    }
    
    func GetSubjectList(sourceDatas:[ExamScoreItem]) -> [Subject]{
        
        var retVal = [Subject]()
        
        for data in sourceDatas{
            let subject = Subject(CourseID: data.CourseID,Name: data.Subject)
            
            if !retVal.contains(subject){
                retVal.append(subject)
            }
        }
        
        //retVal.sort({$0.CourseID < $1.CourseID})
        
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
    
    func CheckExamBtn(){
        if _ExamList.count > 0{
            ExamBtn.enabled = true
        }
        else{
            ExamBtn.enabled = false
        }
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
                cell!.detailTextLabel?.textColor = UIColor.blackColor()
            }
            
            return cell!
            
        }else{
            
            if _isJH{
                var cell = tableView.dequeueReusableCellWithIdentifier("examScoreMoreInfoItemCell") as! ExamScoreMoreInfoItemCell
                cell.ExamName.text = data.Title
                cell.Score.text = data.Value
                cell.Info1.text = data.OtherInfo
                cell.Info2.text = data.OtherInfo2
                cell.Info3.text = data.OtherInfo3
                
                if _isHS{
                    cell.Info1.hidden = false
                    cell.Info2.hidden = false
                }
                else{
                    cell.Info1.hidden = true
                    cell.Info2.hidden = true
                }
                
                if data.ColorAlarm{
                    cell.Score.textColor = UIColor.redColor()
                }
                else{
                    cell.Score.textColor = UIColor.blackColor()
                }
                
                return cell
            }
            else{
                var cell = tableView.dequeueReusableCellWithIdentifier("examScoreItemCell") as! ExamScoreItemCell
                
                if cell.accessoryView == nil{
                    let lab = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                    lab.textAlignment = NSTextAlignment.Center
                    cell.accessoryView = lab
                }
                
                cell.ExamName.text = data.Title
                cell.Score.text = data.Value
                
                var lab = cell.accessoryView as! UILabel
                
                if data.OtherInfo == "up"{
                    lab.text = "↑"
                    lab.textColor = UIColor.greenColor()
                }
                else if data.OtherInfo == "down"{
                    lab.text = "↓"
                    lab.textColor = UIColor.redColor()
                }
                else{
                    lab.text = ""
                }
                
                if data.ColorAlarm{
                    cell.Score.textColor = UIColor.redColor()
                }
                else{
                    cell.Score.textColor = UIColor.blackColor()
                }
                
                return cell
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = ""
        
        if let description = _CurrentSemester?.Description{
            title += description
        }
        
        title += " \(_CurrentExam)"
        
        if title == " "{
            return nil
        }
        
        return title
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        if _isJH && _displayData[indexPath.row].OtherInfo == "summaryItem"{
            return 30
        }
        else if !_isJH && _displayData[indexPath.row].OtherInfo != "summaryItem"{
            return 30
        }
        
        return 50
    }
    
}

struct ExamScoreItem : SemesterProtocol{
    var SchoolYear : String
    var Semester : String
    var CourseID : String
    var Domain : String
    var Subject : String
    var Credit : String
    var Exam : String
    var Score : String
    var AssignmentScore : String
    var DisplayOrder : Int
    var ScorePercentage : Double
    //var Avg:String
    
    func GetSHScore() -> Double{
        if Score.isEmpty{
            return Double.NaN
        }
        
        return Score.doubleValue
    }
    
    func GetJHScore() -> Double{
        
        if Score.isEmpty && AssignmentScore.isEmpty{
            return Double.NaN
        }
        else if Score.isEmpty && !AssignmentScore.isEmpty{
            return AssignmentScore.doubleValue
        }
        else if !Score.isEmpty && AssignmentScore.isEmpty{
            return Score.doubleValue
        }
        else{
            return (Score.doubleValue * ScorePercentage / 100) + (AssignmentScore.doubleValue * (100 - ScorePercentage) / 100)
        }
    }
}

struct Domain : Equatable{
    var Name : String
}

struct Subject : Equatable{
    var CourseID : String
    var Name : String
}

func ==(lhs: Domain, rhs: Domain) -> Bool {
    return lhs.Name == rhs.Name
}

func ==(lhs: Subject, rhs: Subject) -> Bool {
    return lhs.CourseID == rhs.CourseID && lhs.Name == rhs.Name
}
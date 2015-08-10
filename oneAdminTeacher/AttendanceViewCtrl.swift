//
//  AttendanceViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/1/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class AttendanceViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,ContainerViewProtocol {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var progressTimer:ProgressTimer!
    
    var _data = [AttendanceItem]()
    var _displayData = [AttendanceItem]()
    var _Semesters = [SemesterItem]()
    var _CurrentSemester : SemesterItem!
    
    var StudentData : Student!
    
    var _con : Connection!
    
    var ParentNavigationItem : UINavigationItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressTimer = ProgressTimer(progressBar: progress)
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: self, action: "ChangeSemester")
        
        ParentNavigationItem?.rightBarButtonItems?.append(UIBarButtonItem(image: UIImage(named: "Age-25.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ChangeSemester"))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if self._data.count > 0{
            return
        }
        
        progressTimer.StartProgress()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            
            //self._con = GetCommonConnect(self.StudentData.DSNS, self._con, self)
            self._con = GetCommonConnect(self.StudentData.DSNS)
            self._data = self.GetAttendanceData()
            
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
    
    func GetAttendanceData() -> [AttendanceItem]{
        
        var err : DSFault!
        var nserr : NSError?
        
        var retVal = [AttendanceItem]()
        
        var rsp = _con.SendRequest("attendance.GetStudentAttendance", bodyContent: "<Request><RefStudentId>\(StudentData.ID)</RefStudentId></Request>", &err)
        
        if err != nil{
            ShowErrorAlert(self,"取得資料發生錯誤",err.message)
            return retVal
        }
        
        let xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
        
        if let attendances = xml?.root["Response"]["Attendance"].all {
            for attendance in attendances{
                let occurDate = attendance.attributes["OccurDate"] as! String
                let schoolYear = attendance.attributes["SchoolYear"] as! String
                let semester = attendance.attributes["Semester"] as! String
                
                if let periods = attendance["Detail"]["Period"].all {
                    for period in periods{
                        let absenceType = period.attributes["AbsenceType"] as! String
                        let periodName = period.stringValue
                        
                        let item = AttendanceItem(OccurDate: occurDate, SchoolYear: schoolYear, Semester: semester, AbsenceType: absenceType, Period: periodName, Value: 1)
                        
                        retVal.append(item)
                    }
                }
                
            }
        }
        
        return retVal
    }
    
    func SetDataToTableView(semester:SemesterItem){
        
        self._CurrentSemester = semester
        var newData = [AttendanceItem]()
        var tmpData = [String:AttendanceItem]()
        
        for data in self._data{
            if data.SchoolYear == semester.SchoolYear && data.Semester == semester.Semester{
                
                //先合併同一天的假別
                let key = data.OccurDate + "_" + data.AbsenceType
                
                if tmpData[key] == nil{
                    tmpData[key] = data
                }
                else{
                    tmpData[key]?.Period += ",\(data.Period)"
                    tmpData[key]?.Value += data.Value
                }
            }
        }
        
        newData = tmpData.values.array
        
        newData.sort{$0.OccurDate > $1.OccurDate}
        
        var sum = [String:Int]()
        
        //統計相同假別的數量
        for data in newData{
            if sum[data.AbsenceType] == nil{
                sum[data.AbsenceType] = 0
            }
            
            sum[data.AbsenceType]? += data.Value
        }
        
        var total = 0
        
        //按個別假別種類建立一個summary item
        for s in sum{
            var summaryItem = AttendanceItem(OccurDate: "", SchoolYear: "", Semester: "", AbsenceType: s.0, Period: "", Value: s.1)
            newData.insert(summaryItem, atIndex: 0)
            total += s.1
        }
        
        //總計
        newData.insert(AttendanceItem(OccurDate: "", SchoolYear: "", Semester: "", AbsenceType: "總計", Period: "", Value: total), atIndex: 0)
        
        self._displayData = newData
        
        self.tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _displayData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let data = _displayData[indexPath.row]
        
        //處理summmary item
        if data.SchoolYear == "" && data.Semester == ""{
            var cell = tableView.dequeueReusableCellWithIdentifier("summaryItem") as? UITableViewCell
            
            if cell == nil{
                cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "summaryItem")
                cell?.textLabel?.textColor = UIColor(red: 19/255, green: 144/255, blue: 255/255, alpha: 1)
            }
            
            cell!.textLabel?.text = data.AbsenceType
            cell!.detailTextLabel?.text = "\(_displayData[indexPath.row].Value)"
            
            return cell!
        }
        
        //處理一般的cell
        let cell = tableView.dequeueReusableCellWithIdentifier("attendanceItemCell") as! AttendanceItemCell
        
        cell.Date.text = data.OccurDate
        cell.Type.text = data.AbsenceType + " (\(data.Value))"
        cell.Periods.text = data.Period
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _CurrentSemester?.Description
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        if _displayData[indexPath.row].SchoolYear == "" && _displayData[indexPath.row].Semester == ""{
            return 30
        }
        
        return 62
    }
    
}

struct AttendanceItem : SemesterProtocol{
    var OccurDate : String
    var SchoolYear : String
    var Semester : String
    var AbsenceType : String
    var Period : String
    var Value : Int
}

struct SemesterItem : Equatable,Comparable{
    var SchoolYear : String
    var Semester : String
    
    var Description: String {
        get {
            return "第\(SchoolYear)學年度\(Semester)學期"
        }
    }
    
    var CompareValue : Int{
        if let sy = SchoolYear.toInt() , let sm = Semester.toInt(){
            return sy * 10 + sm
        }
        else{
            return 0
        }
    }
}

func ==(lhs: SemesterItem, rhs: SemesterItem) -> Bool {
    return lhs.SchoolYear == rhs.SchoolYear && lhs.Semester == rhs.Semester
}

func <(lhs: SemesterItem, rhs: SemesterItem) -> Bool{
    return lhs.CompareValue < rhs.CompareValue
}

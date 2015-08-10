//
//  DisciplineViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/2/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class DisciplineViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,ContainerViewProtocol {
    
    var _con : Connection!
    
    var _data = [DisciplineItem]()
    var _displayData = [DisciplineItem]()
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
            
            self._data = self.GetDisciplineData()
            
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
        
        var newData = [DisciplineItem]()
        
        var ma = 0
        var mb = 0
        var mc = 0
        var da = 0
        var db = 0
        var dc = 0
        
        for data in _data{
            if data.SchoolYear == semester.SchoolYear && data.Semester == semester.Semester{
                
                ma += data.MA
                mb += data.MB
                mc += data.MC
                
                if !data.IsClear{
                    da += data.DA
                    db += data.DB
                    dc += data.DC
                }
                
                newData.append(data)
            }
        }
        
        newData.sort{$0.Date > $1.Date}
        
        let sumMItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "獎勵總計", IsClear: false, MA: ma, MB: mb, MC: mc, DA: 0, DB: 0, DC: 0)
        let maItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "大功", IsClear: false, MA: ma, MB: 0, MC: 0, DA: 0, DB: 0, DC: 0)
        let mbItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "小功", IsClear: false, MA: 0, MB: mb, MC: 0, DA: 0, DB: 0, DC: 0)
        let mcItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "嘉獎", IsClear: false, MA: 0, MB: 0, MC: mc, DA: 0, DB: 0, DC: 0)
        
        let sumDItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "懲戒總計", IsClear: false, MA: 0, MB: 0, MC: 0, DA: da, DB: db, DC: dc)
        let daItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "大過", IsClear: false, MA: 0, MB: 0, MC: 0, DA: da, DB: 0, DC: 0)
        let dbItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "小過", IsClear: false, MA: 0, MB: 0, MC: 0, DA: 0, DB: db, DC: 0)
        let dcItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "警告", IsClear: false, MA: 0, MB: 0, MC: 0, DA: 0, DB: 0, DC: dc)
        
        newData.insert(dcItem, atIndex: 0)
        newData.insert(dbItem, atIndex: 0)
        newData.insert(daItem, atIndex: 0)
        newData.insert(sumDItem, atIndex: 0)
        newData.insert(mcItem, atIndex: 0)
        newData.insert(mbItem, atIndex: 0)
        newData.insert(maItem, atIndex: 0)
        newData.insert(sumMItem, atIndex: 0)
        
        _displayData = newData
        
        tableView.reloadData()
    }
    
    func GetDisciplineData() -> [DisciplineItem]{
        
        var err : DSFault!
        var nserr : NSError?
        
        var retVal = [DisciplineItem]()
        
        var rsp = _con.SendRequest("discipline.GetStudentDiscipline", bodyContent: "<Request><RefStudentId>\(StudentData.ID)</RefStudentId></Request>", &err)
        
        if err != nil{
            ShowErrorAlert(self,"取得資料發生錯誤",err.message)
            return retVal
        }
        
        let xml = AEXMLDocument(xmlData: rsp.dataValue, error: &nserr)
        
        if let disciplines = xml?.root["Response"]["Discipline"].all {
            for discipline in disciplines{
                let occurDate = discipline.attributes["OccurDate"] as! String
                let schoolYear = discipline.attributes["SchoolYear"] as! String
                let semester = discipline.attributes["Semester"] as! String
                let meritFlag = (discipline.attributes["MeritFlag"] as! String) == "1" ? DisciplineType.Merit : DisciplineType.Demerit
                let reason = discipline["Reason"].stringValue
                
                var ma = 0
                var mb = 0
                var mc = 0
                var da = 0
                var db = 0
                var dc = 0
                var isClear = false
                
                if meritFlag == DisciplineType.Merit{
                    ma = (discipline["Merit"].attributes["A"] as! String).intValue
                    mb = (discipline["Merit"].attributes["B"] as! String).intValue
                    mc = (discipline["Merit"].attributes["C"] as! String).intValue
                }
                else{
                    da = (discipline["Demerit"].attributes["A"] as! String).intValue
                    db = (discipline["Demerit"].attributes["B"] as! String).intValue
                    dc = (discipline["Demerit"].attributes["C"] as! String).intValue
                    isClear = (discipline["Demerit"].attributes["Cleared"] as! String) == "是"
                }
                
                var item = DisciplineItem(Type: meritFlag, Date: occurDate, SchoolYear: schoolYear, Semester: semester, Reason: reason, IsClear: isClear, MA: ma, MB: mb, MC: mc, DA: da, DB: db, DC: dc)
                
                retVal.append(item)
            }
        }
        
        return retVal
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _displayData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let data = _displayData[indexPath.row]
        
        if data.Type == DisciplineType.Summary{
            var cell = tableView.dequeueReusableCellWithIdentifier("summaryItem") as? UITableViewCell
            
            if cell == nil{
                cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "summaryItem")
                cell?.textLabel?.textColor = UIColor(red: 19/255, green: 144/255, blue: 255/255, alpha: 1)
            }
            
            cell!.textLabel?.text = data.Reason
            cell!.detailTextLabel?.text = "\(data.Value)"
            
            return cell!
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("disciplineItemCell") as! DisciplineItemCell
        cell.Date.text = data.Date
        cell.Reason.text = data.Reason
        cell.Status.textColor = UIColor.blackColor()
        
        if data.Type == DisciplineType.Merit{
            cell.Status.text = "大功: \(data.MA) 小功: \(data.MB) 嘉獎: \(data.MC)"
        }
        else{
            cell.Status.text = "大過: \(data.DA) 小過: \(data.DB) 警告: \(data.DC)"
            cell.Status.textColor = UIColor.redColor()
            
            if data.IsClear{
                cell.Reason.text = "(已註銷) " + data.Reason
                cell.Status.textColor = UIColor.lightGrayColor()
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _CurrentSemester?.Description
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        if _displayData[indexPath.row].Type == DisciplineType.Summary{
            return 30
        }
        
        return 70
    }
    
}

struct DisciplineItem : SemesterProtocol{
    var Type:DisciplineType
    var Date:String
    var SchoolYear:String
    var Semester:String
    var Reason:String
    var IsClear:Bool
    var MA:Int
    var MB:Int
    var MC:Int
    var DA:Int
    var DB:Int
    var DC:Int
    
    var Value : Int{
        switch Reason{
        case "獎勵總計":
            return MA + MB + MC
        case "懲戒總計":
            return DA + DB + DC
        case "大功":
            return MA
        case "小功":
            return MB
        case "嘉獎":
            return MC
        case "大過":
            return DA
        case "小過":
            return DB
        case "警告":
            return DC
        default:
            return 0
        }
    }
}

enum DisciplineType : Int{
    case Merit,Demerit,Summary
}

//
//  DisciplineViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/2/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class DisciplineViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,ContainerViewProtocol {
    
    var _con = Connection()
    
    var _data = [DisciplineItem]()
    var _displayData = [DisciplineItem]()
    var _displayDataBase = [DisciplineItem]()
    var _Semesters = [SemesterItem]()
    var _CurrentSemester : SemesterItem!
    var StudentData : Student!
    
    var progressTimer : ProgressTimer!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var ParentNavigationItem : UINavigationItem?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var segment: UISegmentedControl!
    
    var _SegmentItems = [String]()
    
    @IBAction func SegmentSelect(sender: AnyObject) {
        
        let type = _SegmentItems[segment.selectedSegmentIndex]
        
        self._displayData = type == "全部" ? self._displayDataBase : self._displayDataBase.filter({ data in
            
            switch type{
            case "大功":
                return data.MA > 0
            case "小功":
                return data.MB > 0
            case "嘉獎":
                return data.MC > 0
            case "大過":
                return data.DA > 0
            case "小過":
                return data.DB > 0
            case "警告":
                return data.DC > 0
            default:
                return false
            }
        })
        
        self.noDataLabel.hidden = self._displayData.count > 0
        
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segment.removeAllSegments()
        segment.translatesAutoresizingMaskIntoConstraints = true
        
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
            
            //CommonConnect(self.StudentData.DSNS, self._con, self)
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
        
        newData.sortInPlace{$0.Date > $1.Date}
        
        //        let sumMItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "獎勵總計", IsClear: false, MA: ma, MB: mb, MC: mc, DA: 0, DB: 0, DC: 0)
        //        let maItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "大功", IsClear: false, MA: ma, MB: 0, MC: 0, DA: 0, DB: 0, DC: 0)
        //        let mbItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "小功", IsClear: false, MA: 0, MB: mb, MC: 0, DA: 0, DB: 0, DC: 0)
        //        let mcItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "嘉獎", IsClear: false, MA: 0, MB: 0, MC: mc, DA: 0, DB: 0, DC: 0)
        //
        //        let sumDItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "懲戒總計", IsClear: false, MA: 0, MB: 0, MC: 0, DA: da, DB: db, DC: dc)
        //        let daItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "大過", IsClear: false, MA: 0, MB: 0, MC: 0, DA: da, DB: 0, DC: 0)
        //        let dbItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "小過", IsClear: false, MA: 0, MB: 0, MC: 0, DA: 0, DB: db, DC: 0)
        //        let dcItem = DisciplineItem(Type: DisciplineType.Summary, Date: "", SchoolYear: "", Semester: "", Reason: "警告", IsClear: false, MA: 0, MB: 0, MC: 0, DA: 0, DB: 0, DC: dc)
        //
        //        newData.insert(dcItem, atIndex: 0)
        //        newData.insert(dbItem, atIndex: 0)
        //        newData.insert(daItem, atIndex: 0)
        //        newData.insert(sumDItem, atIndex: 0)
        //        newData.insert(mcItem, atIndex: 0)
        //        newData.insert(mbItem, atIndex: 0)
        //        newData.insert(maItem, atIndex: 0)
        //        newData.insert(sumMItem, atIndex: 0)
        
        segment.removeAllSegments()
        segment.insertSegmentWithTitle("警告(\(dc))", atIndex: 0, animated: false)
        segment.insertSegmentWithTitle("小過(\(db))", atIndex: 0, animated: false)
        segment.insertSegmentWithTitle("大過(\(da))", atIndex: 0, animated: false)
        segment.insertSegmentWithTitle("嘉獎(\(mc))", atIndex: 0, animated: false)
        segment.insertSegmentWithTitle("小功(\(mb))", atIndex: 0, animated: false)
        segment.insertSegmentWithTitle("大功(\(ma))", atIndex: 0, animated: false)
        segment.insertSegmentWithTitle("全部(\(dc + db + da + mc + mb + ma))", atIndex: 0, animated: true)
        
        _SegmentItems.removeAll(keepCapacity: false)
        _SegmentItems.insert("警告", atIndex: 0)
        _SegmentItems.insert("小過", atIndex: 0)
        _SegmentItems.insert("大過", atIndex: 0)
        _SegmentItems.insert("嘉獎", atIndex: 0)
        _SegmentItems.insert("小功", atIndex: 0)
        _SegmentItems.insert("大功", atIndex: 0)
        _SegmentItems.insert("全部", atIndex: 0)
        
        var besSize = segment.sizeThatFits(CGSize.zero)
        
        let screenwidth = scrollView.frame.width
        
        if besSize.width < screenwidth - 16 {
            besSize.width = screenwidth - 16
        }
        
        segment.frame.size.width = besSize.width
        
        if besSize.width > screenwidth{
            scrollView.contentSize = CGSizeMake(besSize.width + 16 , 0)
        }
        else{
            scrollView.contentSize = CGSizeMake(besSize.width , 0)
        }
        
        scrollView.contentOffset = CGPointMake(0 - self.scrollView.contentInset.left, 0)
        
        _displayDataBase = newData
        
        if _SegmentItems.count > 0{
            segment.selectedSegmentIndex = 0
            SegmentSelect(self)
        }
    }
    
    func GetDisciplineData() -> [DisciplineItem]{
        
        var err : DSFault!
        var nserr : NSError?
        
        var retVal = [DisciplineItem]()
        
        var rsp = _con.SendRequest("discipline.GetStudentDiscipline", bodyContent: "<Request><RefStudentId>\(StudentData.ID)</RefStudentId></Request>", &err)
        
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
        
        if let disciplines = xml?.root["Response"]["Discipline"].all {
            for discipline in disciplines{
                let occurDate = discipline.attributes["OccurDate"]
                let schoolYear = discipline.attributes["SchoolYear"]
                let semester = discipline.attributes["Semester"]
                let meritFlag = discipline.attributes["MeritFlag"] == "1" ? DisciplineType.Merit : DisciplineType.Demerit
                let reason = discipline["Reason"].stringValue
                
                var ma = 0
                var mb = 0
                var mc = 0
                var da = 0
                var db = 0
                var dc = 0
                var isClear = false
                
                if meritFlag == DisciplineType.Merit{
                    ma = (discipline["Merit"].attributes["A"]?.intValue)!
                    mb = (discipline["Merit"].attributes["B"]?.intValue)!
                    mc = (discipline["Merit"].attributes["C"]?.intValue)!
                }
                else{
                    da = (discipline["Demerit"].attributes["A"]?.intValue)!
                    db = (discipline["Demerit"].attributes["B"]?.intValue)!
                    dc = (discipline["Demerit"].attributes["C"]?.intValue)!
                    isClear = discipline["Demerit"].attributes["Cleared"] == "是"
                }
                
                let item = DisciplineItem(Type: meritFlag, Date: occurDate!, SchoolYear: schoolYear!, Semester: semester!, Reason: reason, IsClear: isClear, MA: ma, MB: mb, MC: mc, DA: da, DB: db, DC: dc)
                
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
            var cell = tableView.dequeueReusableCellWithIdentifier("summaryItem")
            
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

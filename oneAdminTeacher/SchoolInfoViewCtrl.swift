//
//  SchoolInfoViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 9/15/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class SchoolInfoViewCtrl: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var progressTimer : ProgressTimer!
    
    var _DisplayItems = [DisplayItem]()
    
    var _currentSchoolYear : String!
    var _currentSemester : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressTimer = ProgressTimer(progressBar: progressBar)
        
        self.navigationItem.title = "學校資訊"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Menu 2-26.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ClickMenu")
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Menu-24.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ToggleSideMenu")
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if Global.MySchoolList.count > 0{
            GetData(Global.MySchoolList[0])
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func ClickMenu(){
        
        let select = UIAlertController(title: "請選擇一所學校", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        select.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        select.addAction(UIAlertAction(title: "新增學校", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("AddSchoolViewCtrl") as! AddSchoolViewCtrl
            self.navigationController?.pushViewController(nextView, animated: true)
        }))
        
        for dsns in Global.MySchoolList{
            
            select.addAction(UIAlertAction(title: dsns.Name, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                
                self.GetData(dsns)
            }))
            
        }
        
        self.presentViewController(select, animated: true, completion: nil)
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _DisplayItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let data = _DisplayItems[indexPath.row]
        
        let cell = GetCell(data)
        
        cell.textLabel?.text = data.Title
        cell.detailTextLabel?.text = data.Value
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let data = _DisplayItems[indexPath.row]
        
        switch data.OtherInfo{
            
        case "address" :
            
            let alert = UIAlertController(title: "繼續？", message: "即將開啟Apple map", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (okaction) -> Void in
                GoogleMap(data.Value)
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            break
            
        case "phoneNumber" :
            DialNumber(data.Value)
            break
            
        case "email" :
            
            let alert = UIAlertController(title: "繼續？", message: "即將進行電子郵件編輯", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (okaction) -> Void in
                SendEmail(data.Value)
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            break
            
        default:
            break
        }
    }
    
    func GetCell(data:DisplayItem) -> UITableViewCell{
        
        var cell:UITableViewCell?
        
        if data.OtherInfo == "header"{
            cell = self.tableView.dequeueReusableCellWithIdentifier("schoolheader")
        }
        else{
            cell = self.tableView.dequeueReusableCellWithIdentifier("schoolinfo")
        }
        
        if cell == nil{
            
            if data.OtherInfo == "header"{
                cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "schoolheader")
                cell?.backgroundColor = UIColor(red: 219 / 255, green: 228 / 255, blue: 238 / 255, alpha: 1)
                cell?.textLabel?.font = UIFont.boldSystemFontOfSize(18)
            }
            else{
                cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "schoolinfo")
                cell?.detailTextLabel?.numberOfLines = 0
            }
            
        }
        
        return cell!
    }
    
    func GetData(dsns:DsnsItem){
        
        self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top)
        
        progressTimer.StartProgress()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            
            var tmpData = [DisplayItem]()
            
            tmpData.append(DisplayItem(Title: dsns.Name, Value: "", OtherInfo: "header"))
            
            tmpData += self.GetSchoolYearAndSemester(dsns)
            tmpData += self.GetSchoolInfo(dsns)
            tmpData += self.GetSchoolStatistic(dsns)
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.progressTimer.StopProgress()
                
                self._DisplayItems = tmpData
                
                self.tableView.reloadData()
                
            })
        })
        
    }
    
    func GetSchoolYearAndSemester(dsns:DsnsItem) -> [DisplayItem]{
        
        var retVal = [DisplayItem]()
        
        let con = GetCommonConnect(dsns.AccessPoint)
        var err : DSFault!
        
        let rsp = con.SendRequest("main.GetCurrentSemester", bodyContent: "", &err)
        
        var nerror : NSError?
        var xml: AEXMLDocument?
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        
        if let schoolYear = xml?.root["Response"]["SchoolYear"].stringValue{
            _currentSchoolYear = schoolYear
            retVal.append(DisplayItem(Title: "當前學年度", Value: schoolYear, OtherInfo: ""))
        }
        
        if let semester = xml?.root["Response"]["Semester"].stringValue{
            _currentSemester = semester
            retVal.append(DisplayItem(Title: "當前學期", Value: semester, OtherInfo: ""))
        }
        
        return retVal
    }
    
    func GetSchoolInfo(dsns:DsnsItem) -> [DisplayItem]{
        
        var retVal = [DisplayItem]()
        
        let con = GetCommonConnect(dsns.AccessPoint)
        var err : DSFault!
        
        let rsp = con.SendRequest("main.GetSchoolInfo", bodyContent: "", &err)
        
        var nerror : NSError?
        var xml: AEXMLDocument?
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        
        //基本資料
        if let address = xml?.root["Response"]["Address"].stringValue{
            retVal.append(DisplayItem(Title: "學校地址", Value: address, OtherInfo: "address"))
        }
        
        if let code = xml?.root["Response"]["Code"].stringValue{
            retVal.append(DisplayItem(Title: "學校代碼", Value: code, OtherInfo: ""))
        }
        
        if let fax = xml?.root["Response"]["Fax"].stringValue{
            retVal.append(DisplayItem(Title: "傳真號碼", Value: fax, OtherInfo: "phoneNumber"))
        }
        
        if let telephone = xml?.root["Response"]["Telephone"].stringValue{
            retVal.append(DisplayItem(Title: "聯絡電話", Value: telephone, OtherInfo: "phoneNumber"))
        }
        
        //校長
        retVal.append(DisplayItem(Title: "校長", Value: "", OtherInfo: "header"))
        
        if let chancellorChineseName = xml?.root["Response"]["ChancellorChineseName"].stringValue{
            retVal.append(DisplayItem(Title: "中文姓名", Value: chancellorChineseName, OtherInfo: ""))
        }
        
        if let chancellorEnglishName = xml?.root["Response"]["ChancellorEnglishName"].stringValue{
            retVal.append(DisplayItem(Title: "英文姓名", Value: chancellorEnglishName, OtherInfo: ""))
        }
        
        if let chancellorCellPhone = xml?.root["Response"]["ChancellorCellPhone"].stringValue{
            retVal.append(DisplayItem(Title: "手機號碼", Value: chancellorCellPhone, OtherInfo: "phoneNumber"))
        }
        
        if let chancellorEmail = xml?.root["Response"]["ChancellorEmail"].stringValue{
            retVal.append(DisplayItem(Title: "電子郵件", Value: chancellorEmail, OtherInfo: "email"))
        }
        
        //教務主任
        retVal.append(DisplayItem(Title: "教務主任", Value: "", OtherInfo: "header"))
        
        if let eduDirectorName = xml?.root["Response"]["EduDirectorName"].stringValue{
            retVal.append(DisplayItem(Title: "中文姓名", Value: eduDirectorName, OtherInfo: ""))
        }
        
        if let eduDirectorCellPhone = xml?.root["Response"]["EduDirectorCellPhone"].stringValue{
            retVal.append(DisplayItem(Title: "手機號碼", Value: eduDirectorCellPhone, OtherInfo: "phoneNumber"))
        }
        
        if let eduDirectorEmail = xml?.root["Response"]["EduDirectorEmail"].stringValue{
            retVal.append(DisplayItem(Title: "電子郵件", Value: eduDirectorEmail, OtherInfo: "email"))
        }
        
        //學務主任
        retVal.append(DisplayItem(Title: "學務主任", Value: "", OtherInfo: "header"))
        
        if let stuDirectorName = xml?.root["Response"]["StuDirectorName"].stringValue{
            retVal.append(DisplayItem(Title: "中文姓名", Value: stuDirectorName, OtherInfo: ""))
        }
        
        if let stuDirectorCellPhone = xml?.root["Response"]["StuDirectorCellPhone"].stringValue{
            retVal.append(DisplayItem(Title: "手機號碼", Value: stuDirectorCellPhone, OtherInfo: "phoneNumber"))
        }
        
        if let stuDirectorEmail = xml?.root["Response"]["StuDirectorEmail"].stringValue{
            retVal.append(DisplayItem(Title: "電子郵件", Value: stuDirectorEmail, OtherInfo: "email"))
        }
        
        //資訊聯繫人
        retVal.append(DisplayItem(Title: "資訊聯繫人", Value: "", OtherInfo: "header"))
        
        if let associatedWithName = xml?.root["Response"]["AssociatedWithName"].stringValue{
            retVal.append(DisplayItem(Title: "中文姓名", Value: associatedWithName, OtherInfo: ""))
        }
        
        if let associatedWithCellPhone = xml?.root["Response"]["AssociatedWithCellPhone"].stringValue{
            retVal.append(DisplayItem(Title: "手機號碼", Value: associatedWithCellPhone, OtherInfo: "phoneNumber"))
        }
        
        if let associatedWithEmail = xml?.root["Response"]["AssociatedWithEmail"].stringValue{
            retVal.append(DisplayItem(Title: "電子郵件", Value: associatedWithEmail, OtherInfo: "email"))
        }
        
        //其他
        if let otherTitle = xml?.root["Response"]["OtherTitle"].stringValue where !otherTitle.isEmpty{
            retVal.append(DisplayItem(Title: otherTitle, Value: "", OtherInfo: "header"))
            
            if let otherName = xml?.root["Response"]["OtherName"].stringValue{
                retVal.append(DisplayItem(Title: "中文姓名", Value: otherName, OtherInfo: ""))
            }
            
            if let otherCellPhone = xml?.root["Response"]["OtherCellPhone"].stringValue{
                retVal.append(DisplayItem(Title: "手機號碼", Value: otherCellPhone, OtherInfo: "phoneNumber"))
            }
            
            if let otherEmail = xml?.root["Response"]["OtherEmail"].stringValue{
                retVal.append(DisplayItem(Title: "電子郵件", Value: otherEmail, OtherInfo: "email"))
            }
        }
        
        return retVal
    }
    
    func GetSchoolStatistic(dsns:DsnsItem) -> [DisplayItem]{
        
        var retVal = [DisplayItem]()
        
        let con = GetCommonConnect(dsns.AccessPoint)
        var err : DSFault!
        
        let rsp = con.SendRequest("main.GetSchoolStatistic", bodyContent: "<Request><All></All><SchoolYear>\(_currentSchoolYear)</SchoolYear><Semester>\(_currentSemester)</Semester></Request>", &err)
        
        var nerror : NSError?
        var xml: AEXMLDocument?
        do {
            xml = try AEXMLDocument(xmlData: rsp.dataValue)
        } catch _ {
            xml = nil
        }
        
        if let statistics = xml?.root["InfoList"]["Statistic"].all{
            for statistic in statistics{
                
                let type = statistic["Type"].stringValue
                let title = statistic["Title"].stringValue
                let count = statistic["Count"].stringValue
                
                retVal.append(DisplayItem(Title: title, Value: count, OtherInfo: ""))
            }
        }
        
        if retVal.count > 0{
            retVal.insert(DisplayItem(Title: "數據統計", Value: "", OtherInfo: "header"), atIndex: 0)
        }
        
        return retVal
    }
    
    func ToggleSideMenu(){
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        
        app.centerContainer?.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
    
    
}


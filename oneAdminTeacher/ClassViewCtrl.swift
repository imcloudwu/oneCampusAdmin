//
//  ClassViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/10/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//


import UIKit

class ClassViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    //var progressTimer : ProgressTimer!
    var refreshControl : UIRefreshControl!
    
    var _ClassList = [ClassItem]()
    var _DisplayDatas = [ClassItem]()
    var _CurrentDatas = [ClassItem]()
    
    
    var DsnsResult = [String:Bool]()
    
    let redColor = UIColor(red: 244 / 255, green: 67 / 255, blue: 54 / 255, alpha: 1)
    let blueColor = UIColor(red: 33 / 255, green: 150 / 255, blue: 243 / 255, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
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
            _DisplayDatas = _ClassList
            _CurrentDatas = _DisplayDatas
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
        
        if Global.MySchoolList.count > 1 {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "快速切換", style: UIBarButtonItemStyle.Done, target: self, action: "FastSwitch")
        }
        else{
            self.navigationItem.rightBarButtonItem = nil
        }
        
    }
    
    func FastSwitch(){
        let switcher = UIAlertController(title: "快速切換", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        switcher.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        switcher.addAction(UIAlertAction(title: "列出全部", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self._DisplayDatas = self._ClassList
            self._CurrentDatas = self._DisplayDatas
            
            self.tableView.reloadData()
        }))
        
        for ds in Global.MySchoolList{
            
            switcher.addAction(UIAlertAction(title: ds.Name, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                
                let founds = self._ClassList.filter({ cls in
                    
                    if cls.DSNS == ds.AccessPoint{
                        return true
                    }
                    
                    return false
                })
                
                self._DisplayDatas = founds
                self._CurrentDatas = self._DisplayDatas
                
                self.tableView.reloadData()
            }))
        }
        
        self.presentViewController(switcher, animated: true, completion: nil)
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
                    
                    self._DisplayDatas = self._ClassList
                    self._CurrentDatas = self._DisplayDatas
                    self.tableView.reloadData()
                })
            })
        }
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
                let TeacherAccount = cls["TeacherAccount"].stringValue
                
                retVal.append(ClassItem(DSNS : con.accessPoint, ID: ClassID, ClassName: ClassName, AccessPoint: con.accessPoint, GradeYear: GradeYear, TeacherName: TeacherName, TeacherAccount : TeacherAccount))
            }
        }
        
        if retVal.count > 0{
            
            let schoolName = GetSchoolName(con)
            GetAllTeacherAccount(schoolName, con)
            
            retVal.insert(ClassItem(DSNS : con.accessPoint, ID: "header", ClassName: schoolName, AccessPoint: "", GradeYear: 0, TeacherName: "", TeacherAccount : ""), atIndex: 0)
        }
        
        return retVal
    }
    
    func AllDone() -> Bool{
        
        for dsns in DsnsResult{
            if !dsns.1{
                return false
            }
        }
        
        return true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _DisplayDatas.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let data = _DisplayDatas[indexPath.row]
        
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
        cell.Major.text = data.TeacherName
        cell.classItem = data
        
        //字串擷取
        if (data.ClassName as NSString).length > 0{
            let subString = (data.ClassName as NSString).substringToIndex(1)
            cell.ClassIcon.text = subString
        }
        else{
            cell.ClassIcon.text = ""
        }
        
        //UILongPressGestureRecognizer
        var longPress = UILongPressGestureRecognizer(target: self, action: "LongPress:")
        longPress.minimumPressDuration = 0.5
        
        cell.addGestureRecognizer(longPress)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let data = _DisplayDatas[indexPath.row]
        
        if data.ID != "header"{
            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("StudentViewCtrl") as! StudentViewCtrl
            nextView.ClassData = data
            self.navigationController?.pushViewController(nextView, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        if _DisplayDatas[indexPath.row].ID == "header"{
            return 30
        }
        
        return 60
    }
    
    func LongPress(sender:UILongPressGestureRecognizer){
        
        if sender.state == UIGestureRecognizerState.Began{
            var cell = sender.view as! ClassCell
            
            let menu = UIAlertController(title: "要對 \(cell.ClassName.text!) 發送訊息嗎?", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            menu.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
            
            menu.addAction(UIAlertAction(title: "給班導師", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                
                self.SendMessageToClassTeacher(cell)
            }))
            
            menu.addAction(UIAlertAction(title: "給家長們", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                
                self.SendMessageToClassParents(cell)
            }))
            
            self.presentViewController(menu, animated: true, completion: nil)
            
        }
    }
    
    func SendMessageToClassTeacher(cell : ClassCell){
        
        if let ta = GetTeacherAccountItem(cell.classItem.TeacherAccount){
            
            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("OutboxSendViewCtrl") as! OutboxSendViewCtrl
            nextView.MyTeacherSelector.Teachers.append(ta)
            
            self.navigationController?.pushViewController(nextView, animated: true)
        }
        else{
            ShowErrorAlert(self, "錯誤", "找不到此班導師的帳號")
        }
        
    }
    
    func SendMessageToClassParents(cell : ClassCell){
        
        var err : DSFault!
        let con = GetCommonConnect(cell.classItem.DSNS)
        
        var rsp = con.sendRequest("main.GetParent", bodyContent: "<Request><ClassID>\(cell.classItem.ID)</ClassID></Request>", &err)
        
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
            
            //發送訊息前會做了
            //SetTeachersUUID(parentAccounts)
            
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
        
        Search(searchBar.text)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        Search(searchText)
    }
    
    func Search(searchText:String){
        
        if searchText == "" {
            self._DisplayDatas = self._CurrentDatas
        }
        else{
            
            let founds = self._CurrentDatas.filter({ cls in
                
                if let x = cls.ClassName.lowercaseString.rangeOfString(searchText.lowercaseString){
                    return true
                }
                
                if let y = cls.TeacherName.lowercaseString.rangeOfString(searchText.lowercaseString){
                    return true
                }
                
                return false
            })
            
            self._DisplayDatas = founds
        }
        
        self.tableView.reloadData()
        
    }
}

struct ClassItem{
    var DSNS : String
    var ID : String
    var ClassName : String
    var AccessPoint : String
    var GradeYear : Int
    var TeacherName : String
    var TeacherAccount : String
}

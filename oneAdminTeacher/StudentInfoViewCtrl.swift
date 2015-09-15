//
//  StudentInfoViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 6/29/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class StudentInfoViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,ContainerViewProtocol {
    
    var StudentData:Student!
    var ParentNavigationItem : UINavigationItem?
    var AddBtn : UIBarButtonItem!
    
    var _displayData = [DisplayItem]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //self.automaticallyAdjustsScrollViewInsets = true
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "加入清單", style: UIBarButtonItemStyle.Plain, target: self, action: "AddToList")
        AddBtn = UIBarButtonItem(image: UIImage(named: "Add User-25.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "AddToList")
        //ParentNavigationItem?.rightBarButtonItems?.append(AddBtn)
        
        _displayData.append(DisplayItem(Title: "性別", Value: StudentData.Gender, OtherInfo: "", ColorAlarm: false))
        _displayData.append(DisplayItem(Title: "監護人", Value: StudentData.CustodianName, OtherInfo: "", ColorAlarm: false))
        _displayData.append(DisplayItem(Title: "父親姓名", Value: StudentData.FatherName, OtherInfo: "", ColorAlarm: false))
        _displayData.append(DisplayItem(Title: "母親姓名", Value: StudentData.MotherName, OtherInfo: "", ColorAlarm: false))
        _displayData.append(DisplayItem(Title: "戶籍電話", Value: StudentData.PermanentPhone, OtherInfo: "phoneNumber", ColorAlarm: false))
        _displayData.append(DisplayItem(Title: "聯絡電話", Value: StudentData.ContactPhone, OtherInfo: "phoneNumber", ColorAlarm: false))
        _displayData.append(DisplayItem(Title: "戶籍地址", Value: GetAddress(StudentData.PermanentAddress), OtherInfo: "address", ColorAlarm: false))
        _displayData.append(DisplayItem(Title: "郵遞地址", Value: GetAddress(StudentData.MailingAddress), OtherInfo: "address", ColorAlarm: false))
        
//        StudentNumber.text = StudentData.StudentNumber
//        Gender.text = StudentData.Gender
//        CustodianName.text = StudentData.CustodianName
//        MailingAddress.text = GetAddress(StudentData.MailingAddress)
//        PermanentAddress.text = GetAddress(StudentData.PermanentAddress)
//        FatherName.text = StudentData.FatherName
//        FatherPhone.text = StudentData.PermanentPhone
//        MotherName.text = StudentData.MotherName
//        MotherPhone.text = StudentData.ContactPhone
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        LockBtnEnableCheck()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _displayData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let data = _displayData[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("StudentBasicInfoCell") as! StudentBasicInfoCell
        
        cell.Title.text = data.Title
        cell.Value.text = data.Value
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let data = _displayData[indexPath.row]
        
        if data.OtherInfo == "phoneNumber"{
            DialNumber(data.Value)
        }
        
        if data.OtherInfo == "address"{
            
            let alert = UIAlertController(title: "繼續？", message: "即將開啟Apple map", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (okaction) -> Void in
                GoogleMap(data.Value)
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func AddToList(){
        Global.Students.append(StudentData)
        LockBtnEnableCheck()
        
        //存入catch
        StudentCoreData.SaveCatchData(StudentData)
    }
    
    func GetAddress(xmlString:String) -> String{
        var nserr : NSError?
        let xml = AEXMLDocument(xmlData: xmlString.dataValue, error: &nserr)
        
        var retVal = ""
        
        if let addresses = xml?.root["AddressList"]["Address"].all{
            for address in addresses{
                
                let zipCode = address["ZipCode"].stringValue == "" ? "" : "[" + address["ZipCode"].stringValue + "]"
                let county = address["County"].stringValue
                let town = address["Town"].stringValue
                let detailAddress = address["DetailAddress"].stringValue
                
                retVal = zipCode + county + town + detailAddress
                
                if retVal != ""{
                    return retVal
                }
            }
        }
        
        return "查無地址資料"
    }
    
    func LockBtnEnableCheck(){
        if contains(Global.Students, StudentData){
            AddBtn.enabled = false
        }
        else{
            AddBtn.enabled = true
        }
    }
}

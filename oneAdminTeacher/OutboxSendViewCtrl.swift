//
//  OutboxSendViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 8/3/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class OutboxSendViewCtrl: UIViewController,UITextFieldDelegate,UITextViewDelegate {
    
    @IBOutlet weak var SchoolName: UITextField!
    @IBOutlet weak var Organize: UITextField!
    @IBOutlet weak var ContentFrame: UIView!
    @IBOutlet weak var Content: UITextView!
    @IBOutlet weak var Receiver: UILabel!
    @IBOutlet weak var Redirect: UITextField!
    
    @IBOutlet weak var ContentBottomCS: NSLayoutConstraint!
    
    var MyTeacherSelector = TeacherSelector()
    var MyOptions = OptionCollection()
    
    let placeTitle = "訊息內容..."
    
    var KeyBoardHeight : CGFloat = 0
    
    var DataBase : [TeacherAccount]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SchoolName.delegate = self
        Organize.delegate = self
        Redirect.delegate = self
        Content.delegate = self
        
        let sendBtn = UIBarButtonItem(title: "發送", style: UIBarButtonItemStyle.Done, target: self, action: "Send")
        let settingBtn = UIBarButtonItem(title: "問卷設定", style: UIBarButtonItemStyle.Done, target: self, action: "Setting")
        
        self.navigationItem.rightBarButtonItems = [settingBtn,sendBtn]
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "發送", style: UIBarButtonItemStyle.Done, target: self, action: "Send")
        //self.navigationItem.rightBarButtonItems?.append(UIBarButtonItem(title: "進階設定", style: UIBarButtonItemStyle.Done, target: self, action: ""))
        
//        ContentFrame.layer.shadowColor = UIColor.blackColor().CGColor
//        ContentFrame.layer.shadowOffset = CGSizeMake(3, 3)
//        ContentFrame.layer.shadowOpacity = 0.5
//        ContentFrame.layer.shadowRadius = 5
        
        //Receiver.text = "imcloudwu@gmail.com"
        
        if let schoolName = Keychain.load("schoolName")?.stringValue{
            SchoolName.text = schoolName
        }
            
        if SchoolName.text!.isEmpty{
            SchoolName.text = Global.MySchoolList.count > 0 ? Global.MySchoolList[0].Name : ""
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "SelectTeacher")
        Receiver.addGestureRecognizer(tapGesture)
        
        let receiversPress = UILongPressGestureRecognizer(target: self, action: "ClearReceivers")
        receiversPress.minimumPressDuration = 1.0
        Receiver.addGestureRecognizer(receiversPress)
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        RegisterForKeyboardNotifications(self)
        SetReceiverText()
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func SelectTeacher(){
        
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("SelectTeacherPageViewCtrl") as! SelectTeacherPageViewCtrl
        nextView.ParentTeacherSelector = MyTeacherSelector
        
        nextView.DataBase = DataBase == nil ? Global.MyTeacherList : DataBase
        
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
    func ClearReceivers(){
        MyTeacherSelector.Teachers.removeAll(keepCapacity: false)
        SetReceiverText()
    }
    
    func SetReceiverText(){
        let receiver = MyTeacherSelector.GetString()
        Receiver.text = receiver == "" ? "點擊加入" : receiver
    }
    
    func Send(){
        
        let schoolName = SchoolName.text
        let sender = Organize.text
        let receivers = MyTeacherSelector.GetReceivers()
        let message = Content.text == placeTitle ? "" : Content.text
        
        let redirect = Redirect.text
        
        Keychain.save("schoolName", data: schoolName!.dataValue)
        
        var options = [String]()
        
        for item in MyOptions.Items{
            
            if item.Value != ""{
                options.append(item.Value)
            }
        }
        
        if options.count >= 2{
            
            let alert = UIAlertController(title: "此訊息有\(options.count)筆問卷選項,請決定單選或複選?", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
            
            alert.addAction(UIAlertAction(title: "單選", style: UIAlertActionStyle.Default, handler: { (action1) -> Void in
                NotificationService.SendMessage(schoolName!, type: "single", sender: sender!, redirect: redirect!, msg: message, receivers: receivers, options: options, accessToken: Global.AccessToken)
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
            
            alert.addAction(UIAlertAction(title: "複選", style: UIAlertActionStyle.Default, handler: { (action2) -> Void in
                NotificationService.SendMessage(schoolName!, type: "multiple", sender: sender!, redirect: redirect!, msg: message, receivers: receivers, options: options, accessToken: Global.AccessToken)
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        else{
            NotificationService.SendMessage(schoolName!, type: "normal", sender: sender!, redirect: redirect!, msg: message, receivers: receivers, options: [String](), accessToken: Global.AccessToken)
            
            self.navigationController?.popViewControllerAnimated(true)
        }
        
    }
    
    func Setting(){
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("OptionSettingViewCtrl") as! OptionSettingViewCtrl
        nextView.Options = MyOptions
        
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
    func textViewDidBeginEditing(textView: UITextView){
        if textView.text == placeTitle {
            textView.textColor = UIColor.blackColor()
            textView.text = ""
        }
        
        ContentBottomCS.constant = KeyBoardHeight + 10
        
        //textView.frame.size.height = 100
    }
    
    func textViewDidEndEditing(textView: UITextView){
        if textView.text.isEmpty {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = placeTitle
        }
        
        ContentBottomCS.constant = 0
        
        //textView.frame.size.height = 400
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        
        if textField == SchoolName{
            
            let autoComplete = UIAlertController(title: "要自動填入學校名稱嗎?", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            autoComplete.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
            
            for sn in Global.MySchoolList{
                
                autoComplete.addAction(UIAlertAction(title: sn.Name, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    self.SchoolName.text = sn.Name
                }))
            }
            
            self.presentViewController(autoComplete, animated: true, completion: nil)
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Called when the UIKeyboardDidShowNotification is sent.
    func keyboardWillBeShown(sender: NSNotification) {
        let info: NSDictionary = sender.userInfo!
        let value: NSValue = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
        let keyboardSize: CGSize = value.CGRectValue().size
        
        KeyBoardHeight = keyboardSize.height
    }
    
    
}

class TeacherSelector{
    
    var Teachers = [TeacherAccount]()
    
    func GetReceivers() -> [TeacherAccount]{
        
        let tmp = Teachers.filter { (t) -> Bool in
            return t.UUID.isEmpty
        }
        
        if tmp.count > 0 {
            SetTeachersUUID(tmp)
        }
        
        let retVal = Teachers.filter { (t) -> Bool in
            return !t.UUID.isEmpty
        }
        
        return retVal
    }
    
    func IndexOf(teacher:TeacherAccount) -> Int{
        
        var index = 0
        
        for t in Teachers{
            if t == teacher{
                return index
            }
            
            index++
        }
        
        return -1
    }
    
    func GetString() -> String{
        
        var retVal = ""
        
        var count = 0
        let limit = 3
        
        for t in Teachers{
            count++
            
            if count <= limit {
                if t == Teachers.last{
                    retVal += t.Name
                }
                else{
                    retVal += t.Name + ","
                }
            }
        }
        
        if count > limit{
            retVal += "...等 \(count) 人"
        }
        
        return retVal
    }
}
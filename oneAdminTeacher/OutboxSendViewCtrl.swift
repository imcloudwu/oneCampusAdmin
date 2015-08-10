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
    
    var MyTeacherSelector = TeacherSelector()
    
    let placeTitle = "訊息內容..."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SchoolName.delegate = self
        Organize.delegate = self
        Content.delegate = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "發送", style: UIBarButtonItemStyle.Done, target: self, action: "Send")
        
//        ContentFrame.layer.shadowColor = UIColor.blackColor().CGColor
//        ContentFrame.layer.shadowOffset = CGSizeMake(3, 3)
//        ContentFrame.layer.shadowOpacity = 0.5
//        ContentFrame.layer.shadowRadius = 5
        
        //Receiver.text = "imcloudwu@gmail.com"
        
        if let schoolName = Keychain.load("schoolName")?.stringValue{
            SchoolName.text = schoolName
        }
            
        if SchoolName.text.isEmpty{
            SchoolName.text = Global.MySchoolList.count > 0 ? Global.MySchoolList[0] : ""
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "SelectTeacher")
        Receiver.addGestureRecognizer(tapGesture)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "ClearReceivers")
        longPress.minimumPressDuration = 1.0
        Receiver.addGestureRecognizer(longPress)
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        SetReceiverText()
    }
    
    func SelectTeacher(){
        
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("SelectTeacherPageViewCtrl") as! SelectTeacherPageViewCtrl
        nextView.ParentTeacherSelector = MyTeacherSelector
        
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
        
        Keychain.save("schoolName", data: schoolName.dataValue)
        
        NotificationService.SendMessage(schoolName, sender: sender, msg: message, receivers: receivers, accessToken: Global.AccessToken)
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func textViewDidBeginEditing(textView: UITextView){
        if textView.text == placeTitle {
            textView.textColor = UIColor.blackColor()
            textView.text = ""
        }
    }
    
    func textViewDidEndEditing(textView: UITextView){
        if textView.text.isEmpty {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = placeTitle
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
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
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
}

class TeacherSelector{
    
    var Teachers = [TeacherAccount]()
    
    func GetReceivers() -> [TeacherAccount]{
        
        var retVal = [TeacherAccount]()
        
        for teacher in Teachers{
            if teacher.UUID != ""{
                retVal.append(teacher)
            }
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
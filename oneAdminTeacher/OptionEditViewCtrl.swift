//
//  OptionEditViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 8/11/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class OptionEditViewCtrl: UIViewController,UITextViewDelegate {
    
    @IBOutlet weak var Content: UITextView!
    @IBOutlet weak var BottomCS: NSLayoutConstraint!
    
    var KeyBoardHeight : CGFloat = 0
    var placeTitle = "請輸入選項內容..."
    
    var Option : OptionItem!
    
    var tmpOption = OptionItem("")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tmpOption.Value = Option.Value
        
        Content.delegate = self
        
        Content.text = tmpOption.Value
        
        if Content.text.isEmpty {
            Content.textColor = UIColor.lightGrayColor()
            Content.text = placeTitle
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "Save")
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        RegisterForKeyboardNotifications(self)
        Content.becomeFirstResponder()
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func Save(){
        Option.Value = Content.text == placeTitle ? "" : Content.text
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func textViewDidBeginEditing(textView: UITextView){
        if Content.text == placeTitle {
            Content.textColor = UIColor.blackColor()
            Content.text = ""
        }
        
        BottomCS.constant = KeyBoardHeight + 10
        
        //textView.frame.size.height = 100
    }
    
    func textViewDidEndEditing(textView: UITextView){
        if Content.text.isEmpty {
            Content.textColor = UIColor.lightGrayColor()
            Content.text = placeTitle
        }
        
        BottomCS.constant = 0
        
        //textView.frame.size.height = 400
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    // Called when the UIKeyboardDidShowNotification is sent.
    func keyboardWillBeShown(sender: NSNotification) {
        let info: NSDictionary = sender.userInfo!
        let value: NSValue = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
        let keyboardSize: CGSize = value.CGRectValue().size
        
        KeyBoardHeight = keyboardSize.height
    }
    
    
}

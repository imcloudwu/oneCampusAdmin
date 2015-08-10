//
//  MessageDetailViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/22/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class MessageDetailViewCtrl: UIViewController {
    
    var MessageData : MessageItem!
    var SenderMode = false
    
    @IBOutlet weak var DsnsName: UILabel!
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var HyperLinkView: UIView!
    @IBOutlet weak var HyperLink: UILabel!
    @IBOutlet weak var Content: UITextView!
    @IBOutlet weak var HyperLinkViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var ContentBoardView: UIView!
    
    @IBOutlet weak var SenderLabel: UILabel!
    @IBOutlet weak var SenderLabelHeight: NSLayoutConstraint!
    
    var ReadersCatch = [String:String]()
    var ReadList = [String]()
    
    var _dateFormate = NSDateFormatter()
    var _timeFormate = NSDateFormatter()
    
    var _today : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //設為已讀
        NotificationService.SetRead(MessageData.Id, accessToken: Global.AccessToken)
        
        _dateFormate.dateFormat = "yyyy/MM/dd"
        _timeFormate.dateFormat = "HH:mm"
        
        _today = _dateFormate.stringFromDate(NSDate())
        
        let date = _dateFormate.stringFromDate(MessageData.Date)
        
        HyperLink.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "OpenUrl"))
        SenderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "WatchReaderList"))
        
        //self.automaticallyAdjustsScrollViewInsets = false
        
        //self.navigationController?.navigationBar.topItem?.title = MessageData.Title
        self.navigationItem.title = MessageData.Title
        
        ContentBoardView.layer.shadowColor = UIColor.blackColor().CGColor
        ContentBoardView.layer.shadowOffset = CGSizeZero
        ContentBoardView.layer.shadowOpacity = 0.5
        ContentBoardView.layer.shadowRadius = 5
        
        DsnsName.text = MessageData.DsnsName
        Name.text = MessageData.Name
        Date.text = _today == date ? _timeFormate.stringFromDate(MessageData.Date) : date
        HyperLink.text = MessageData.Redirect
        
        if MessageData.Redirect == ""{
            HyperLinkView.hidden = true
            HyperLinkViewHeight.constant = 0
        }
        
        if SenderMode{
            UpdateMessage()
        }
        else{
            SenderLabel.hidden = true
            SenderLabelHeight.constant = 0
        }
        
        Content.text = MessageData.Content
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        MessageCoreData.SaveCatchData(MessageData)
        
        Content.setContentOffset(CGPointMake(0, 0), animated: false)
    }
    
    func OpenUrl(){
        let alert = UIAlertController(title: "開啟附加連結", message: "您確定要開啟附加連結？開啟前請先確認該網址的安全性，避免損害您的裝置。", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Destructive){ (action) -> Void in
            let url:NSURL = NSURL(string:self.MessageData.Redirect)!
            UIApplication.sharedApplication().openURL(url)
        })
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func UpdateMessage(){
        
        var json = JSON(data: NotificationService.GetMessageById(MessageData.Id, accessToken: Global.AccessToken))
        
        let read = json["progress"]["read"].stringValue
        let total = json["progress"]["total"].stringValue
        
        for receiver in json["to"].arrayValue{
            let uuid = receiver["uuid"].stringValue
            let name = receiver["name"].stringValue
            
            ReadersCatch[uuid] = name
        }
        
        for reader in json["progress"]["readList"].arrayValue{
            ReadList.append(reader.stringValue)
        }
        
        SenderLabel.text = "已讀 ( \(read) / \(total) )"
    }
    
    func WatchReaderList(){
        
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("WatchReaderListViewCtrl") as! WatchReaderListViewCtrl
        nextView.ReadersCatch = ReadersCatch
        nextView.ReadList = ReadList
        
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
}

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
    
    @IBOutlet weak var MessageTitle: UILabel!
    
    @IBOutlet weak var DsnsName: UILabel!
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var HyperLinkView: UIView!
    @IBOutlet weak var HyperLink: UILabel!
    @IBOutlet weak var Content: UITextView!
    @IBOutlet weak var HyperLinkViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var StatusBtn: UIButton!
    @IBOutlet weak var StatusBtnHeight: NSLayoutConstraint!
    
    @IBOutlet weak var NameHeight: NSLayoutConstraint!
    
    @IBAction func StatusBtnClick(sender: AnyObject) {
        self.WatchReaderList()
    }
    
//    @IBOutlet weak var ContentBoardView: UIView!
//    
//    @IBOutlet weak var SenderLabel: UILabel!
//    @IBOutlet weak var SenderLabelHeight: NSLayoutConstraint!
    
    var ReadersCatch = [String:String]()
    var ReadList = [String]()
    
    var _dateFormate = NSDateFormatter()
    var _timeFormate = NSDateFormatter()
    
    var _today : String!
    
    var Options = [String]()
    
    var MustVote = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //設為已讀
        NotificationService.SetRead(MessageData.Id, accessToken: Global.AccessToken)
    
        if MessageData.Type != "normal"{
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Thumb Up Filled-25.png"), style: UIBarButtonItemStyle.Done, target: self, action: "Vote")
            
            GetMessageOptions()
        }
        
        _dateFormate.dateFormat = "yyyy/MM/dd"
        _timeFormate.dateFormat = "HH:mm"
        
        _today = _dateFormate.stringFromDate(NSDate())
        
        let date = _dateFormate.stringFromDate(MessageData.Date)
        
        HyperLink.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "OpenUrl"))
        //SenderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "WatchReaderList"))
        
        //self.automaticallyAdjustsScrollViewInsets = false
        
        //self.navigationController?.navigationBar.topItem?.title = MessageData.Title
        //self.navigationItem.title = MessageData.Title
        
        MessageTitle.text = MessageData.Title
        
//        ContentBoardView.layer.shadowColor = UIColor.blackColor().CGColor
//        ContentBoardView.layer.shadowOffset = CGSizeZero
//        ContentBoardView.layer.shadowOpacity = 0.5
//        ContentBoardView.layer.shadowRadius = 5
        
        DsnsName.text = MessageData.DsnsName
        Name.text = MessageData.Name
        Date.text = _today == date ? _timeFormate.stringFromDate(MessageData.Date) : date
        HyperLink.text = MessageData.Redirect
        
        if Name.text == ""{
            Name.hidden = true
            NameHeight.constant = 0
        }
        
        if MessageData.Redirect == ""{
            HyperLinkView.hidden = true
            HyperLinkViewHeight.constant = 0
        }
        
        if SenderMode{
            UpdateMessage()
        }
        else{
//            SenderLabel.hidden = true
//            SenderLabelHeight.constant = 0
            StatusBtn.hidden = true
            StatusBtnHeight.constant = 0
            
            if MustVote && Options.count > 0{
                let alert = UIAlertController(title: "此訊息有投票項目,現在進行投票?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
                
                alert.addAction(UIAlertAction(title: "下次再說", style: UIAlertActionStyle.Cancel, handler: nil))
                
                alert.addAction(UIAlertAction(title: "進行投票", style: UIAlertActionStyle.Destructive, handler: { (action1) -> Void in
                    self.Vote()
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        Content.text = MessageData.Content
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        MessageCoreData.SaveCatchData(MessageData)
    }
    
    override func viewDidAppear(animated: Bool) {
        Content.setContentOffset(CGPointMake(0, 0), animated: false)
    }
    
    func Vote(){
        let voteView = self.storyboard?.instantiateViewControllerWithIdentifier("VoteViewCtrl") as! VoteViewCtrl
        voteView.Options = Options
        voteView.MessageData = MessageData
        
        self.navigationController?.pushViewController(voteView, animated: true)
    }
    
    func OpenUrl(){
        let alert = UIAlertController(title: "開啟附加連結", message: "您確定要開啟附加連結？開啟前請先確認該網址的安全性，避免損害您的裝置。", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Destructive){ (action) -> Void in
            
            if let encodeUrl = self.MessageData.Redirect.UrlEncoding{
                let url:NSURL = NSURL(string:encodeUrl)!
                UIApplication.sharedApplication().openURL(url)
            }
            
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
        
        //SenderLabel.text = "已讀 ( \(read) / \(total) )"
        
        StatusBtn.setTitle("已讀: \(read)          未讀: \(total.intValue - read.intValue)", forState: UIControlState.Normal)
    }
    
    func GetMessageOptions(){
        
        var json = JSON(data: NotificationService.GetMessageById(MessageData.Id, accessToken: Global.AccessToken))
        
        if let single = json["reply"].number {
            MustVote = false
        }
        else if let multiple = json["reply"].array {
            MustVote = false
        }
        else{
            MustVote = true
        }
        
        for option in json["options"].arrayValue{
            Options.append(option.stringValue)
        }
    }
    
    func WatchReaderList(){
        
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("WatchReaderListViewCtrl") as! WatchReaderListViewCtrl
        nextView.ReadersCatch = ReadersCatch
        nextView.ReadList = ReadList
        
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
}

//
//  MessageViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/22/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//
import UIKit
import Parse

class MessageViewCtrl: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    var messageData = [MessageItem]()
    var DisplayMessage = [MessageItem]()
    
    var _dateFormate = NSDateFormatter()
    var _timeFormate = NSDateFormatter()
    var _boldFont = UIFont.boldSystemFontOfSize(17.0)
    var _normalFont = UIFont.systemFontOfSize(17.0)
    
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var progressTimer : ProgressTimer!
    
    var _today : String!
    
    var isFirstLoad = true
    var onInBox = true
    var UnReadCount = 0
    var ViewTitle = "我的訊息"
    
    let MsgIcon = UIImage(named: "Message Filled-32 White.png")
    let VotedIcon = UIImage(named: "Starred Ticket Filled-32.png")
    let VoteIcon = UIImage(named: "Starred Ticket-32.png")
    
    @IBOutlet weak var tableView: UITableView!
    var refreshControl : UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ResetBadge()
        
        let sideMenuBtn = UIBarButtonItem(image: UIImage(named: "Menu-24.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "ToggleSideMenu")
        self.navigationItem.leftBarButtonItem = sideMenuBtn
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Menu 2-26.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "MessageMenu")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: "ReloadData", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        self.navigationController?.interactivePopGestureRecognizer?.enabled = false
        
        progressTimer = ProgressTimer(progressBar: progress)
        
        _dateFormate.dateFormat = "yyyy/MM/dd"
        _timeFormate.dateFormat = "HH:mm"
        
        _today = _dateFormate.stringFromDate(NSDate())
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
//    override func viewDidUnload() {
//        NotificationService.SetNewMessageDelegate(nil)
//    }
    
    override func viewWillAppear(animated: Bool) {
        SetViewTitle()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        NotificationService.SetNewMessageDelegate { () -> () in
            self.ReloadData()
        }
        
        if isFirstLoad || NotificationService.NeedReload{
            NotificationService.ExecuteNewMessageDelegate()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        NotificationService.SetNewMessageDelegate(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func ResetBadge(){
        PFInstallation.currentInstallation().badge = 0
        PFInstallation.currentInstallation().saveInBackground()
    }
    
    func SetViewTitle(){
        
        var unread = 0
        
        for msg in self.DisplayMessage{
            unread += msg.IsNew ? 1 : 0
        }
        
        UnReadCount = unread
        
        self.navigationItem.title = UnReadCount > 0 && ViewTitle == "收件訊息" ? "\(ViewTitle) ( \(UnReadCount) 封未讀 )" : "\(ViewTitle)"
    }
    
    func ReloadData(){
        
        isFirstLoad = false
        
        self.refreshControl.endRefreshing()
        
        progressTimer.StartProgress()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            
            for msg in self.GetNewMessageData(){
                MessageCoreData.SaveCatchData(msg)
            }
            
            self.messageData = MessageCoreData.LoadCatchData()
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.DisplayMessage = self.messageData
                
                if self.DisplayMessage.count > 0{
                    self.noDataLabel.hidden = true
                }
                else{
                    self.noDataLabel.hidden = false
                }
                
                if self.onInBox{
                    self.GotoInbox()
                }
                else{
                    self.GotoOutbox()
                }
                
                self.progressTimer.StopProgress()
            })
        })
    }
    
    func GetNewMessageData() -> [MessageItem]{
        
        var retVal = [MessageItem]()
        
        //計算要更新的數量
        let count = NotificationService.GetMessageCount(Global.AccessToken) - MessageCoreData.GetCount()
        
        if count == 0{
            return retVal
        }
        
        var mod = count % 10
        
        if mod > 0 {
            mod = 1
        }
        
        for i in 1...(count / 10) + mod{
            
            //取得訊息
            var jsons = JSON(data: NotificationService.GetMessage("\(i)", accessToken: Global.AccessToken))
            
            var format:NSDateFormatter = NSDateFormatter()
            format.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
            //format.timeZone = NSTimeZone(name: "Asia/Taipei")
            
            for (index,obj) in jsons {
                
                let dateTime = obj["time"].stringValue
                
                let id = obj["_id"].stringValue
                let isNew = obj["new"].stringValue == "true" ? true : false
                let message = obj["message"].stringValue
                let redirect = obj["redirect"].stringValue
                let sender = obj["from"]["sender"].stringValue
                let dsnsname = obj["from"]["group"]["dsnsname"].stringValue
                let name = obj["from"]["group"]["name"].stringValue
                
                let isSender = obj["sender"].stringValue == "true" ? true : false
                let isReceiver = obj["receiver"].stringValue == "true" ? true : false
                
                let type = obj["type"].stringValue
                
                //有沒有投過票
                var voted = false
                if let single = obj["reply"].number {
                    voted = true
                }
                else if let multiple = obj["reply"].array {
                    voted = true
                }
                
                let newDate = format.dateFromString(dateTime)
                
                retVal.append(MessageItem(id: id, date: newDate!, isNew: isNew, title: sender, content: message, redirect: redirect, dsnsName: dsnsname, name: name,isSender: isSender, isReceiver: isReceiver, type: type, voted: voted))
            }
        }
        
        return retVal
    }
    
    func ToggleSideMenu(){
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        
        app.centerContainer?.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
    
    func MessageMenu(){
        let menu = UIAlertController(title: "你想要？", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        menu.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        menu.addAction(UIAlertAction(title: "查看收件", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.GotoInbox()
        }))
        
        menu.addAction(UIAlertAction(title: "查看寄件", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.GotoOutbox()
        }))
        
        menu.addAction(UIAlertAction(title: "發送訊息", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("OutboxSendViewCtrl") as! OutboxSendViewCtrl
            
            self.navigationController?.pushViewController(nextView, animated: true)
        }))
        
        self.presentViewController(menu, animated: true, completion: nil)
    }
    
    func GotoInbox(){
        
        self.onInBox = true
        
        var tmpData = [MessageItem]()
        
        for mi in self.messageData{
            if mi.IsReceiver{
                tmpData.append(mi)
            }
        }
        
        self.DisplayMessage = tmpData
        self.ViewTitle = "收件訊息"
        self.SetViewTitle()
        self.tableView.reloadData()
    }
    
    func GotoOutbox(){
        
        self.onInBox = false
        
        var tmpData = [MessageItem]()
        
        for mi in self.messageData{
            if mi.IsSender{
                tmpData.append(mi)
            }
        }
        
        self.DisplayMessage = tmpData
        self.ViewTitle = "寄件訊息"
        self.SetViewTitle()
        self.tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return DisplayMessage.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let data = DisplayMessage[indexPath.row]
        
        let date = _dateFormate.stringFromDate(data.Date)
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell") as! MessageCell
        cell.Title.font = data.IsNew ? _boldFont : _normalFont
        cell.Title.text = data.Title
        cell.Date.text = _today == date ? _timeFormate.stringFromDate(data.Date) : date
        cell.Date.textColor = data.IsNew ? UIColor(red: 19 / 255, green: 144 / 255, blue: 255 / 255, alpha: 1) : UIColor.lightGrayColor()
        cell.Content.text = data.Content
        
        if data.Type == "normal"{
            cell.Icon.image = MsgIcon
        }
        else{
            cell.Icon.image = data.Voted ? VotedIcon : VoteIcon
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let data = DisplayMessage[indexPath.row]
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MessageCell
        
        if data.IsNew{
            data.IsNew = false
            UnReadCount--
            
            cell.Title.font = _normalFont
            cell.Date.textColor = data.IsNew ? UIColor(red: 19 / 255, green: 144 / 255, blue: 255 / 255, alpha: 1) : UIColor.lightGrayColor()
        }
        
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("MessageDetailViewCtrl") as! MessageDetailViewCtrl
        nextView.MessageData = data
        
        if data.IsSender && ViewTitle == "寄件訊息"{
            nextView.SenderMode = true
        }
        
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
}

class MessageItem : Equatable{
    var Id : String
    var Date : NSDate
    var IsNew : Bool
    var Title : String
    var Content : String
    var Redirect : String
    var DsnsName : String
    var Name : String
    var IsSender : Bool
    var IsReceiver : Bool
    
    var Type : String
    var Voted : Bool
    
    init(id: String, date: NSDate, isNew: Bool, title: String, content: String, redirect: String, dsnsName: String, name: String, isSender: Bool, isReceiver: Bool, type: String,voted:Bool){
        Id = id
        Date = date
        IsNew = isNew
        Title = title
        Content = content
        Redirect = redirect
        DsnsName = dsnsName
        Name = name
        IsSender = isSender
        IsReceiver = isReceiver
        
        Type = type
        Voted = voted
    }
    
//    convenience init(id: String, date: NSDate, isNew: Bool, title: String, content: String, redirect: String, dsnsName: String, name: String, isSender: Bool, isReceiver: Bool, type: String) {
//        
//        self.init(id: id, date: date, isNew: isNew, title: title, content: content, redirect: redirect, dsnsName: dsnsName, name: name, isSender: isSender, isReceiver: isReceiver, type: type, voted: false)
//    }
}

func ==(lhs: MessageItem, rhs: MessageItem) -> Bool {
    return lhs.Id == rhs.Id
}

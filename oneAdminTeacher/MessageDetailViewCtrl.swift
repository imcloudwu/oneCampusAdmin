//
//  MessageDetailViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/22/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class MessageDetailViewCtrl: UIViewController{
    
    var MessageData : MessageItem!
    var SenderMode = false
    
    var Options = [VoteItem]()
    var Answers = [Int]()
    
    var MustVote = false
    var CanMultiple = false
    
    @IBOutlet weak var VoteTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var VoteFrameView: UIView!
    
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
    
    @IBOutlet weak var TextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var VoteFrameHeight: NSLayoutConstraint!
    
    @IBOutlet weak var ScrollView: UIScrollView!
    
    var OptionLabels = [UILabel]()
    
    var onceToken: dispatch_once_t = 0
    
    //@IBOutlet weak var TableViewHeight: NSLayoutConstraint!
    
    @IBAction func StatusBtnClick(sender: AnyObject) {
        self.WatchReaderList()
    }
    
    var ReadersCatch = [String:String]()
    var ReadList = [String]()
    
    var _dateFormate = NSDateFormatter()
    var _timeFormate = NSDateFormatter()
    
    var _today : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        VoteFrameView.hidden = true
        
        //設為已讀
        NotificationService.SetRead(MessageData.Id, accessToken: Global.AccessToken)
        
        //tableView.delegate = self
        //tableView.dataSource = self
        
        //tableView.estimatedRowHeight = 44.0
        //tableView.rowHeight = UITableViewAutomaticDimension
        
        //判斷是否無投票訊息並設定投票按鈕和取得選項
        if MessageData.Type == "normal" {
            VoteFrameView.hidden = true
            //TableViewHeight.constant = 0
        }
        else{
            
            CanMultiple = MessageData.Type == "multiple" ? true : false
            VoteTitle.text = CanMultiple ? "選項(可複選):" : "選項:"
            
            GetMessageOptions()
            
            if SenderMode{
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "問卷統計", style: UIBarButtonItemStyle.Done, target: self, action: "ViewChart")
            }
            else{
                
                //有投過的訊息,按鈕長不一樣
                if MessageData.Voted{
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Starred Ticket Filled-25.png"), style: UIBarButtonItemStyle.Done, target: self, action: "Vote")
                }
                else{
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Starred Ticket-25.png"), style: UIBarButtonItemStyle.Done, target: self, action: "Vote")
                }
                
            }
            
        }
        
        //更新訊息狀態
        if SenderMode{
            UpdateMessage()
        }
        else{
            StatusBtn.hidden = true
            StatusBtnHeight.constant = 0
            
//            if MustVote && Options.count > 0{
//                let alert = UIAlertController(title: "此訊息有投票項目,現在進行投票?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
//                
//                alert.addAction(UIAlertAction(title: "下次再說", style: UIAlertActionStyle.Cancel, handler: nil))
//                
//                alert.addAction(UIAlertAction(title: "進行投票", style: UIAlertActionStyle.Destructive, handler: { (action1) -> Void in
//                    self.Vote()
//                }))
//                
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
        }
        
        //資料初始化
        _dateFormate.dateFormat = "yyyy/MM/dd"
        _timeFormate.dateFormat = "HH:mm"
        
        _today = _dateFormate.stringFromDate(NSDate())
        
        let date = _dateFormate.stringFromDate(MessageData.Date)
        
        HyperLink.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "OpenUrl"))
        
        MessageTitle.text = MessageData.Title
        
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
        
        Content.text = MessageData.Content
        
        //TextViewHeight.constant = frame.size.height
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        //前一個畫面已經將isNew設定過了,直接儲存
        MessageCoreData.SaveCatchData(MessageData)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        dispatch_once(&onceToken) { () -> Void in
            self.InitUIControl()
        }
    }
    
    func InitUIControl(){
        var yPosition : CGFloat = 0.0
        
        Content.setContentOffset(CGPointMake(0, 0), animated: false)
        
        let bestSize = Content.sizeThatFits(Content.bounds.size)
        TextViewHeight.constant = bestSize.height
        
        //VoteFrameHeight.constant = CGFloat(Float(Options.count)) * 40 + 100
        VoteFrameHeight.constant = 0
        
        self.view.layoutIfNeeded()
        
        yPosition += Content.bounds.size.height + 30
        
        if Options.count > 1{
            for index in 0...Options.count - 1 {
                
                let newLabel = UILabel()
                newLabel.layer.masksToBounds = true
                newLabel.layer.cornerRadius = 5
                newLabel.userInteractionEnabled = true
                newLabel.tag = index
                newLabel.numberOfLines = 0
                newLabel.text = Options[index].Title
                newLabel.backgroundColor = UIColor(red: 0.0/255, green: 150.0/255, blue: 136.0/255, alpha: 0.1)
                newLabel.frame.size.width = Content.frame.size.width
                newLabel.frame.size.height = 48.0
                newLabel.frame.origin.x = Content.frame.origin.x
                newLabel.frame.origin.y = yPosition
                
                let bestSize = newLabel.sizeThatFits(CGSizeMake(newLabel.frame.size.width, newLabel.frame.size.height))
                newLabel.frame.size.height = bestSize.height > 48.0 ? bestSize.height : 48.0
                
                yPosition += newLabel.frame.size.height + 10
                
                let tapGesture = UITapGestureRecognizer(target: self, action: "TapOption:")
                newLabel.addGestureRecognizer(tapGesture)
                
                OptionLabels.append(newLabel)
                ScrollView.addSubview(newLabel)
            }
        }
        
        if yPosition > ScrollView.contentSize.height{
            ScrollView.contentSize.height = yPosition
        }
    }
    
    func TapOption(sender : UITapGestureRecognizer){
        let view = sender.view as! UILabel
        //println("u pressed number : \(view.tag) option")
        
        if CanMultiple{
            if let index = find(Answers, view.tag){
                Answers.removeAtIndex(index)
                view.text = Options[view.tag].Title
                //cell!.accessoryType = UITableViewCellAccessoryType.None
            }
            else{
                Answers.append(view.tag)
                view.text = "✓ " + Options[view.tag].Title
                //cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
        }
        else{
            Answers.removeAll(keepCapacity: false)
            
            Answers.append(view.tag)
            
            for index in 0...Options.count - 1{
                OptionLabels[index].text = Options[index].Title
            }
            
            view.text = "✓ " + Options[view.tag].Title
        }
    }
    
//    func GoBack(){
//
//        if MustVote && !SenderMode {
//
//            let alarm = UIAlertController(title: "提醒您", message: "此訊息尚未進行投票回覆呦", preferredStyle: UIAlertControllerStyle.Alert)
//            
//            alarm.addAction(UIAlertAction(title: "朕知道了", style: UIAlertActionStyle.Cancel, handler: nil))
//            
//            alarm.addAction(UIAlertAction(title: "下次再說", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
//                self.navigationController?.popViewControllerAnimated(true)
//            }))
//            
//            //alarm.addAction(UIAlertAction(title: "朕知道了", style: UIAlertActionStyle.Default, handler: nil))
//            
//            self.presentViewController(alarm, animated: true, completion: nil)
//        }
//        else{
//            self.navigationController?.popViewControllerAnimated(true)
//        }
//        
//    }
    
    func ViewChart(){
        let chartView = self.storyboard?.instantiateViewControllerWithIdentifier("ChartViewCtrl") as! ChartViewCtrl
        chartView.VoteItems = Options
        
        self.navigationController?.pushViewController(chartView, animated: true)
    }
    
    func Vote(){
        
        if Answers.count > 0{
            
            MustVote = false
            
            if CanMultiple{
                NotificationService.ReplyMultiple(MessageData.Id, accessToken: Global.AccessToken, answers: Answers)
                self.navigationController?.popViewControllerAnimated(true)
            }
            else{
                NotificationService.ReplySingle(MessageData.Id, accessToken: Global.AccessToken, answerIndex: Answers[0])
                self.navigationController?.popViewControllerAnimated(true)
            }
            
            MessageData.Voted = true
            MessageCoreData.SaveCatchData(MessageData)
            
            NotificationService.ExecuteNewMessageDelegate()
        }
        else{
            ShowErrorAlert(self, "錯誤", "必須選擇一個以上的選項")
        }
        
//        let voteView = self.storyboard?.instantiateViewControllerWithIdentifier("VoteViewCtrl") as! VoteViewCtrl
//        voteView.Options = Options
//        voteView.MessageData = MessageData
//        
//        self.navigationController?.pushViewController(voteView, animated: true)
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
        
        var index = 0
        for selectedOption in json["progress"]["selectedOptions"].arrayValue{
            let count = selectedOption.arrayValue.count
            //兩邊的數量應該一樣,不會發生超出length
            Options[index].Value = count
            index++
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
            //Options.append(option.stringValue)
            Options.append(VoteItem(Title: "  " + option.stringValue, Value: 0))
        }
    }
    
    func WatchReaderList(){
        
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("WatchReaderListViewCtrl") as! WatchReaderListViewCtrl
        nextView.ReadersCatch = ReadersCatch
        nextView.ReadList = ReadList
        
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
    //Mark : tableView
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
//        return Options.count
//    }
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
//        var cell = tableView.dequeueReusableCellWithIdentifier("voteCell") as? UITableViewCell
//        
//        if cell == nil {
//            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "voteCell")
//            //cell?.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
//            cell?.textLabel?.numberOfLines = 0
//        }
//        
//        cell?.textLabel?.text = Options[indexPath.row].Title
//        
//        if contains(Answers, indexPath.row){
//            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
//        }
//        else{
//            cell!.accessoryType = UITableViewCellAccessoryType.None
//        }
//        
//        return cell!
//    }
//    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
//        
//        var cell = tableView.cellForRowAtIndexPath(indexPath)
//        
//        if CanMultiple{
//            if let index = find(Answers, indexPath.row){
//                Answers.removeAtIndex(index)
//                //cell!.accessoryType = UITableViewCellAccessoryType.None
//            }
//            else{
//                Answers.append(indexPath.row)
//                //cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
//            }
//            
//            tableView.reloadData()
//        }
//        else{
//            
//            Answers.removeAll(keepCapacity: false)
//            
//            Answers.append(indexPath.row)
//            
//            tableView.reloadData()
//        }
//    }
    
}

struct VoteItem {
    var Title : String
    var Value : Int
}

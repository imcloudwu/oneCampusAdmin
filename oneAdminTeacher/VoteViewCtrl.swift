//
//  VoteViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 8/12/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class VoteViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    
    var MessageData : MessageItem!
    var Options : [String]!
    
    var Answers = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationItem.title = "進行投票"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "確認", style: UIBarButtonItemStyle.Done, target: self, action: "Confirm")
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func Confirm(){
        
        if Answers.count > 0{
            if MessageData.Type == "single"{
                NotificationService.ReplySingle(MessageData.Id, accessToken: Global.AccessToken, answerIndex: Answers[0])
                self.navigationController?.popViewControllerAnimated(true)
            }
            else{
                NotificationService.ReplyMultiple(MessageData.Id, accessToken: Global.AccessToken, answers: Answers)
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        else{
            ShowErrorAlert(self, "錯誤", "必須選擇一個以上的選項")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return Options.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("voteCell") as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "voteCell")
        }
        
        cell?.textLabel?.text = Options[indexPath.row]
        
        if contains(Answers, indexPath.row){
            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        else{
            cell!.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        
        if let index = find(Answers, indexPath.row){
            Answers.removeAtIndex(index)
            cell!.accessoryType = UITableViewCellAccessoryType.None
        }
        else{
            Answers.append(indexPath.row)
            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
    }
    
    
}


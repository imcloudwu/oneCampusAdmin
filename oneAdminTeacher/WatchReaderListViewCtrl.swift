//
//  WatchReaderListViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 8/6/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class WatchReaderListViewCtrl: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var ReadersCatch : [String:String]!
    var ReadList : [String]!
    
    var ReaderUUIDs : [String]!
    //var DisplayData : [TeacherAccount]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        ReaderUUIDs = ReadersCatch.keys.array
        
        //DisplayData = Global.GetTeacherAccountByUUIDs(ReaderUUIDs)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return ReaderUUIDs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let uuid = ReaderUUIDs[indexPath.row]
        
        var cell = tableView.dequeueReusableCellWithIdentifier("teacher") as? UITableViewCell
        
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "teacher")
            cell?.accessoryType = UITableViewCellAccessoryType.None
        }
        
        cell?.textLabel?.text = ReadersCatch[uuid]
        //cell?.detailTextLabel?.text = uuid
        
        if contains(ReadList, uuid){
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        else{
            cell?.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell!
    }
    
    
}

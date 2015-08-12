//
//  WatchReaderListViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 8/6/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class WatchReaderListViewCtrl: UIViewController,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var ReadersCatch : [String:String]!
    var ReadList : [String]!
    
    var ReaderUUIDs : [String]!
    
    var DisplayData : [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "檢視讀取狀態"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        
        ReaderUUIDs = ReadersCatch.keys.array
        
        DisplayData = ReaderUUIDs
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Menu 2-26.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "SwitchList")
        
        //DisplayData = Global.GetTeacherAccountByUUIDs(ReaderUUIDs)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return DisplayData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let uuid = DisplayData[indexPath.row]
        
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
    
    func SwitchList(){
        
        let alert = UIAlertController(title: "快速查看", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "已讀清單", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            var founds = [String]()
            
            for (key,value) in self.ReadersCatch{
                
                if contains(self.ReadList, key){
                    founds.append(key)
                }
            }
            
            self.DisplayData = founds
            
            self.tableView.reloadData()
            
        }))
        
        alert.addAction(UIAlertAction(title: "未讀清單", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            var founds = [String]()
            
            for (key,value) in self.ReadersCatch{
                
                if !contains(self.ReadList, key){
                    founds.append(key)
                }
            }
            
            self.DisplayData = founds
            
            self.tableView.reloadData()
            
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //Mark : SearchBar
    func searchBarSearchButtonClicked(searchBar: UISearchBar){
        searchBar.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            DisplayData = ReaderUUIDs
        }
        else{
            
            var founds = [String]()
            
            for (key,value) in ReadersCatch{
                
                if let match = value.lowercaseString.rangeOfString(searchText.lowercaseString){
                    founds.append(key)
                }
            }
            
            DisplayData = founds
        }
        
        self.tableView.reloadData()
    }
    
}

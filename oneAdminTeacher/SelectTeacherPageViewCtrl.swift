//
//  SelectTeacherPageViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 8/4/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class SelectTeacherPageViewCtrl: UIViewController,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var selectAllBtn: UIButton!
    
    var ParentTeacherSelector : TeacherSelector!
    var ChildTeacherSelector = TeacherSelector()
    
    var DisplayItem : [TeacherAccount]!
    
    @IBAction func SelectAll(sender: AnyObject) {
        
        if selectAllBtn.titleLabel?.text == "全部選擇"{
            selectAllBtn.setTitle("全部刪除", forState: UIControlState.Normal)
            
            ChildTeacherSelector.Teachers = Global.MyTeacherList
        }
        else{
            selectAllBtn.setTitle("全部選擇", forState: UIControlState.Normal)
            ChildTeacherSelector.Teachers.removeAll(keepCapacity: false)
        }
        
        self.tableView.reloadData()
        
        SetTitle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        
        DisplayItem = Global.MyTeacherList
        
        ChildTeacherSelector.Teachers = ParentTeacherSelector.Teachers
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "Save")
        
        SetTitle()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func SetTitle(){
        self.navigationItem.title = "選擇了 \(ChildTeacherSelector.Teachers.count) 位教師"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return DisplayItem.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let data = DisplayItem[indexPath.row]
        
        var cell = tableView.dequeueReusableCellWithIdentifier("teacher") as? UITableViewCell
        
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "teacher")
            cell?.accessoryType = UITableViewCellAccessoryType.None
        }
        
        cell?.textLabel?.text = data.Name
        cell?.detailTextLabel?.text = data.Account
        
        if contains(ChildTeacherSelector.Teachers, data){
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        else{
            cell?.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let data = DisplayItem[indexPath.row]
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        if contains(ChildTeacherSelector.Teachers, data){
            let index = ChildTeacherSelector.IndexOf(data)
            ChildTeacherSelector.Teachers.removeAtIndex(index)
            cell?.accessoryType = UITableViewCellAccessoryType.None
        }
        else{
            ChildTeacherSelector.Teachers.append(data)
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        
        SetTitle()
    }
    
    func Save(){
        ParentTeacherSelector.Teachers = ChildTeacherSelector.Teachers
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //Mark : SearchBar
    func searchBarSearchButtonClicked(searchBar: UISearchBar){
        searchBar.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            DisplayItem = Global.MyTeacherList
        }
        else{
            
            var founds = Global.MyTeacherList.filter({ t in
                
                if let x = t.Name.lowercaseString.rangeOfString(searchText.lowercaseString){
                    return true
                }
                else if let y = t.Account.lowercaseString.rangeOfString(searchText.lowercaseString){
                    return true
                }
                
                return false
            })
            
            DisplayItem = founds
        }
        
        self.tableView.reloadData()
    }
    
}

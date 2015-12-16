//
//  OptionSettingViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 8/11/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class OptionSettingViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var Options : OptionCollection!
    
    var tmpOptions = OptionCollection()
    
    @IBAction func AddBtnClick(sender: AnyObject) {
        
        if tmpOptions.Items.count < 8{
            tmpOptions.Items.append(OptionItem(""))
            self.tableView.reloadData()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tmpOptions.Items = Options.ItemClone
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationItem.title = "問卷設定"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "Save")
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tableView.reloadData()
        
        DisableSideMenu()
    }
    
    override func viewDidDisappear(animated: Bool) {
        EnableSideMenu()
    }
    
    func Save(){
        
        if (tmpOptions.Items[0].Value.isEmpty && tmpOptions.Items[1].Value.isEmpty) || (!tmpOptions.Items[0].Value.isEmpty && !tmpOptions.Items[1].Value.isEmpty){
            Options.Items = tmpOptions.Items
            self.navigationController?.popViewControllerAnimated(true)
        }
        else{
            ShowErrorAlert(self, title: "錯誤", msg: "至少需要兩個非空白選項")
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return tmpOptions.Items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("OptionCell") as! OptionCell
        cell.OptionText.text = "選項 \(indexPath.row + 1)"
        cell.OptionContent.text = tmpOptions.Items[indexPath.row].Value
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("OptionEditViewCtrl") as! OptionEditViewCtrl
        nextView.Option = tmpOptions.Items[indexPath.row]
            
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
    //滑動刪除
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath){
        if editingStyle == UITableViewCellEditingStyle.Delete && self.tmpOptions.Items.count > 2{
            self.tmpOptions.Items.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
    }
    
    
}

class OptionCollection{
    
    var Items : [OptionItem]
    
    var ItemClone : [OptionItem]{
    
        var retVal = [OptionItem]()
        
        for item in Items{
            retVal.append(OptionItem(item.Value))
        }
        
        return retVal
    }
    
    init(){
        Items = [OptionItem(""),OptionItem("")]
    }
}

class OptionItem{
    var Value : String
    
    init(_ value:String){
        Value = value
    }
}

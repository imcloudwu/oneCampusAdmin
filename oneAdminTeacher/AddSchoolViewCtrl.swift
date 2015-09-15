//
//  AddSchoolViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 9/14/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class AddSchoolViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UIWebViewDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var _DSNSDic:[String:String]!
    var _display:[String]!
    var _DsnsItem : DsnsItem!
    
    var webView : UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "加入學校"
        
        searchBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        _DSNSDic = [String:String]()
        _display = [String]()
        
        webView = UIWebView()
        webView.hidden = true
        webView.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        self.webView.frame = self.view.bounds
        self.view.addSubview(self.webView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func DsnsIsExist(address:String) -> Bool{
        var tmp = DsnsItem(name: "", accessPoint: address)
        
        return contains(Global.DsnsList, tmp)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _display.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        var cell = self.tableView.dequeueReusableCellWithIdentifier("school") as? UITableViewCell
        
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "school")
        }
        
        cell?.textLabel?.text = _display[indexPath.row]
        
        if let address = self._DSNSDic[self._display[indexPath.row]]{
            
            if DsnsIsExist(address){
                cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            else{
                cell?.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        if let address = self._DSNSDic[self._display[indexPath.row]]{
            
            if self.DsnsIsExist(address){
                
                let deleteConfirm = UIAlertController(title: "確認刪除 \(_display[indexPath.row]) 嗎?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
                
                deleteConfirm.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
                
                deleteConfirm.addAction(UIAlertAction(title: "確認", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                    
                    self.DeleteApplicationRef(address)
                    
                }))
                
                self.presentViewController(deleteConfirm, animated: true, completion: nil)
                
            }
            else{
                
                let addConfirm = UIAlertController(title: "確認加入 \(_display[indexPath.row]) 嗎?", message: "", preferredStyle: UIAlertControllerStyle.Alert)
                
                addConfirm.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
                
                addConfirm.addAction(UIAlertAction(title: "確認", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                    
                    self.AddApplicationRef(address)
                    
                }))
                
                self.presentViewController(addConfirm, animated: true, completion: nil)
            }
        }
        
    }
    
    //Mark : SearchBar
    func searchBarSearchButtonClicked(searchBar: UISearchBar){
        searchBar.resignFirstResponder()
        self.view.endEditing(true)
        
        newSearch(searchBar.text.lowercaseString)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        //newSearch(searchText)
    }
    
    func newSearch(matchName:String){
        
        //encode成功呼叫查詢
        if let encodingName = matchName.UrlEncoding{
            
            HttpClient.Get("http://dsns.1campus.net/campusman.ischool.com.tw/config.public/GetSchoolList?content=%3CRequest%3E%3CMatch%3E\(encodingName)%3C/Match%3E%3CPagination%3E%3CPageSize%3E10%3C/PageSize%3E%3CStartPage%3E1%3C/StartPage%3E%3C/Pagination%3E%3C/Request%3E", successCallback: { (response) -> Void in
                
                if !response.isEmpty {
                    
                    //println(NSString(data: rsp, encoding: NSUTF8StringEncoding))
                    
                    var tmpDic = [String:String]()
                    
                    var nserr : NSError?
                    
                    let xml = AEXMLDocument(xmlData: response.dataValue, error: &nserr)
                    
                    if let schools = xml?.root["Response"]["School"].all{
                        
                        for school in schools{
                            let name = school["Title"].stringValue
                            let dsns = school["DSNS"].stringValue
                            
                            tmpDic[name] = dsns
                        }
                    }
                    
                    self._DSNSDic = tmpDic
                    self._display = tmpDic.keys.array
                }
                
                self.tableView.reloadData()
                
                }, errorCallback: { (error) -> Void in
                    //code
                }, prepareCallback: { (request) -> Void in
                    //code
            })
        }
    }
    
    func DeleteApplicationRef(server:String){
        
        self._DsnsItem = DsnsItem(name: "", accessPoint: server)
        
        var err : DSFault!
        var con = Connection()
        con.connect("https://auth.ischool.com.tw:8443/dsa/greening", "user", SecurityToken.createOAuthToken(Global.AccessToken), &err)
        
        if err != nil{
            ShowErrorAlert(self, "過程發生錯誤", err.message)
            return
        }
        
        var rsp = con.sendRequest("DeleteApplication", bodyContent: "<Request><Application><AccessPoint>\(server)</AccessPoint><Type>dynpkg</Type></Application></Request>", &err)
        
        if err != nil{
            ShowErrorAlert(self, "過程發生錯誤", err.message)
            return
        }
        
        var newList = [DsnsItem]()
        
        for dsns in Global.DsnsList{
            
            if dsns != self._DsnsItem{
                newList.append(dsns)
            }
        }
        
        Global.DsnsList = newList
        
        Goback()
    }
    
    func AddApplicationRef(server:String){
        
        self._DsnsItem = DsnsItem(name: "", accessPoint: server)
        
        if !contains(Global.DsnsList,self._DsnsItem){
            
            var err : DSFault!
            var con = Connection()
            con.connect("https://auth.ischool.com.tw:8443/dsa/greening", "user", SecurityToken.createOAuthToken(Global.AccessToken), &err)
            
            if err != nil{
                ShowErrorAlert(self, "過程發生錯誤", err.message)
                return
            }
            
            var rsp = con.sendRequest("AddApplicationRef", bodyContent: "<Request><Applications><Application><AccessPoint>\(server)</AccessPoint><Type>dynpkg</Type></Application></Applications></Request>", &err)
            
            if err != nil{
                ShowErrorAlert(self, "過程發生錯誤", err.message)
                return
            }
            
            Global.DsnsList.append(self._DsnsItem)
            
            ShowWebView()
        }
    }
    
    func ShowWebView(){
        
        let target = "https://auth.ischool.com.tw/oauth/authorize.php?client_id=\(Global.clientID)&response_type=token&redirect_uri=http://_blank&scope=User.Mail,User.BasicInfo,1Campus.Notification.Read,1Campus.Notification.Send,*:auth.guest,*:\(Global.ContractName)&access_token=\(Global.AccessToken)"
        
        var urlobj = NSURL(string: target)
        var request = NSURLRequest(URL: urlobj!)
        
        self.webView.loadRequest(request)
        self.webView.hidden = false
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError){
        
        //網路異常
        if error.code == -1009 || error.code == -1003{
            
            if UpdateTokenFromError(error){
                Goback()
            }
            else{
                ShowErrorAlert(self, "連線過程發生錯誤", "若此情況重複發生,建議重登後再嘗試")
            }
        }
    }
    
    func UpdateTokenFromError(error: NSError) -> Bool{
        
        var accessToken : String!
        var refreshToken : String!
        
        if let url = error.userInfo?["NSErrorFailingURLStringKey"] as? String{
            
            let stringArray = url.componentsSeparatedByString("&")
            
            if stringArray.count != 5{
                return false
            }
            
            if let range1 = stringArray[0].rangeOfString("http://_blank/#access_token="){
                accessToken = stringArray[0]
                accessToken.removeRange(range1)
            }
            
            if let range2 = stringArray[4].rangeOfString("refresh_token="){
                refreshToken = stringArray[4]
                refreshToken.removeRange(range2)
            }
        }
        
        if accessToken != nil && refreshToken != nil{
            Global.SetAccessTokenAndRefreshToken((accessToken: accessToken, refreshToken: refreshToken))
            return true
        }
        
        return false
    }
    
    func Goback(){
//        Global.SchoolListChanged = true
//        self.navigationController?.popViewControllerAnimated(true)
        
        Global.SchoolListChanged = true
        
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("ClassQuery") as! UIViewController
        
        ChangeContentView(nextView)
    }
}

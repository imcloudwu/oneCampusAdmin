////  Created by Cloud on 6/12/15.
////  Copyright (c) 2015 ischool. All rights reserved.
////
//
//import UIKit
//
//class SchoolOptionsView: UIViewController {
//    
//    @IBOutlet weak var ServerBtn: UIButton!
//    
//    let _achtonSheet = UIAlertController(title: "請選擇登入學校主機", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        _achtonSheet.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
//        
//        for dsns in Global.DsnsList{
//            _achtonSheet.addAction(UIAlertAction(title: dsns.Name, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
//                self.ServerBtn.setTitle(dsns.Name, forState: UIControlState.Normal)
//                Global.CurrentDsns = dsns
//            }))
//        }
//        // Do any additional setup after loading the view, typically from a nib.
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    
//    @IBAction func SelectSchoolServer(sender: AnyObject) {
//        self.presentViewController(_achtonSheet, animated: true, completion: nil)
//    }
//    
//    @IBAction func GoToNextView(sender: AnyObject) {
//        
//        if Global.CurrentDsns == nil{
//            let alert = UIAlertController(title: "錯誤", message: "您必須選擇一台主機才能繼續操作", preferredStyle: UIAlertControllerStyle.Alert)
//            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
//            
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
//        else{
//            //let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("menuView") as! UIViewController
//            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("ClassQuery") as! UIViewController
//            ChangeContentView(nextView)
//            //self.presentViewController(nextView, animated: true, completion: nil)
//        }
//    }
//}
//

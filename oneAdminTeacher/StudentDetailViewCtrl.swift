//
//  StudentDetailViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/13/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class StudentDetailViewCtrl: UIViewController {
    
    @IBOutlet weak var SubTitleView: UIView!
    @IBOutlet weak var SubTitle1: UILabel!
    @IBOutlet weak var SubTitle2: UILabel!
    @IBOutlet weak var SubTitle3: UILabel!
    
    @IBOutlet weak var Height: NSLayoutConstraint!
    @IBOutlet weak var EmbedView: UIView!
    @IBOutlet weak var Segment: UISegmentedControl!
    @IBOutlet weak var SegmentHeight: NSLayoutConstraint!
    
    @IBOutlet weak var PhotoImage: UIImageView!
    
    let upArrow = UIImage(named: "Up 4-25.png")
    let downArrow = UIImage(named: "Down 4-25.png")
    
    var ExpandBtn : UIBarButtonItem!
    
    var StudentData : Student!
    
    var IsClassStudent = true
    
    var mustFlipPhoto = true
    
    var lastSegmentIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var pics = ["background.png","background5.png"]
        let randomIndex = Int(arc4random_uniform(2))
        
        var background = UIImageView(image: UIImage(named: pics[randomIndex]))
        background.frame = SubTitleView.bounds
        //nback.contentMode = UIViewContentMode.ScaleAspectFill
        SubTitleView.insertSubview(background, atIndex: 0)
        
        //移除底端邊界
        //self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        //self.navigationController?.navigationBar.shadowImage = UIImage()
        //self.navigationItem.title = StudentData.Name
        self.navigationController?.navigationBar.topItem?.title = StudentData.Name
        
        ExpandBtn = UIBarButtonItem(image: upArrow, style: UIBarButtonItemStyle.Plain, target: self, action: "ChangeHeight")
        self.navigationItem.rightBarButtonItem = ExpandBtn
        
        PhotoImage.image = nil
        PhotoImage.layer.cornerRadius = PhotoImage.frame.size.width / 2
        PhotoImage.layer.masksToBounds = true
        
        PhotoImage.layer.borderWidth = 3.0
        PhotoImage.layer.borderColor = UIColor.whiteColor().CGColor
        
        var tap = UITapGestureRecognizer(target: self, action: "DisplayPhoto")
        PhotoImage.addGestureRecognizer(tap)
        
        if !IsClassStudent{
            Segment.hidden = true
            SegmentHeight.constant = 0
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        SubTitle1.text = StudentData.Name
        SubTitle2.text = "學號 : \(StudentData.StudentNumber)"
        SubTitle3.text = StudentData.ClassName + (StudentData.SeatNo == "" ? "" : " " + StudentData.SeatNo + " 號")
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if mustFlipPhoto{
            UIView.transitionWithView(PhotoImage, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromTop, animations: { () -> Void in
                self.PhotoImage.image = self.StudentData.Photo
                }) { (Bool) -> Void in
                    self.mustFlipPhoto = false
            }
        }
        
        if Segment.selectedSegmentIndex == lastSegmentIndex{
            return
        }
        
        if self.IsClassStudent{
            self.SegmentValueChange(self)
        }
        else{
            let contentView = self.storyboard?.instantiateViewControllerWithIdentifier("CourseScoreViewCtrl") as! CourseScoreViewCtrl
            self.ChangeContainerViewContent(contentView)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func SegmentValueChange(sender: AnyObject) {
        
        if Segment.selectedSegmentIndex == 0{
            let contentView = self.storyboard?.instantiateViewControllerWithIdentifier("studentInfoViewCtrl") as! StudentInfoViewCtrl
            ChangeContainerViewContent(contentView)
        }
        else if Segment.selectedSegmentIndex == 1{
            let contentView = self.storyboard?.instantiateViewControllerWithIdentifier("attendanceViewCtrl") as! AttendanceViewCtrl
            ChangeContainerViewContent(contentView)
        }
        else if Segment.selectedSegmentIndex == 2{
            let contentView = self.storyboard?.instantiateViewControllerWithIdentifier("disciplineViewCtrl") as! DisciplineViewCtrl
            ChangeContainerViewContent(contentView)
        }
        else if Segment.selectedSegmentIndex == 3{
            let contentView = self.storyboard?.instantiateViewControllerWithIdentifier("examScoreViewCtrl") as! ExamScoreViewCtrl
            ChangeContainerViewContent(contentView)
        }
        else if Segment.selectedSegmentIndex == 4{
            let contentView = self.storyboard?.instantiateViewControllerWithIdentifier("semesterScoreViewCtrl") as! SemesterScoreViewCtrl
            ChangeContainerViewContent(contentView)
        }
    }
    
    func DisplayPhoto(){
        lastSegmentIndex = Segment.selectedSegmentIndex
        let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("DisplayViewCtrl") as! DisplayViewCtrl
        nextView.Image = StudentData.Photo
        self.navigationController?.pushViewController(nextView, animated: true)
    }
    
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        if UIDevice.currentDevice().orientation.isLandscape.boolValue {
//            println("landscape")
//        } else {
//            println("portraight")
//        }
//    }
    
    func ChangeHeight(){
        SubTitleView.hidden = !SubTitleView.hidden
        Height.constant = SubTitleView.hidden ? 0 : 133
        ExpandBtn.image = SubTitleView.hidden ? downArrow : upArrow
    }
    
    func ChangeContainerViewContent(vc : UIViewController){
        
        DeteleRightBarButtonItems()
        
        childViewControllers.first?.removeFromParentViewController()
        
        //var newController = self.storyboard?.instantiateViewControllerWithIdentifier("test1") as! UIViewController
        
        SetContainViewData(vc)
        addChildViewController(vc)
        
        //newController.didMoveToParentViewController(self)
        
        for sub in EmbedView.subviews as! [UIView]{
            sub.removeFromSuperview()
        }
        
        vc.view.frame = EmbedView.bounds
        
        EmbedView.addSubview(vc.view)
        
        //            var newController = self.storyboard?.instantiateViewControllerWithIdentifier("test2") as! UIViewController
        //            let oldController = childViewControllers.last as? UIViewController
        //
        //            oldController?.willMoveToParentViewController(nil)
        //            addChildViewController(newController)
        //
        //            if let frame = oldController?.view.frame{
        //                newController.view.frame = frame
        //            }
        //
        //            oldController?.removeFromParentViewController()
        //            newController.didMoveToParentViewController(self)
        //            
        //            EmbedView.addSubview(newController.view)
    }
    
    func DeteleRightBarButtonItems(){
        if self.navigationItem.rightBarButtonItems?.count != 1{
            self.navigationItem.rightBarButtonItems?.removeLast()
            DeteleRightBarButtonItems()
        }
    }
    
    func SetContainViewData(vc : UIViewController){
        var cvp = vc as! ContainerViewProtocol
        cvp.StudentData = StudentData
        cvp.ParentNavigationItem = self.navigationItem
    }
}

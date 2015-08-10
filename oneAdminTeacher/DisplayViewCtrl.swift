//
//  DisplayViewCtrl.swift
//  oneAdminTeacher
//
//  Created by Cloud on 7/16/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class DisplayViewCtrl: UIViewController,UIWebViewDelegate{
    
    var Image : UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    
    var progressTimer :  ProgressTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = Image{
            imageView.image = Image
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

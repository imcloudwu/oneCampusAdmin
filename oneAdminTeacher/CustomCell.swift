//
//  CustomCell.swift
//  oneAdminTeacher
//
//  Created by Cloud on 6/12/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class SHSemesterScoreSummaryCell : UITableViewCell{
    
    @IBOutlet weak var 實得: UILabel!
    @IBOutlet weak var 已修: UILabel!
    @IBOutlet weak var 必修: UILabel!
    @IBOutlet weak var 選修: UILabel!
    @IBOutlet weak var 校訂必修: UILabel!
    @IBOutlet weak var 校訂選修: UILabel!
    @IBOutlet weak var 部訂必修: UILabel!
    @IBOutlet weak var 部訂選修: UILabel!
    @IBOutlet weak var 實習: UILabel!
    
    override func awakeFromNib() {
        
    }
}

class JHSemesterScoreSummaryCell : UITableViewCell{
    
    @IBOutlet weak var 不及格領域數: UILabel!
    @IBOutlet weak var 學習領域成績: UILabel!
    @IBOutlet weak var 課程學期成績: UILabel!
    
    override func awakeFromNib() {
        
    }
}

class SemesterScoreItemCell : UITableViewCell{
    
    @IBOutlet weak var Subject: UILabel!
    @IBOutlet weak var Score: UILabel!
    @IBOutlet weak var Info: UILabel!
    @IBOutlet weak var Check: UIImageView!
    
    override func awakeFromNib() {
        Score.layer.cornerRadius = Score.frame.size.width / 2
        Score.layer.masksToBounds = true
    }
}

class StudentCell2 : UITableViewCell{
    
    @IBOutlet weak var Photo: UIImageView!
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var ClassName: UILabel!
    @IBOutlet weak var ClassSeatNo: UILabel!
    
    var student : Student!
    
    override func awakeFromNib() {
        Photo.layer.cornerRadius = Photo.frame.size.width / 2
        Photo.layer.masksToBounds = true
    }
}

class StudentCell : UITableViewCell{
    
    @IBOutlet weak var Photo: UIImageView!
    @IBOutlet weak var Label1: UILabel!
    @IBOutlet weak var Label2: UILabel!
    
    var student : Student!
    
    override func awakeFromNib() {
        Photo.layer.cornerRadius = Photo.frame.size.width / 2
        Photo.layer.masksToBounds = true
    }
}

class StudentBasicInfoCell : UITableViewCell{
    
    @IBOutlet weak var Title: UILabel!
    @IBOutlet weak var Value: UILabel!
    
    override func awakeFromNib() {
    }
}

class AttendanceItemCell : UITableViewCell{
    
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var Type: UILabel!
    @IBOutlet weak var Periods: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class DisciplineItemCell : UITableViewCell{
    
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var Status: UILabel!
    @IBOutlet weak var Reason: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class ExamScoreItemCell : UITableViewCell{
    
    @IBOutlet weak var ExamName: UILabel!
    @IBOutlet weak var Score: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class ExamScoreMoreInfoItemCell : UITableViewCell{
    
    @IBOutlet weak var ExamName: UILabel!
    @IBOutlet weak var Score: UILabel!
    @IBOutlet weak var Info1: UILabel!
    @IBOutlet weak var Info2: UILabel!
    @IBOutlet weak var Info3: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class ClassCell : UITableViewCell{
    
    @IBOutlet weak var ClassIcon: UILabel!
    @IBOutlet weak var ClassName: UILabel!
    @IBOutlet weak var Major: UILabel!
    
    var classItem : ClassItem!
    
    override func awakeFromNib() {
//        ClassIcon.layer.cornerRadius = 5
//        ClassIcon.layer.masksToBounds = true
    }
}

class MessageCell : UITableViewCell{
    
    @IBOutlet weak var Title: UILabel!
    @IBOutlet weak var Content: UILabel!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var Icon: UIImageView!
    @IBOutlet weak var IcomFrame: UIView!
    
    override func awakeFromNib() {
        IcomFrame.layer.cornerRadius = IcomFrame.frame.size.width / 2
        IcomFrame.layer.masksToBounds = true
    }
}

class OptionCell : UITableViewCell{
    
    @IBOutlet weak var OptionText: UILabel!
    @IBOutlet weak var OptionContent: UITextView!
    
    override func awakeFromNib() {
    }
}

class ChartOptionCell : UITableViewCell{
    
    @IBOutlet weak var ColorView: UIView!
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var ValueLabel: UILabel!
    
    override func awakeFromNib() {
    }
}

/*
class AbsentCell : UITableViewCell{
    
    @IBOutlet weak var Type: UILabel!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var Period: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class DisciplineCell : UITableViewCell{
    
    @IBOutlet weak var State: UILabel!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var Reason: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class SemesterCell : UITableViewCell{
    
    @IBOutlet weak var Title: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class SemesterScoreCell : UITableViewCell{
    
    @IBOutlet weak var Subject: UILabel!
    @IBOutlet weak var Info: UILabel!
    @IBOutlet weak var Type: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class ExamScoreCell : UITableViewCell{
    
    @IBOutlet weak var Subject: UILabel!
    @IBOutlet weak var Credit: UILabel!
    @IBOutlet weak var ScoreA: UILabel!
    @IBOutlet weak var ScoreB: UILabel!
    @IBOutlet weak var ScoreC: UILabel!
    @IBOutlet weak var SubTitleA: UILabel!
    @IBOutlet weak var SubTitleB: UILabel!
    
    override func awakeFromNib() {
        //
    }
}

class ExamScoreTitleCell : UITableViewCell{
    
    @IBOutlet weak var Domain: UILabel!
    @IBOutlet weak var Score: UILabel!
    
    override func awakeFromNib() {
    }
}
*/

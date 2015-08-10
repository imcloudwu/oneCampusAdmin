////
////  FirstViewController.swift
////  oneAdminTeacher
////
////  Created by Cloud on 6/12/15.
////  Copyright (c) 2015 ischool. All rights reserved.
////
//
//import UIKit
//
//class DeatilViewCtrl: UIViewController,UITableViewDataSource,UITableViewDelegate {
//    
//    @IBOutlet weak var Photo: UIImageView!
//    @IBOutlet weak var StudentName: UILabel!
//    @IBOutlet weak var ClassName: UILabel!
//    @IBOutlet weak var StudentNumber: UILabel!
//    @IBOutlet weak var ParentName: UILabel!
//    @IBOutlet weak var Phone: UILabel!
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var segment: UISegmentedControl!
//    
//    var StudentData : Student!
//    var _AbsentData = [Absent]()
//    var _DisciplineData = [Discipline]()
//    var _ExamScoreData = [ExamScore]()
//    var _SemesterScoreData = [SemesterScore]()
//    
//    var _currentDataType = DataType.Absent
//    
//    enum DataType : Int{
//        case Absent,Discipline,ExamScore,SemesterScore
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        _AbsentData.append(Absent(Type: "曠課", Date: "2015/01/01", Period: "一,二,三,四,午休"))
//        _AbsentData.append(Absent(Type: "遲到", Date: "2015/01/10", Period: "五,六,七,八"))
//        _AbsentData.append(Absent(Type: "早退", Date: "2015/01/30", Period: "晚自習"))
//        _AbsentData.append(Absent(Type: "早退", Date: "2015/01/30", Period: "晚自習"))
//        _AbsentData.append(Absent(Type: "早退", Date: "2015/01/30", Period: "晚自習"))
//        _AbsentData.append(Absent(Type: "早退", Date: "2015/01/30", Period: "晚自習"))
//        _AbsentData.append(Absent(Type: "早退", Date: "2015/01/30", Period: "晚自習"))
//        
//        _DisciplineData.append(Discipline(Type: DisciplineType.Merit, Date: "2015/02/28", Reason: "參與校外打掃表現傑出", MA: 1, MB: 0, MC: 0, DA: 0, DB: 0, DC: 0))
//        _DisciplineData.append(Discipline(Type: DisciplineType.Demerit, Date: "2015/03/05", Reason: "霸凌同學,屢勸不聽", MA: 0, MB: 0, MC: 0, DA: 3, DB: 0, DC: 0))
//        _DisciplineData.append(Discipline(Type: DisciplineType.Merit, Date: "2015/03/27", Reason: "主動積極,要事第一", MA: 1, MB: 1, MC: 1, DA: 0, DB: 0, DC: 0))
//        _DisciplineData.append(Discipline(Type: DisciplineType.Merit, Date: "2015/04/05", Reason: "雙贏思維,不斷更新", MA: 3, MB: 2, MC: 1, DA: 0, DB: 0, DC: 0))
//        _DisciplineData.append(Discipline(Type: DisciplineType.Merit, Date: "2015/04/08", Reason: "服裝整齊,配件光亮", MA: 0, MB: 0, MC: 3, DA: 0, DB: 0, DC: 0))
//        
//        _ExamScoreData.append(ExamScore(SchoolYear: 99, Semester: 1, Type: "第一次段考"))
//        _ExamScoreData.append(ExamScore(SchoolYear: 99, Semester: 2, Type: "第二次段考"))
//        _ExamScoreData.append(ExamScore(SchoolYear: 100, Semester: 1, Type: "期末考"))
//        _ExamScoreData.append(ExamScore(SchoolYear: 100, Semester: 2, Type: "第一次段考"))
//        _ExamScoreData.append(ExamScore(SchoolYear: 101, Semester: 1, Type: "第二次段考"))
//        _ExamScoreData.append(ExamScore(SchoolYear: 101, Semester: 2, Type: "期末考"))
//        
//        _SemesterScoreData.append(SemesterScore(SchoolYear: 99, Semester: 1))
//        _SemesterScoreData.append(SemesterScore(SchoolYear: 99, Semester: 2))
//        _SemesterScoreData.append(SemesterScore(SchoolYear: 100, Semester: 1))
//        _SemesterScoreData.append(SemesterScore(SchoolYear: 100, Semester: 2))
//        _SemesterScoreData.append(SemesterScore(SchoolYear: 101, Semester: 1))
//        _SemesterScoreData.append(SemesterScore(SchoolYear: 102, Semester: 2))
//        
//        tableView.delegate = self
//        tableView.dataSource = self
//        
//        Photo.image = StudentData.Photo
//        StudentName.text = StudentData.Name
//        ClassName.text = StudentData.ClassName + "(1)"
//        StudentNumber.text = "學號: 911252"
//        ParentName.text = "監護人: 王大明"
//        Phone.text = "聯絡電話: \(StudentData.PermanentPhone)"
//        
//        // Do any additional setup after loading the view, typically from a nib.
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    @IBAction func segment_select(sender: AnyObject) {
//        switch segment.selectedSegmentIndex{
//        case 0:
//            SetDateTypeAndReload(DataType.Absent)
//        case 1:
//            SetDateTypeAndReload(DataType.Discipline)
//        case 2:
//            SetDateTypeAndReload(DataType.ExamScore)
//        case 3:
//            SetDateTypeAndReload(DataType.SemesterScore)
//        default:
//            break
//        }
//    }
//    
//    func SetDateTypeAndReload(type : DataType){
//        _currentDataType = type
//        
//        if _currentDataType == DataType.Absent || _currentDataType == DataType.Discipline{
//            tableView.allowsSelection = false
//        }
//        else{
//            tableView.allowsSelection = true
//        }
//        
//        tableView.reloadData()
//    }
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
//        
//        switch _currentDataType{
//        case DataType.Absent:
//            return _AbsentData.count
//        case DataType.Discipline:
//            return _DisciplineData.count
//        case DataType.ExamScore:
//            return _ExamScoreData.count
//        case DataType.SemesterScore:
//            return _SemesterScoreData.count
//        default:
//            return 0
//        }
//    }
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
//        
//        switch _currentDataType{
//            
//        case DataType.Absent:
//            let cell = tableView.dequeueReusableCellWithIdentifier("absentCell") as! AbsentCell
//            cell.Type.text = self._AbsentData[indexPath.row].Type
//            cell.Date.text = "日期: \(self._AbsentData[indexPath.row].Date)"
//            cell.Period.text = "節次: \(self._AbsentData[indexPath.row].Period)"
//            return cell
//            
//        case DataType.Discipline:
//            let cell = tableView.dequeueReusableCellWithIdentifier("disciplineCell") as! DisciplineCell
//            cell.Date.text = "日期: \(self._DisciplineData[indexPath.row].Date)"
//            cell.Reason.text = "事由: \(self._DisciplineData[indexPath.row].Reason)"
//            
//            if self._DisciplineData[indexPath.row].Type == DisciplineType.Merit{
//                cell.State.text = "大功: \(self._DisciplineData[indexPath.row].MA) 小功: \(self._DisciplineData[indexPath.row].MB) 嘉獎: \(self._DisciplineData[indexPath.row].MC)"
//                cell.State.textColor = UIColor.blackColor()
//            }
//            else{
//                cell.State.text = "大過: \(self._DisciplineData[indexPath.row].DA) 小過: \(self._DisciplineData[indexPath.row].DB) 警告: \(self._DisciplineData[indexPath.row].DC)"
//                cell.State.textColor = UIColor.redColor()
//            }
//            
//            return cell
//            
//        case DataType.ExamScore:
//            let cell = tableView.dequeueReusableCellWithIdentifier("semesterCell") as! SemesterCell
//            cell.Title.text = "\(self._ExamScoreData[indexPath.row].SchoolYear)學年度第\(self._ExamScoreData[indexPath.row].Semester)學期 \(self._ExamScoreData[indexPath.row].Type)"
//            return cell
//            
//        default:
//            let cell = tableView.dequeueReusableCellWithIdentifier("semesterCell") as! SemesterCell
//            cell.Title.text = "\(self._SemesterScoreData[indexPath.row].SchoolYear)學年度第\(self._SemesterScoreData[indexPath.row].Semester)學期"
//            return cell
//        }
//        
//    }
//    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
//        switch _currentDataType{
//        case DataType.Absent:
//            return 85
//        case DataType.Discipline:
//            return 85
//        default :
//            return 34
//        }
//    }
//    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
//        
//        if _currentDataType == DataType.SemesterScore{
//            
//            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("semesterScoreViewCtrl") as! SemesterScoreViewCtrl
//            
//            self.navigationController?.pushViewController(nextView, animated: true)
//        }
//        else if _currentDataType == DataType.ExamScore{
//            
//            let nextView = self.storyboard?.instantiateViewControllerWithIdentifier("examScoreViewCtrl") as! ExamScoreViewCtrl
//            
//            self.navigationController?.pushViewController(nextView, animated: true)
//        }
//    }
//    
//    
//}
//
//struct Absent {
//    var Type:String!
//    var Date:String!
//    var Period:String!
//}
//
//struct Discipline {
//    var Type:DisciplineType!
//    var Date:String!
//    var Reason:String!
//    var MA:Int!
//    var MB:Int!
//    var MC:Int!
//    var DA:Int!
//    var DB:Int!
//    var DC:Int!
//}
//
//struct ExamScore{
//    var SchoolYear: Int!
//    var Semester: Int!
//    var Type: String!
//}
//
//struct SemesterScore{
//    var SchoolYear: Int!
//    var Semester: Int!
//}
//
////enum DisciplineType : Int{
////    case Merit,Demerit
////}

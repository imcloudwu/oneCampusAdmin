//
//  ExamScoreChart.swift
//  oneCampusParent
//
//  Created by Cloud on 11/3/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class ExamScoreChart: UIViewController {
    
    var StudentData : Student!
    var OtherData : DisplayItem!
    
    var IsJH = false
    var IsHS = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        self.navigationItem.title = OtherData.Title
        
        let chartLabel = UILabel(frame: CGRectMake(0, 10, Global.ScreenSize.width, 20.0))
        chartLabel.textAlignment = NSTextAlignment.Center
        chartLabel.text = "班級成績分佈圖"
        
        var datas = GetData()
        
        let dataItem: PDLineChartDataItem = PDLineChartDataItem()
        dataItem.chartLayerColor = UIColor.orangeColor()
        dataItem.xMax = 11.0
        dataItem.xInterval = 1.0
        dataItem.yMax = 30.0
        dataItem.yInterval = 5.0
        dataItem.pointArray = [CGPoint]()
        dataItem.xAxesDegreeTexts = ["9", "19", "29", "39", "49", "59", "69", "79", "89", "99", "100"]
        dataItem.yAxesDegreeTexts = ["5", "10", "15", "20", "25", "30"]
        
        dataItem.pointArray?.append(CGPoint(x: Double(0), y: Double(datas[0]!)))
        
        for x in 0...9{
            dataItem.pointArray?.append(CGPoint(x: Double(x+1), y: Double(datas[x*10 + 9]!)))
        }
        
        dataItem.pointArray?.append(CGPoint(x: Double(11), y: Double(datas[100]!)))
        
        let lineChart: PDLineChart = PDLineChart(frame: CGRectMake(0, 30, Global.ScreenSize.width, Global.ScreenSize.width), dataItem: dataItem)
        
        //lineChart.center = CGPointMake(self.view.frame.width / 2, self.view.frame.height / 2)
        
        let label = UILabel(frame: CGRectMake(0, Global.ScreenSize.width + 30, Global.ScreenSize.width, 20.0))
        label.textAlignment = NSTextAlignment.Center
        
        if let obj = OtherData.OtherObject as? ExamScoreItem{
            label.text = IsHS ? "\(StudentData.Name)的成績 : " + obj.Score : "\(StudentData.Name)的成績 : " + OtherData.Value
        }
        
        self.view.addSubview(chartLabel)
        self.view.addSubview(lineChart)
        self.view.addSubview(label)
        
        lineChart.strokeChart()
        
        //        var dataItem: PDBarChartDataItem = PDBarChartDataItem()
        //        dataItem.xMax = 10
        //        dataItem.xInterval = 1
        //        dataItem.yMax = 20
        //        dataItem.yInterval = 5
        //        //dataItem.barPointArray = [CGPoint(x:1.0,y:100.0),CGPoint(x:9.0,y:90.0)]
        //        dataItem.barPointArray = chartData
        //        dataItem.xAxesDegreeTexts = ["總", "哲", "宗", "自", "應", "社", "歷", "地", "語", "美"]
        //        dataItem.yAxesDegreeTexts = ["5","10","15","20"]
        //
        //        //                let width = cell.contentView.frame.width
        //        //                let swidth = cell.contentView.frame.size.width
        //        //                let height = cell.contentView.frame.height
        //        //                let sheight = cell.contentView.frame.size.height
        //
        //        var barChart: PDBarChart = PDBarChart(frame: CGRectMake(0, -40, ScreenWidth, 200), dataItem: dataItem)
        //
        //        cell.contentView.addSubview(barChart)
        //        barChart.strokeChart()
        //    }
        //    else if self._data[indexPath.row].Type == "health"{
        
        
    }
    
    func GetData() -> [Int:Int]{
        
        var retVal = [Int:Int]()
        
        retVal[0] = 0
        retVal[100] = 0
        
        for i in 0...9{
            retVal[i*10 + 9] = 0
        }
        
        if let obj = OtherData.OtherObject as? ExamScoreItem{
            
            var err : DSFault!
            let con = GetCommonConnect(StudentData.DSNS)
            
            let target = IsJH ? "examScore.GetClassExamScoreJH" : "examScore.GetClassExamScoreSH"
            
            let rsp = con.SendRequest(target, bodyContent: "<Request><ExamId>\(obj.ExamId)</ExamId><CourseId>\(obj.CourseID)</CourseId></Request>", &err)
            
            //print(rsp)
            
            if err != nil{
                return retVal
            }
            
            var nserr : NSError?
            
            let xml: AEXMLDocument?
            do {
                xml = try AEXMLDocument(xmlData: rsp.dataValue)
            } catch _ {
                xml = nil
            }
            
            if nserr != nil{
                return retVal
            }
            
            if let exams = xml?.root["Exam"].all{
                for exam in exams{
                    
                    let score = exam["Score"].stringValue
                    
                    var scoreValue = score.doubleValue
                    
                    if scoreValue.isNaN{
                        scoreValue = 0
                    }
                    
                    if scoreValue >= 100{
                        retVal[100] = retVal[100]! + 1
                    }
                    else if scoreValue <= 0{
                        retVal[0] = retVal[0]! + 1
                    }
                    else{
                        
                        let key = Int(scoreValue / 10)
                        
                        retVal[key*10 + 9] = retVal[key*10 + 9]! + 1
                    }
                }
                
            }
        }
        
        return retVal
    }
    
}

//
//  ChartViewCtrl.swift
//  oneCampusAdmin
//
//  Created by Cloud on 8/14/15.
//  Copyright (c) 2015 ischool. All rights reserved.
//

import UIKit

class ChartViewCtrl: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    var VoteItems : [VoteItem]!
    
    @IBOutlet weak var ChartView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var Colors = [
        UIColor(red: 69.0 / 255, green: 212.0 / 255, blue: 103.0 / 255, alpha: 1.0),
        UIColor(red: 66.0 / 255, green: 187.0 / 255, blue: 102.0 / 255, alpha: 1.0),
        UIColor(red: 64.0 / 255, green: 164.0 / 255, blue: 102.0 / 255, alpha: 1.0),
        UIColor(red: 0.0 / 255, green: 122.0 / 255, blue: 122.0 / 255, alpha: 1.0),
        UIColor(red: 0.0 / 255, green: 148.0 / 255, blue: 148.0 / 255, alpha: 1.0),
        UIColor(red: 0.0 / 255, green: 173.0 / 255, blue: 173.0 / 255, alpha: 1.0),
        UIColor(red: 0.0 / 255, green: 76.0 / 255, blue: 153.0 / 255, alpha: 1.0),
        UIColor(red: 0.0 / 255, green: 89.0 / 255, blue: 179.0 / 255, alpha: 1.0)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationItem.title = "問卷統計"
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        //        dataItem.dataArray = [PieDataItem(description: "first pie", color: lightGreen, percentage: 0.6),
        //            PieDataItem(description: nil, color: middleGreen, percentage: 0.1),
        //            PieDataItem(description: "third pie", color: deepGreen, percentage: 0.6)]
        
        var dataItem: PDPieChartDataItem = PDPieChartDataItem()
        dataItem.pieWidth = 100
        dataItem.pieMargin = 35
        
        var items = [PieDataItem]()
        
        //count total
        var total : Double = 0
        
        for vt in VoteItems{
            total += Double(vt.Value)
        }
        
        //Add percentage item
        var index = 0
        for vt in VoteItems{
            
            let colorIndex = index % 8
            
            if total > 0 {
                
                var percentage : Double = Double(vt.Value) / total
                
                if percentage > 0{
                    items.append(PieDataItem(description: vt.Title, color: Colors[colorIndex], percentage: CGFloat(percentage)))
                }
            }
            else{
                
                var percentage : Double = 1 / Double(VoteItems.count)
                items.append(PieDataItem(description: vt.Title, color: Colors[colorIndex], percentage: CGFloat(percentage)))
            }
            
            index++
        }
        
        dataItem.dataArray = items
        
        var pieChart: PDPieChart = PDPieChart(frame: CGRectMake(0, 0, 320, 320), dataItem: dataItem)
        
        pieChart.center = ChartView.center
        
        self.ChartView.addSubview(pieChart)
        
        pieChart.strokeChart()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return VoteItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("chartCell") as? UITableViewCell
        
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "chartCell")
        }
        
        cell?.textLabel?.text = VoteItems[indexPath.row].Title
        cell?.detailTextLabel?.text = "\(VoteItems[indexPath.row].Value)"
        
        return cell!
    }
    
}

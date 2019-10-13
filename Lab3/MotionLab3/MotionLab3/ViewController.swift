//
//  ViewController.swift
//  MotionLab3
//
//  Created by 梅沈潇 on 10/9/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//  Lab3 Module A

import UIKit
import CoreMotion
import Charts


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pieView: PieChartView!
    
    var todayStep_entry = PieChartDataEntry(value: 0.0)
    var goalStep_entry = PieChartDataEntry(value: 0.0)
    var numberOfDownloaadsDataEntries = [PieChartDataEntry]()
    
    // MARK: =======Set up pie chart=======
    func setupPieChart(){
        pieView.chartDescription?.enabled = false
        pieView.drawHoleEnabled = false
        pieView.rotationAngle = 0
//        pieView.rotationEnabled = true
        pieView.isUserInteractionEnabled = true
        pieView.legend.enabled = false
        todayStep_entry.label = "Today's Step"
        goalStep_entry.label = "Step Goal"
        
        // update data in the chart
        updateChart()
    }
    
    func updateChart(){
        
        // get the step data
        todayStep_entry.value = Double(self.cell_todayStep)
//        goalStep_entry.value = Double(self.stepGoal) - Double(self.cell_todayStep)
        
        if(Double(self.cell_todayStep) >= Double(self.stepGoal)){
            goalStep_entry.value = 0.0
        }else{
            goalStep_entry.value = Double(self.stepGoal) - Double(self.cell_todayStep)
        }
//        self.goalLabel.text = "\(self.cell_todayStep)" + "/" + "\(self.stepGoal)"
        goalStep_entry.label = "Remaining Goal"
        
        
        // set up char dataset
        numberOfDownloaadsDataEntries = [todayStep_entry, goalStep_entry]
        let charDataSet = PieChartDataSet(entries: numberOfDownloaadsDataEntries, label: nil)
        let charData = PieChartData(dataSet: charDataSet)
        
        // set up colors for data entry
        let colors = [#colorLiteral(red: 1, green: 0.08598016948, blue: 0, alpha: 1),#colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)]
        charDataSet.colors = colors
        
        // display value for each data entry
        charDataSet.drawValuesEnabled = true
        
        // set up data for pie chart
        pieView.data = charData
        
        // modify font style and size
        let labeltext = pieView.data
        let attribute = NSUIFont(name: "HelveticaNeue", size: 20.0)
        labeltext?.setValueFont(attribute!)
        labeltext?.setValueTextColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
    }
    
    // MARK: =======Set up table view=======
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        // return number of rows in each section
        return 3
    }
    
    func numberOfSections(in tableView: UITableView) -> Int{  // Default is 1 if not implemented
        // return number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        // when a row is selected, make it unselected immediately
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        //Returns a reusable table-view cell object located by its identifier.
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell1") as! TodayTableViewCell
        
        // bring the todayStep label above the background imageView
        self.view.bringSubviewToFront(cell.todayStep)
        
        // set cell style for each row
        if(indexPath.row==0){
            cell.todayStep.text = "Today's step: " + String(self.cell_todayStep)
            
            // make the text label above the image
            cell.todayStep.layer.zPosition = 1
            
            // change the background color
            cell.todayImage.backgroundColor = #colorLiteral(red: 0.5204460025, green: 0.8825983405, blue: 0.9786363244, alpha: 1)
            
        }else if(indexPath.row==1){
            cell.todayStep.text = "Yesterday's step: " + String(self.cell_yesterdayStep)
            
            // make the text label above the image
            cell.todayStep.layer.zPosition = 1
            
            // change the background color
            cell.todayImage.backgroundColor = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
        }else if(indexPath.row==2){
            cell.todayStep.text = "You are " + self.cell_state + " now"
            
            // make the text label above the image
            cell.todayStep.layer.zPosition = 1
            
            // change the background color
            switch(self.cell_state){
            case "Walking":
                cell.todayImage.backgroundColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
                break
            case "Running":
                cell.todayImage.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
                break
            case "Cycling":
                cell.todayImage.backgroundColor = #colorLiteral(red: 0.9928941131, green: 0.5036882162, blue: 0.9914329648, alpha: 1)
                break
            case "Unknown":
                cell.todayImage.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
                break
            case "Automotive":
                cell.todayImage.backgroundColor = #colorLiteral(red: 1, green: 0.08598016948, blue: 0, alpha: 1)
                break
            case "Stationary":
                cell.todayImage.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                break
            default:
                break
            }
            
        }
        return cell;
    }
    

    let defaults = UserDefaults.standard
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    var stepGoal = UserDefaults.standard.float(forKey: "stepGoal")
    var todayCount=0
    var todayCombineCount=0
    var cell_yesterdayStep=0
    var cell_todayStep=0
    var cell_state: String! = ""
    
    @IBOutlet weak var goalSlider: UISlider!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var todayStepCounter: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var yesterdayStepCounter: UILabel!
    
    // MARK: ======UI Lifecycle Methods======
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize slider value
//        print(self.goalSlider)
        self.goalSlider.setValue(self.stepGoal, animated: true)
        
        // initialize step data
        checkStep()
        
        // start monitoring activity
        startActivityMonitoring()
        if CMPedometer.isStepCountingAvailable() {
            startCountingSteps()
        }
        
        // initialize the chart
        setupPieChart()
        
    }
    
    // MARK: ======Motion Methods======
    func startActivityMonitoring(){
        if CMMotionActivityManager.isActivityAvailable(){
            self.activityManager.startActivityUpdates(to: OperationQueue.main)
            {(activity:CMMotionActivity?)->Void in
                if let unwrappedActivity = activity {
                    if(unwrappedActivity.walking){
                        self.cell_state = "Walking"
                    }
                    else if(unwrappedActivity.running){
                        self.cell_state = "Running"
                    }
                    else if(unwrappedActivity.cycling){
                        self.cell_state = "Cycling"
                    }
                    else if(unwrappedActivity.automotive){
                        self.cell_state = "Automotive"
                    }
                    else if(unwrappedActivity.stationary){
                        self.cell_state = "Stationary"
                    }
                    else{
                        self.cell_state = "Unknown"
                    }
                }
            }
        }
    }

    func checkStep(){
        let date = Date();
        if CMPedometer.isStepCountingAvailable() {
            let calendar = Calendar.current
            
            // get step of today
            pedometer.queryPedometerData(from: calendar.startOfDay(for: Date()), to: Date()) { (data, error) in
                DispatchQueue.main.async {
                    var todayStep = "Today's Step: ";
                    self.todayCount=(data?.numberOfSteps.intValue)!
                    var stepNow = self.todayCount
                    if(self.todayCount>Int(self.goalSlider.value)){
                        stepNow = Int(self.goalSlider.value)
                    }
                    self.goalLabel.text = "\(stepNow)/\(Int(self.goalSlider.value))"
                    todayStep += (data?.numberOfSteps.stringValue)!
                    
                    // update display variable of table view cell
                    self.cell_todayStep = (data?.numberOfSteps.intValue)!
                    
                    // update the combine count
                    self.todayCombineCount = self.todayCount
                    
                }
            }
            var dateComponents = DateComponents()
            dateComponents.setValue(-1, for: .day) // -1 day
            let yesterday = Calendar.current.date(byAdding: dateComponents, to: date)
            
            // get step of yesterday
            pedometer.queryPedometerData(from: calendar.startOfDay(for: yesterday!), to: calendar.startOfDay(for: Date())) { (data, error) in
                DispatchQueue.main.async {
                    var todayStep = "Yesterday's Step: ";
                    todayStep += (data?.numberOfSteps.stringValue)!
                    
                    // update tableview cell variable
                    self.cell_yesterdayStep = (data?.numberOfSteps.intValue)!
                    
                    // update tableview
                    self.tableView.reloadData()
                    
                    // update the chart
                    self.updateChart()
                }
            }
        }
        
    }

    func startCountingSteps() {
        pedometer.startUpdates(from: Date()) {
            [weak self] pedometerData, error in
            guard let pedometerData = pedometerData, error == nil else { return }
            
            DispatchQueue.main.async {
                var todayStep = "Today's Step: "
                
                // get today step count
                let combineStep = pedometerData.numberOfSteps.intValue+self!.todayCount
                todayStep += String(combineStep)
                
                // update goal label
                self?.goalLabel.text = "\(combineStep)/\(Int(self!.stepGoal))"
                print(pedometerData.numberOfSteps.stringValue)
                
                self?.todayCombineCount = combineStep
                
                // display in the cell
                self!.cell_todayStep = combineStep
                
                // reload table view data
                self!.tableView.reloadData()
                
                // update the pie chart data
                self!.updateChart()
                
            }
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        
        let currentValue = Int(sender.value)
        var stepNow = self.todayCombineCount
        NSLog("step Now/today count: \(stepNow)")
        
        // if we have reached the current goal, make them the same value
        if(self.todayCombineCount>currentValue){
            stepNow = currentValue
            self.cell_todayStep = currentValue;
            self.stepGoal = Float(currentValue);
        }
        
        defaults.set(currentValue, forKey: "stepGoal")
        self.stepGoal=Float(currentValue)
        
        // update tableview
        updateChart();
        goalLabel.text = "\(stepNow)/\(currentValue)"
    }
}


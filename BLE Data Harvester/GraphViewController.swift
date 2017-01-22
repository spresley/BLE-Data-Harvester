//
//  GraphViewController.swift
//  Pods
//
//  Created by Sam Presley on 23/12/2016.
//
//

import UIKit
import Charts

var pickerEntry: [String] = [String]()

class GraphViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    
    @IBOutlet var activityLevelLabel: UILabel!
    
    @IBOutlet var lightLevelLabel: UILabel!
    @IBOutlet var lineView: LineChartView!
    
    weak var axisFormatDelegate: IAxisValueFormatter?

    @IBOutlet var segmentControl: UISegmentedControl!
    
    @IBOutlet var devicePicker: UIPickerView!
    
    @IBAction func pickNode(_ sender: Any) {
        devicePicker.reloadAllComponents()
        if(devicePicker.isHidden==false){
            devicePicker.isHidden = true
            
            updateGraph(timeWindow: segmentControl.selectedSegmentIndex , selected_node: selectedNode.text!)
        } else {
            devicePicker.isHidden = false
        }
    }
    @IBOutlet var selectedNode: UILabel!
    
    //Requests data from the DB for the chosen data range and plots on graph
    
    @IBAction func segmentControlAction(_ sender: Any) {
        updateGraph(timeWindow: segmentControl.selectedSegmentIndex , selected_node: selectedNode.text!)
    
    }
    func updateGraph(timeWindow: Int, selected_node: String){
        let today = Date()
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        var components = calendar.components([.year, .month, .day, .hour, .minute, .second], from: today)
        components.hour = 0
        components.minute = 0
        components.second = 0
        //let today_start = calendar.date(from: components)
        //let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        let lastweek = Calendar.current.date(byAdding: .day, value: -7, to: today)
        let lastmonth = Calendar.current.date(byAdding: .month, value: -1, to: today)
        let lasthour = Calendar.current.date(byAdding: .hour, value: -1, to: today)
        
        let historicDataObj = HistoricData()
        if timeWindow==0{ //month
            historicDataObj.requestDataFromDB_byDate(startDate: (lastmonth?.iso8601)!, endDate: today.iso8601, selected_node: selected_node, completion: {
                self.printHistDataObj(historicDataObj: historicDataObj)
                self.dataDidParse(historicDataObj: historicDataObj, timeWindow: timeWindow)
            })
        }
        if timeWindow==1{ //week
            historicDataObj.requestDataFromDB_byDate(startDate: (lastweek?.iso8601)!, endDate: today.iso8601, selected_node: selected_node, completion: {
                self.printHistDataObj(historicDataObj: historicDataObj)
                self.dataDidParse(historicDataObj: historicDataObj, timeWindow: timeWindow)
            })
        }
        if timeWindow==2{ //day
            historicDataObj.requestDataFromDB_byDate(startDate: (yesterday?.iso8601)!, endDate: today.iso8601, selected_node: selected_node, completion: {
                self.printHistDataObj(historicDataObj: historicDataObj)
                self.dataDidParse(historicDataObj: historicDataObj, timeWindow: timeWindow)
            })
        }
        if timeWindow==3{//hour
            historicDataObj.requestDataFromDB_byDate(startDate: (lasthour?.iso8601)!, endDate: today.iso8601, selected_node: selected_node, completion: {
                self.printHistDataObj(historicDataObj: historicDataObj)
                self.dataDidParse(historicDataObj: historicDataObj, timeWindow: timeWindow)
            })
        }
    }
    
    func printHistDataObj(historicDataObj: HistoricData){
        for datapoint in historicDataObj.sensorData{
            print("node_id: \(datapoint.node_id), time_stamp: \(datapoint.time_stamp), activity_level: \(datapoint.activity_level), light_level: \(datapoint.light_level)")
        }
    }
    
    func dataDidParse(historicDataObj : HistoricData, timeWindow: Int){
        
        print("Data parsed")
        let numDataPoints: Int = historicDataObj.sensorData.count
        print("numDataPoints:\(numDataPoints)")
        
        if(numDataPoints > 0){
            let sensorData = historicDataObj.sensorData
            
            struct dataStruct{
                var time_stamp: Double
                var activity_level: Double
                var light_level: Double
                
            }
            var i : Int = 1
            var lightDataEntries: [ChartDataEntry] = []
            var activityDataEntries: [ChartDataEntry] = []
            
            for entry in sensorData{
                let timestamp : Date = entry.time_stamp.dateFromISO8601!
                let lightDataEntry = ChartDataEntry(x: Double(timestamp.timeIntervalSince1970), y: Double(entry.light_level))
                lightDataEntries.append(lightDataEntry)
                let activityDataEntry = ChartDataEntry(x: Double(timestamp.timeIntervalSince1970), y: Double(entry.activity_level))
                activityDataEntries.append(activityDataEntry)
                i += 1
            }
            
            let lightDataSet = LineChartDataSet(values: lightDataEntries, label: "Light level")
            lightDataSet.drawCirclesEnabled = false
            lightDataSet.mode = LineChartDataSet.Mode.horizontalBezier
            lightDataSet.lineWidth = 2
            
            let activityDataSet = LineChartDataSet(values: activityDataEntries, label: "Activity level")
            activityDataSet.drawCirclesEnabled = false
            activityDataSet.mode = LineChartDataSet.Mode.horizontalBezier
            activityDataSet.setColor(UIColor.red)
            activityDataSet.axisDependency = .right
            activityDataSet.lineWidth = 2
            
            let chartData = LineChartData(dataSets: [activityDataSet, lightDataSet])
            lineView.data = chartData
            lineView.data?.setDrawValues(false)
            
            let xaxis = lineView.xAxis
            xaxis.valueFormatter = axisFormatDelegate
            xaxis.labelPosition = XAxis.LabelPosition.bottom
            
            xaxis.axisMaximum = Double(Date().timeIntervalSince1970)
            

            let today = Date()
            let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            var components = calendar.components([.year, .month, .day, .hour, .minute, .second], from: today)
            
            components.minute = 0
            components.second = 0
            
            let last_hour = calendar.date(from: components)
            let end_hour = Calendar.current.date(byAdding: .hour, value: 1, to: last_hour!)
            
            components.hour = 0

            let today_start = calendar.date(from: components)
            let today_end = Calendar.current.date(byAdding: .day, value: 1, to: today_start!)
            let last_month = Calendar.current.date(byAdding: .month, value: -1, to: today_end!)
            let last_week = Calendar.current.date(byAdding: .day, value: -7, to: today_end!)
            xaxis.granularity = 59
            
            switch timeWindow {
            case 0://month
                xaxis.axisMinimum = Double((last_month?.timeIntervalSince1970)!)
                xaxis.axisMaximum = Double((today_end?.timeIntervalSince1970)!)
            case 1://week
                xaxis.axisMinimum = Double((last_week?.timeIntervalSince1970)!)
                xaxis.axisMaximum = Double((today_end?.timeIntervalSince1970)!)
            case 2://day
                xaxis.axisMinimum = Double((today_start?.timeIntervalSince1970)!)
                xaxis.axisMaximum = Double((today_end?.timeIntervalSince1970)!)
            case 3://hour
                xaxis.axisMinimum = Double((last_hour?.timeIntervalSince1970)!)
                xaxis.axisMaximum = Double((end_hour?.timeIntervalSince1970)!)
            default:
                print("Error default switch statement reached")
            }
            
            lineView.leftAxis.axisMinimum = 0
            lineView.rightAxis.axisMinimum = 0
            
            lineView.chartDescription?.enabled = false
            lineView.xAxis.drawGridLinesEnabled = false
            lineView.leftAxis.drawGridLinesEnabled = false
            lineView.rightAxis.drawGridLinesEnabled = false
            lineView.leftAxis.axisMaximum = 3100
            lineView.rightAxis.axisMaximum = 105
            
            lineView.scaleYEnabled = false
            lineView.drawMarkers = false

            lineView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
            
        }else{
            lineView.clear()
            lineView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
            print("No data returned")
        }

    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Graph view loaded")
        axisFormatDelegate = self
        
        self.devicePicker.delegate = self
        self.devicePicker.dataSource = self
        
        self.activityLevelLabel.transform = CGAffineTransform(rotationAngle:  CGFloat.pi / 2);
        self.lightLevelLabel.transform = CGAffineTransform(rotationAngle:  -CGFloat.pi / 2);
        
        pickerEntry = ["All"]
        devicePicker.isHidden = true
    
        // Do any additional setup after loading the view.
        let historicDataObj = HistoricData()
        historicDataObj.requestDataFromDB_byDate(startDate: "2000", endDate: "2019",  selected_node: "All", completion: {
            print("finished loading from DB")
            
            for datapoint in historicDataObj.sensorData{
                print("node_id: \(datapoint.node_id), time_stamp: \(datapoint.time_stamp), activity_level: \(datapoint.activity_level), light_level: \(datapoint.light_level)")
            }
            self.dataDidParse(historicDataObj: historicDataObj, timeWindow: 0)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // The number of columns of data
    func numberOfComponents (in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerEntry.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerEntry[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        print("picker changed")
        selectedNode.text = pickerEntry[row]
    }

    
    
    //Picker view tut: http://codewithchris.com/uipickerview-example/
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

struct sensorDataPoint{
    let time_stamp: String
    let activity_level: Int
    let light_level: Int
    let node_id: String
    
    init(time_stamp: String, activity_level: Int, light_level: Int, node_id: String){
        self.time_stamp = time_stamp
        self.activity_level = activity_level
        self.light_level = light_level
        self.node_id = node_id
    }
}

class HistoricData{
    
    var sensorData: [sensorDataPoint] = []
    
    init(){
    }
    
    func addDataPoint(sensorData: [sensorDataPoint]){
        for datapoint in sensorData {
            self.sensorData.append(datapoint)
            print("added")
        }
    }
    
    func requestDataFromDB_byDate(startDate: String, endDate: String, selected_node: String, completion: @escaping () -> Void ){
        
        // Do any additional setup after loading the view.
        
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "APIkeys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        let keysdict = keys
        
        let cloudantUsername = keysdict?["cloudant-username"] as! String
        let cloudantPassword = keysdict?["cloudant-password"] as! String
        
        let url = URL(string: ("https://" + cloudantUsername + ":" + cloudantPassword + "@f810fc6b-39be-4c4c-9716-47f93c071d09-bluemix.cloudant.com/test-data/_design/design_doc/_view/by-date-minimised?reduce=false&inclusive_end=true&start_key=%22" + startDate + "%22&end_key=%22" + endDate + "%22"))!
        print(url)
        
        let task = URLSession.shared.dataTask(with: url){(data, response, error) in
            if error != nil{
                print("error")
            } else{
                if let urlContent = data{
                    do{
                        let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options:[])
                        //print(jsonResult)
                        
                        if let dictionary = jsonResult as? [String: AnyObject] {
                            if let total_rows = dictionary["total_rows"] as? Int {
                                // access individual value in dictionary
                                print(total_rows)
                            }
                            if let rows = dictionary["rows"]{
                                for (row) in rows as! [AnyObject] {
                                    if let value = row["value"] as? [String: AnyObject]{
                                        //print(value)
                                        guard let time_stamp = value["time_stamp"] as? String else {
                                            return
                                        }
                                        //print(time_stamp)
                                        
                                        guard let activity_level = value["activity_level"] as? Int else {
                                            return
                                        }
                                        //print(activity_level)
                                        
                                        guard let light_level = value["light_level"] as? Int else {
                                            return
                                        }
                                        
                                        var node_id = ""
                                        
                                        if (value["node_id"] != nil){
                                            node_id = value["node_id"] as! String
                                            
                                            if (node_id == selected_node){
                                                //Add data to array here
                                                let datapoint: sensorDataPoint = sensorDataPoint(time_stamp: time_stamp, activity_level: activity_level, light_level: light_level, node_id: node_id)
                                                
                                                self.addDataPoint(sensorData: [datapoint]);
                                            }
                                            if (selected_node == "All"){
                                                //Add data to array here
                                                let datapoint: sensorDataPoint = sensorDataPoint(time_stamp: time_stamp, activity_level: activity_level, light_level: light_level, node_id: node_id)
                                                
                                                self.addDataPoint(sensorData: [datapoint]);
                                                
                                            }
                                        } else{
                                            node_id = "empty"
                                        }

                                        if(!pickerEntry.contains(node_id)){
                                            pickerEntry.append(node_id)
                                        }
                                        
                                    }
                                }
                            }
                        }
                        
                    }
                    catch{
                        print("Json processing failed")
                    }
                }
                print("finished parsing data into objects")
                completion()
            }
        }
        task.resume()
    }
}

// MARK: axisFormatDelegate
// Provides dynamic restructuring of the x-axis labels and granularity of labels 
// TODO: Refactor as a more elegant solution
extension GraphViewController: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        
        
        let dateFormatter = DateFormatter()
        
        //let axisRange = (axis?.axisMaximum)! - (axis?.axisMinimum)!
        let axisRange = lineView.highestVisibleX - lineView.lowestVisibleX
        
        print("axisRange \(axisRange)")

        axis?.setLabelCount(5, force: false)

        dateFormatter.dateFormat = "HH:mm"

        if(axisRange<5*60){ //4 minute
            axis?.granularity = Double(60)//60 seconds
        }else{
            if(axisRange<8*60){ //8 minutes
                axis?.granularity = Double(2*60)//2 minutes
            }else{
                if(axisRange<30*60){ //30 minutes
                    axis?.granularity = Double(5*60)//5 minutes
                }else{
                    if(axisRange<50*60){ //50 minutes
                        axis?.granularity = Double(10*60)//10 minutes
                    }else{
                        if(axisRange<60*60){ //1 hour
                            axis?.granularity = Double(20*60)//20 minutes
                        }else{
                            if(axisRange<(2*60*60)){ //2 hours
                                axis?.granularity = Double(60*30)//30 minutes
                            }else{
                                if(axisRange<4*60*60){ //4 hours
                                    axis?.granularity = Double(1*60*60)//1 hour
                                }else{
                                    if(axisRange<6*60*60){ //6 hours
                                        axis?.granularity = Double(1*60*60)//2 hour
                                    }else{
                                        if(axisRange<12*60*60){ //12 hours
                                            axis?.granularity = Double(3*60*60)//3 hour
                                        }else{
                                            dateFormatter.dateFormat = "EEE HH:mm"
                                            if(axisRange<24*60*60){ //24 hours
                                                axis?.granularity = Double(4*60*60)//4 hour
                                            }else{
                                                dateFormatter.dateFormat = "EEE-dd"
                                                if(axisRange<3*24*60*60){ //3 days
                                                    axis?.granularity = Double(6*60*60)//6 hour
                                                }else{
                                                    if(axisRange<7*24*60*60){ //7 days
                                                        axis?.granularity = Double(24*60*60)//1 day
                                                    }else{
                                                       dateFormatter.dateFormat = "dd-MMM"
                                                        if(axisRange<20*24*60*60){ //20 days
                                                            axis?.granularity = Double(24*60*60)//1 day
                                                        }else{
                                                            if(axisRange<31*24*60*60){ //31 days
                                                                axis?.granularity = Double(7*24*60*60)//1 week
                                                            }else{
                                                                axis?.granularity = Double(7*24*60*60)//1 week
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        print("Granularity:\(axis?.granularity)")

        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}



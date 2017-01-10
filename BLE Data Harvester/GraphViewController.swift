//
//  GraphViewController.swift
//  Pods
//
//  Created by Sam Presley on 23/12/2016.
//
//

import UIKit
import Charts

class GraphViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    
    @IBOutlet var lineView: LineChartView!
    weak var axisFormatDelegate: IAxisValueFormatter?

    @IBOutlet var segmentControl: UISegmentedControl!
    
    @IBOutlet var devicePicker: UIPickerView!
    var pickerEntry: [String] = [String]()
    
    @IBAction func pickNode(_ sender: Any) {
        if(devicePicker.isHidden==false){
            devicePicker.isHidden = true
        } else {
            devicePicker.isHidden = false
        }
    }
    
    //Requests data from the DB for the chosen data range and plots on graph
    
    @IBAction func segmentControlAction(_ sender: Any) {
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
        let lastminute = Calendar.current.date(byAdding: .minute, value: -1, to: today)
        
        if segmentControl.selectedSegmentIndex == 0{ //Month
            let historicDataObj = HistoricData()
            historicDataObj.requestDataFromDB_byDate(startDate: (lastmonth?.iso8601)!, endDate: today.iso8601, completion: {
                print("finished loading from DB")
                
                for datapoint in historicDataObj.sensorData{
                    print("node_id: \(datapoint.node_id), time_stamp: \(datapoint.time_stamp), activity_level: \(datapoint.activity_level), light_level: \(datapoint.light_level)")
                }
                self.dataDidParse(historicDataObj: historicDataObj)
            })
        }
        if segmentControl.selectedSegmentIndex == 1{ //Week
            let historicDataObj = HistoricData()
            historicDataObj.requestDataFromDB_byDate(startDate: (lastweek?.iso8601)!, endDate: today.iso8601, completion: {
                print("finished loading from DB")
                
                for datapoint in historicDataObj.sensorData{
                    print("node_id: \(datapoint.node_id), time_stamp: \(datapoint.time_stamp), activity_level: \(datapoint.activity_level), light_level: \(datapoint.light_level)")
                }
                self.dataDidParse(historicDataObj: historicDataObj)
            })
        
        }
        if segmentControl.selectedSegmentIndex == 2{ //Day
            let historicDataObj = HistoricData()
            historicDataObj.requestDataFromDB_byDate(startDate: (yesterday?.iso8601)!, endDate: today.iso8601, completion: {
                print("finished loading from DB")
                
                for datapoint in historicDataObj.sensorData{
                    print("node_id: \(datapoint.node_id), time_stamp: \(datapoint.time_stamp), activity_level: \(datapoint.activity_level), light_level: \(datapoint.light_level)")
                }
                self.dataDidParse(historicDataObj: historicDataObj)
            })
        }
        if segmentControl.selectedSegmentIndex == 3{ //Hour
            let historicDataObj = HistoricData()
            historicDataObj.requestDataFromDB_byDate(startDate: (lasthour?.iso8601)!, endDate: today.iso8601, completion: {
                print("finished loading from DB")
                
                for datapoint in historicDataObj.sensorData{
                    print("node_id: \(datapoint.node_id), time_stamp: \(datapoint.time_stamp), activity_level: \(datapoint.activity_level), light_level: \(datapoint.light_level)")
                }
                self.dataDidParse(historicDataObj: historicDataObj)
            })
        }
    }
    
    func dataDidParse(historicDataObj : HistoricData){
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
            
            let xaxis = lineView.xAxis
            xaxis.valueFormatter = axisFormatDelegate
            xaxis.setLabelCount(5, force: false)
            xaxis.granularity = 59
            xaxis.labelPosition = XAxis.LabelPosition.bottom
            
            //lineView.setVisibleXRangeMaximum(10)
            
            lineView.leftAxis.axisMinimum = 0
            lineView.rightAxis.axisMinimum = 0
            //lineView.rightAxis.enabled = false
            
            lineView.chartDescription?.enabled=false
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
        
        pickerEntry = ["Node 1", "Node 2", "Node 3", "Node  4", "Node 5", "Node 6"]
//        devicePicker.setValue(UIColor.white, forKey: "textColor")
//        devicePicker.setValue(UIColor.black, forKey: "backgroundColor")
        devicePicker.isHidden = true
    
        // Do any additional setup after loading the view.
        let historicDataObj = HistoricData()
        historicDataObj.requestDataFromDB(completion: {
            print("finished loading from DB")
            
            for datapoint in historicDataObj.sensorData{
                print("node_id: \(datapoint.node_id), time_stamp: \(datapoint.time_stamp), activity_level: \(datapoint.activity_level), light_level: \(datapoint.light_level)")
            }
            self.dataDidParse(historicDataObj: historicDataObj)
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
        //pickerView.isHidden = true
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
    
    func requestDataFromDB(completion: @escaping () -> Void ){
        
        // Do any additional setup after loading the view.
        
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "APIkeys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        let keysdict = keys
        
        let cloudantUsername = keysdict?["cloudant-username"] as! String
        let cloudantPassword = keysdict?["cloudant-password"] as! String
        
        let url = URL(string: ("https://" + cloudantUsername + ":" + cloudantPassword + "@f810fc6b-39be-4c4c-9716-47f93c071d09-bluemix.cloudant.com/test-data/_design/design_doc/_view/by-date-minimised"))!
        
        
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
                                        //print(light_level)
//                                        guard let node_id = value["node_id"] as? String else {
//                                            return
//                                        }

                                        var node_id = ""
                                    
                                        if (value["node_id"] != nil){
                                            node_id = value["node_id"] as! String
                                        } else{
                                            node_id = "empty"
                                        }

                                        //Add data to array here
                                        let datapoint: sensorDataPoint = sensorDataPoint(time_stamp: time_stamp, activity_level: activity_level, light_level: light_level, node_id: node_id)

                                        self.addDataPoint(sensorData: [datapoint]);
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
    func requestDataFromDB_byDate(startDate: String, endDate: String, completion: @escaping () -> Void ){
        
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
                                        } else{
                                            node_id = "empty"
                                        }

                                        //Add data to array here
                                        let datapoint: sensorDataPoint = sensorDataPoint(time_stamp: time_stamp, activity_level: activity_level, light_level: light_level, node_id: node_id)
                                        
                                        self.addDataPoint(sensorData: [datapoint]);
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

        //json query
        //pass json to parser
}




// MARK: axisFormatDelegate
extension GraphViewController: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE HH:mm"
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}


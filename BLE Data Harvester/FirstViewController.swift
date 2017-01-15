//
//  FirstViewController.swift
//  BLE Data Harvester
//
//  Created by Sam Presley on 02/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData

class FirstViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var sharedInstance = MQTTmanager.sharedInstance
    
    @IBAction func testButton(_ sender: Any) {
        if isConnected == 1{
            sharedInstance.sendRoomMonitorMessage(activity_level: 0, light_level: 0, time_stamp: Date(), node_id: "test node") // Call this function for each message needing to be sent
        }else {
            print("not connected")
        }
    }

    // MARK: Properties
    @IBOutlet weak var activityLevelLabel: UILabel!
    @IBOutlet weak var lightLevelLabel: UILabel!
    //@IBOutlet weak var sensorTable: UITableView!
    
    
    // MARK: Status Indicators

    @IBOutlet weak var FoundSensorStatus: UILabel!
    @IBOutlet weak var DiscoveredServicesStatus: UILabel!
    @IBOutlet weak var HistoricalDataStatus: UILabel!
    @IBOutlet weak var LiveDataStatus: UILabel!
    @IBOutlet weak var SentToBlueMixStatus: UILabel!
    @IBOutlet weak var DisconnectedStatus: UILabel!
    @IBOutlet weak var ScanningStatus: UILabel!
    @IBOutlet weak var ScanningIndicator: UIActivityIndicatorView!
    @IBOutlet weak var FoundSensorLabel: UILabel!
    
    @IBOutlet weak var FoundSensorColour: UIView!
    @IBOutlet weak var DiscoveredServicesColour: UIView!
    @IBOutlet weak var GatheringHistDataColour: UIView!
    @IBOutlet weak var GatheringLiveDataColour: UIView!
    @IBOutlet weak var BluemixColour: UIView!
    @IBOutlet weak var DisconnectedColour: UIView!
    @IBOutlet var MainView: UIView!
    
    // MARK: Debugging Flags
    let debugHistoricalData = false
    let usePersistance = true
    
    // MARK: scanning parameters
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    var keepScanning = false
    var pauseScanFlag = false
    var resumeScanFlag = false
    var timer = Timer()
    let servicesArray:[CBUUID] = [CBUUID(string: Device.RoomMonitorServiceUUID)]
    
    var centralManager:CBCentralManager!
    var sensorTag:CBPeripheral?
    var lightLevelCharacteristic:CBCharacteristic?
    var activityStateCharacteristic:CBCharacteristic?
    let sensorTagName = "ROOM"
    
    var gotLight:Bool = false
    var gotActivity:Bool = false
    var rawActivityLevel:UInt16 = 0
    var rawLightLevel:UInt16 = 0
    
    var gotHistoricalActivity:Bool = false
    var gotHistoricalLight:Bool = false
    var gotHistoricalTime:Bool = false
    var rawHistoricalActivityLevel:UInt16 = 0
    var rawHistoricalLightLevel:UInt16 = 0
    var rawHistoricalTime:UInt16 = 0
    var currentSensorName:String = "something has gone wrong"
    
    // MARK: Historical data collection
    struct historicalData {
        var historicalActivityLevel:UInt16
        var historicalLightLevel:UInt16
        var relativeTimeHistoricalMeasurement:UInt16
        var actualTimeHistoricalMeasurement:Date
    }
    var maximumRelativeTime:UInt16 = 0
    
    var historicalDataTable = [historicalData]()
    var collectingHistoricalData:Bool = false
    var currentHistoricalData = historicalData(historicalActivityLevel: 0, historicalLightLevel: 0, relativeTimeHistoricalMeasurement: 0, actualTimeHistoricalMeasurement: Date())
    
    var histTimeCharRef:CBCharacteristic?
    var histActivityCharRef:CBCharacteristic?
    var histLightCharRef:CBCharacteristic?
    var historicalFirstPass:Bool = false
    
    // MARK: connection history parameters
    let gatherDataInterval:TimeInterval = 30.0
    struct roomSensorNode {
        var UUID:String
        var lastConnectionTime:Date
    }
    var currentPeripheral:roomSensorNode?
    var removedDuplicates = false
    var connectionHistory = [roomSensorNode]()
    var persistantConnectionHistory = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Node Finder"
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        MainView.backgroundColor = UIColorFromRGB(rgbValue: 0xD0D0D0)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.FoundSensorColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
            self.DiscoveredServicesColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
            self.GatheringHistDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
            self.GatheringLiveDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
            self.BluemixColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
            self.DisconnectedColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
            self.FoundSensorColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RoomSensor")
        ScanningIndicator.hidesWhenStopped = true
        ScanningStatus.text = ""
        do {
            let results = try managedContext.fetch(fetchRequest)
            persistantConnectionHistory = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var showAlert = true
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            message = "The state of the BLE Manager is unknown."
        case .poweredOn:
            showAlert = false
            message = "Bluetooth LE is turned on and ready for communication."
            
            print(message)
            keepScanning = true
            resumeScan()
        }
        
        if showAlert {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName.contains(sensorTagName) {
            //if peripheralName == sensorTagName {
                print("SENSOR TAG FOUND! ADDING NOW!!!")
                
                let currentTime = Date()
                var foundInHistory = false
                
                // to save power, stop scanning for other devices
                keepScanning = false
                
                // Check if sensorNode has been scanned recently (non persistant)
                if (usePersistance == false){
                    for index in 0..<connectionHistory.count {
                        if connectionHistory[index].UUID == peripheral.identifier.uuidString {
                            print("Found peripheral in connection history")
                            print("Checking last connection time")
                            foundInHistory = true
                            let connectionTime = connectionHistory[index].lastConnectionTime
                            let timeoutTime = connectionTime.addingTimeInterval(gatherDataInterval)
                            if currentTime.compare(timeoutTime) == ComparisonResult.orderedDescending {
                                print("Current time is later than timeout time. Can collect data again")
                                // save a reference to the sensor tag
                                sensorTag = peripheral
                                sensorTag!.delegate = self
                                
                                // Request a connection to the peripheral
                                centralManager.connect(sensorTag!, options: nil)
                                
                                // Update peripheral in to connection history
                                
                                let thisPeripheral = roomSensorNode(UUID: peripheral.identifier.uuidString, lastConnectionTime: currentTime)
                                connectionHistory.append(thisPeripheral)
                                //self.saveSensor(uuid: peripheral.identifier.uuidString, lastConnectionTime: currentTime)
                                connectionHistory.remove(at: index)
                                //connectionHistoryWritable = connectionHistory as NSArray
                                //connectionHistoryWritable.write(toFile: "storedConnectionHistory.txt", atomically: true)
                            } else {
                                print("Have scanned this peripheral recently. Ignore.")
                                keepScanning = true
                            }
                        }
                    }
                    
                    if foundInHistory == false {
                        print("DIDN'T find peripheral in connection history")
                        // save a reference to the sensor tag
                        sensorTag = peripheral
                        sensorTag!.delegate = self
                        
                        // Request a connection to the peripheral
                        centralManager.connect(sensorTag!, options: nil)
                        currentSensorName = peripheral.identifier.uuidString
                        
                        // Put peripheral in to connection history
                        
                        let thisPeripheral = roomSensorNode(UUID: peripheral.identifier.uuidString, lastConnectionTime: currentTime)
                        currentPeripheral = roomSensorNode(UUID: peripheral.identifier.uuidString, lastConnectionTime: currentTime)
                        connectionHistory.append(thisPeripheral)
                    }
                }
                
                if (usePersistance){
                    // Check if sensorNode has been scanned recently (persistant)
                    if (findSensor(testuuid: peripheral.identifier.uuidString)) {
                        print("Have scanned this peripheral recently. Ignore.")
                        keepScanning = true
                    } else {
                        print("DIDN'T find peripheral in connection history")
                        saveSensor(uuid: peripheral.identifier.uuidString, lastConnectionTime: currentTime)
                        //self.sensorTable.reloadData()
                        // save a reference to the sensor tag
                        sensorTag = peripheral
                        sensorTag!.delegate = self
                    
                        // Request a connection to the peripheral
                        centralManager.connect(sensorTag!, options: nil)
                        currentSensorName = peripheral.identifier.uuidString
                        
                    }
                }
            }
        }
    }
    
    func pauseScan() {
        // Scanning uses up battery on phone, so pause the scan process for the designated interval.
        print("*** PAUSING SCAN")
        timer = Timer.scheduledTimer(timeInterval: timerPauseInterval, target:self, selector: #selector(FirstViewController.resumeScan), userInfo: nil, repeats: false)
        ScanningIndicator.stopAnimating()
        ScanningStatus.text = " "
        centralManager.stopScan()
    }
    
    func resumeScan() {
        if keepScanning {
            // Start scanning again
            print("*** RESUMING SCAN!")
            UIView.animate(withDuration: 0.5, animations: {
                self.FoundSensorColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
                self.DiscoveredServicesColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
                self.GatheringHistDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
                self.GatheringLiveDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
                self.BluemixColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
                self.DisconnectedColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
                self.FoundSensorColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xD0D0D0)
            })
            timer = Timer.scheduledTimer(timeInterval: timerScanInterval, target:self, selector: #selector(FirstViewController.pauseScan), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            ScanningIndicator.startAnimating()
            ScanningStatus.text = "Scanning"
            //centralManager.scanForPeripherals(withServices: [CBUUID(string: "2A19")], options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!")
        UIView.animate(withDuration: 0.5, animations: {
            self.FoundSensorColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
        })
        
        UIView.animate(withDuration: 0.5, animations: {
            self.DisconnectedColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xC84240)
        })
        peripheral.discoverServices(nil) // nil = discover all services
    }
   
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("**** CONNECTION TO SENSOR TAG FAILED!!!")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if (usePersistance == false){
            connectionHistory.append(currentPeripheral!)
        }
        
        print("**** DISCONNECTED FROM SENSOR TAG")
        UIView.animate(withDuration: 0.5, animations: {
            //self.FoundSensorColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xC84240)
            //self.DiscoveredServicesColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xC84240)
            //self.GatheringHistDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xC84240)
            //self.GatheringLiveDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xC84240)
            //self.BluemixColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0xC84240)
            self.DisconnectedColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
        })
        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        sensorTag = nil
        keepScanning = true
        historicalDataTable.removeAll()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING SERVICES: \(error?.localizedDescription)")
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                print("Discovered service \(service)")
                if (service.uuid == CBUUID(string: Device.RoomMonitorServiceUUID)) {
                    peripheral.discoverCharacteristics(nil, for: service)
                    UIView.animate(withDuration: 0.5, animations: {
                        self.DiscoveredServicesColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                    })
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(error?.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: Device.MostRecentLightLevelUUID) {
                    lightLevelCharacteristic = characteristic
                    sensorTag?.setNotifyValue(false, for: characteristic)
                    sensorTag?.readValue(for: characteristic)
                    print("Discovered most recent light level")
                }
                if characteristic.uuid == CBUUID(string: Device.MostRecentActivityStateUUID) {
                    activityStateCharacteristic = characteristic
                    sensorTag?.setNotifyValue(false, for: characteristic)
                    sensorTag?.readValue(for: characteristic)
                    print("Discovered most recent activity level")
                }
                if characteristic.uuid == CBUUID(string: Device.HistoricalLightLevelUUID) {
                    histLightCharRef = characteristic
                    activityStateCharacteristic = characteristic
                    sensorTag?.setNotifyValue(false, for: characteristic)
                    sensorTag?.readValue(for: characteristic)
                    print("Discovered most historical light level")
                    collectingHistoricalData = true
                }
                if characteristic.uuid == CBUUID(string: Device.HistoricalActivityStateUUID) {
                    histActivityCharRef = characteristic
                    activityStateCharacteristic = characteristic
                    sensorTag?.setNotifyValue(false, for: characteristic)
                    sensorTag?.readValue(for: characteristic)
                    print("Discovered most historical activity level")
                    collectingHistoricalData = true
                }
                if characteristic.uuid == CBUUID(string: Device.TimeOfHistoricalMeasurementUUID) {
                    histTimeCharRef = characteristic
                    activityStateCharacteristic = characteristic
                    sensorTag?.setNotifyValue(false, for: characteristic)
                    sensorTag?.readValue(for: characteristic)
                    print("Discovered time of historical measurement")
                    collectingHistoricalData = true
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(error?.localizedDescription)")
            return
        }
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if (characteristic.uuid == CBUUID(string: Device.MostRecentLightLevelUUID) && (collectingHistoricalData == false)) {
                //update light level
                let dataLength = dataBytes.count / MemoryLayout<UInt16>.size
                var value = [UInt16](repeating:0, count: dataLength)
                (dataBytes as NSData).getBytes(&value, length: dataLength * MemoryLayout<Int16>.size)
                
                rawLightLevel = value[0]
                lightLevelLabel.text = "\(rawLightLevel)"
                print("updated light level")
                
                gotLight = true
                
                if (gotActivity && gotLight) {
                    centralManager.cancelPeripheralConnection(sensorTag!)
                    print("DISCONNECTED FROM PERIPHERAL")
                    gotLight = false
                    gotActivity = false
                    UIView.animate(withDuration: 0.5, animations: {
                        self.GatheringLiveDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                    })
                    if isConnected == 1{
                        sharedInstance.sendRoomMonitorMessage(activity_level: Double(rawActivityLevel), light_level: Double(rawLightLevel), time_stamp: Date(), node_id: currentSensorName) // Call this function for each message needing to be sent
                        UIView.animate(withDuration: 0.5, animations: {
                            self.BluemixColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                        })
                    }else {
                        print("Not connected to IBM BlueMix")
                        
                        /*let alertController = UIAlertController(title: "Connection Error", message: "Not connected to IBM BlueMix", preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                        alertController.addAction(okAction)
                        self.show(alertController, sender: self)*/
                    }
                }
            } else if (characteristic.uuid == CBUUID(string: Device.MostRecentActivityStateUUID) && (collectingHistoricalData == false)) {
                //update activity level
                
                let dataLength = dataBytes.count / MemoryLayout<UInt16>.size
                var value = [UInt16](repeating:0, count: dataLength)
                (dataBytes as NSData).getBytes(&value, length: dataLength * MemoryLayout<Int16>.size)
                
                rawActivityLevel = value[0]
                activityLevelLabel.text = "\(rawActivityLevel)"
                print("updated activity level")
                
                gotActivity = true
                
                if (gotActivity && gotLight) {
                    centralManager.cancelPeripheralConnection(sensorTag!)
                    print("GOT DATA: DISCONNECTING FROM PERIPHERAL")
                    gotActivity = false
                    gotLight = false
                    UIView.animate(withDuration: 0.5, animations: {
                        self.GatheringLiveDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                    })
                    if isConnected == 1{
                        sharedInstance.sendRoomMonitorMessage(activity_level: Double(rawActivityLevel), light_level: Double(rawLightLevel), time_stamp: Date(), node_id: currentSensorName) // Call this function for each message needing to be sent
                        UIView.animate(withDuration: 0.5, animations: {
                            self.BluemixColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                        })
                    }else {
                        print("Not connected to IBM BlueMix")
                        
                        /*let alertController = UIAlertController(title: "Connection Error", message: "Not connected to IBM BlueMix", preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                        alertController.addAction(okAction)
                        self.show(alertController, sender: self)*/
                    }
                }
                
            // HISTORICAL DATA HANDLING
                
            } else if (characteristic.uuid == CBUUID(string: Device.HistoricalActivityStateUUID) && (collectingHistoricalData == true) && (gotHistoricalActivity == false)) {
                //update historical activity level
                
                histActivityCharRef = characteristic
                let dataLength = dataBytes.count / MemoryLayout<UInt16>.size
                var value = [UInt16](repeating:0, count: dataLength)
                (dataBytes as NSData).getBytes(&value, length: dataLength * MemoryLayout<Int16>.size)
                
                rawHistoricalActivityLevel = value[0]
                currentHistoricalData.historicalActivityLevel = rawHistoricalActivityLevel
                
                print("updated historical activity level")
                
                activityLevelLabel.text = "\(rawHistoricalActivityLevel)"
                UIView.animate(withDuration: 0.5, animations: {
                    self.GatheringHistDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                })
                gotHistoricalActivity = true

            } else if (characteristic.uuid == CBUUID(string: Device.HistoricalLightLevelUUID) && (collectingHistoricalData == true) && (gotHistoricalLight == false)) {
                //update historical light level
                
                histLightCharRef = characteristic
                let dataLength = dataBytes.count / MemoryLayout<UInt16>.size
                var value = [UInt16](repeating:0, count: dataLength)
                (dataBytes as NSData).getBytes(&value, length: dataLength * MemoryLayout<Int16>.size)
                
                rawHistoricalLightLevel = value[0]
                currentHistoricalData.historicalLightLevel = rawHistoricalLightLevel
                
                print("updated historical light level")
                
                lightLevelLabel.text = "\(rawHistoricalLightLevel)"
                UIView.animate(withDuration: 0.5, animations: {
                    self.GatheringHistDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                })

             
                gotHistoricalLight = true
                
            } else if (characteristic.uuid == CBUUID(string: Device.TimeOfHistoricalMeasurementUUID) && (collectingHistoricalData == true) && (gotHistoricalTime == false)) {
                
                histTimeCharRef = characteristic
                let dataLength = dataBytes.count / MemoryLayout<UInt16>.size
                var value = [UInt16](repeating:0, count: dataLength)
                (dataBytes as NSData).getBytes(&value, length: dataLength * MemoryLayout<Int16>.size)
                
                rawHistoricalTime = value[0]
                currentHistoricalData.relativeTimeHistoricalMeasurement = rawHistoricalTime
                print("updated relative historical time")
                if (rawHistoricalTime>maximumRelativeTime){
                    maximumRelativeTime = rawHistoricalTime
                }
                UIView.animate(withDuration: 0.5, animations: {
                    self.GatheringHistDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                })

                gotHistoricalTime = true
            }
        }
        
        // MARK: Historical data checking
        if (gotHistoricalActivity && gotHistoricalLight && gotHistoricalTime){
            print("save historical data")
            historicalDataTable.append(currentHistoricalData) // add the most recently collected data to the table
            gotHistoricalActivity = false
            gotHistoricalLight = false
            gotHistoricalTime = false
            historicalFirstPass = true
            
            if (debugHistoricalData){
                rawHistoricalTime = 0 // enable for test only
            }
            
            if (rawHistoricalTime == 0){ // if the historical time is 0 all data has been collected
                print("historical time is 0")
                keepScanning = true
                print("GOT ALL HISTORICAL DATA")
                gotHistoricalLight = false
                gotHistoricalActivity = false
                gotHistoricalTime = false
                historicalFirstPass = false
                calculateActualHistoricalTime()
                print("done")
                UIView.animate(withDuration: 0.5, animations: {
                    self.GatheringHistDataColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                })
                disconnectSensorNode()
            }
        }
        if (collectingHistoricalData && historicalFirstPass){ //if the first pass is done and collecting historical data then:
            if (!gotHistoricalTime) {
                peripheral.readValue(for: histTimeCharRef!)
            }
            if (!gotHistoricalActivity) {
                peripheral.readValue(for: histActivityCharRef!)
            }
            if (!gotHistoricalLight) {
                peripheral.readValue(for: histLightCharRef!)
            }
        }
    }
    
    func disconnectSensorNode() {
        centralManager.cancelPeripheralConnection(sensorTag!)
        sensorTag = nil
    }
    
    func calculateActualHistoricalTime(){ // calculate historical time and send data to BlueMix
        print("calculating actual times")
        print("max relative time:",maximumRelativeTime)
        //let maximumRelativeTime:TimeInterval = 10 // for test only
        let currentTime = Date()
        print("current time:",currentTime)
        print("activity,light,relative,actual")
        var subtractTime:TimeInterval = 0
        for index in 0..<historicalDataTable.count { // loop through the historical data table and calculate actual time
            let relativeTime:UInt16 = historicalDataTable[index].relativeTimeHistoricalMeasurement
            let timeDifference = maximumRelativeTime - relativeTime
            subtractTime = TimeInterval(timeDifference)
            historicalDataTable[index].actualTimeHistoricalMeasurement = (currentTime - subtractTime)
            print(historicalDataTable[index].historicalActivityLevel, ","
                , historicalDataTable[index].historicalLightLevel, ","
                , historicalDataTable[index].relativeTimeHistoricalMeasurement, ","
                , historicalDataTable[index].actualTimeHistoricalMeasurement)
            
            //Send each data line to BlueMix
            if(relativeTime > 0){
                if (isConnected == 1){
                    sharedInstance.sendRoomMonitorMessage(activity_level: Double(historicalDataTable[index].historicalActivityLevel),
                                                          light_level: Double(historicalDataTable[index].historicalLightLevel),
                                                          time_stamp: historicalDataTable[index].actualTimeHistoricalMeasurement,
                                                          node_id: currentSensorName)
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        self.BluemixColour.backgroundColor = self.UIColorFromRGB(rgbValue: 0x95C566)
                    })
                }else {
                    print("Not connected to IBM BlueMix")
                    
                    /*let alertController = UIAlertController(title: "Connection Error", message: "Not connected to IBM BlueMix", preferredStyle: UIAlertControllerStyle.alert)
                     let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
                     alertController.addAction(okAction)
                     self.show(alertController, sender: self)*/
                }
            } else {
                print("Reached last line")
            }
            
        }
        maximumRelativeTime = 0
        collectingHistoricalData = false
        
        
    }
    
    // MARK: Persistance Methods
    
    func saveSensor(uuid: String, lastConnectionTime: Date) {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext

        let entity =  NSEntityDescription.entity(forEntityName: "RoomSensor", in:managedContext)
        
        let sensorNode = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        sensorNode.setValue(uuid, forKey: "uuid")
        sensorNode.setValue(lastConnectionTime, forKey: "lastConnectionTime")
        
        do {
            try managedContext.save()
            //5
            persistantConnectionHistory.append(sensorNode)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        //self.sensorTable.reloadData()
    }
    
    func findSensor(testuuid: String)  -> Bool {
        var returnVal = false
        var foundUUID = false
        var foundIndex:Int = 0
        
        /* Print out some debugging info */
        print("Searching for:",testuuid)
        print("Number of nodes in connection history: ", persistantConnectionHistory.count)
        
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RoomSensor") //fetch entities with the correct name
        var result = [NSManagedObject]() //an array to put the results in
        result.removeAll() //make sure this array is empty
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        do {
            let matches = try managedContext.fetch(fetchRequest)
            
            if let matches = matches as? [NSManagedObject] {
                result = matches
            }
        } catch {
            print("Unable to fetch managed objects for entity RoomSensor.")
        }
        print("Number of nodes in result history: ", result.count)
        for index in 0..<result.count {
            let resultTest = result[index].value(forKey: "uuid")
            if (resultTest as! String == testuuid){
                print("MATCH")
                foundUUID = true
                
                if(index>foundIndex){
                    foundIndex = index
                    print("found later entry")
                }
            } else {
                print("NO MATCH")
            }
        }
        removedDuplicates = true
        
        if (foundUUID){
            print("Node was found in history at index: ", foundIndex, ", checking last connection time")
            let currentTime = Date()
            let connectionTime = result[foundIndex].value(forKey: "lastConnectionTime") as! Date
            let timeoutTime = connectionTime.addingTimeInterval(gatherDataInterval)
            if currentTime.compare(timeoutTime) == ComparisonResult.orderedDescending {
                print("Current time is later than timeout time. Can collect data again")
                //persistantConnectionHistory.remove(at: foundIndex) // TODO: fix this to reduce storage usage
                result.remove(at: foundIndex)
                print("Have removed record from history")
            } else {
                print("Current time is sooner than timeout time. Can't collect data again")
                returnVal = true
            }
        }
        return returnVal
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor { // from Nate Cook
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

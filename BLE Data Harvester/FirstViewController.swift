//
//  FirstViewController.swift
//  BLE Data Harvester
//
//  Created by Sam Presley on 02/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//

import UIKit
import CoreBluetooth

class FirstViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    // MARK: Properties
    @IBOutlet weak var activityLevelLabel: UILabel!
    @IBOutlet weak var lightLevelLabel: UILabel!
    @IBOutlet weak var historyView: UITextView!
    
    
    // MARK: scanning parameters
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    var keepScanning = false
    var pauseScanFlag = false
    var resumeScanFlag = false
    var timer = Timer()
    
    var centralManager:CBCentralManager!
    var sensorTag:CBPeripheral?
    var lightLevelCharacteristic:CBCharacteristic?
    var activityStateCharacteristic:CBCharacteristic?
    let sensorTagName = "GH-SensorNode"
    
    var gotLight:Bool = false
    var gotActivity:Bool = false
    var rawActivityLevel:UInt16 = 0
    var rawLightLevel:UInt16 = 0
    
    // MARK: connection history parameters
    let gatherDataInterval:TimeInterval = 60.0
    struct roomSensorNode {
        var UUID:String
        var lastConnectionTime:NSDate
    }
    var connectionHistory = [roomSensorNode]()
    //let defaults = UserDefaults.standard
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
        /*if defaults.bool(forKey: "notFirstRun") {
            print("not the first run")
            // TODO: Load the history connection array
        } else {
            print("the first run")
            defaults.set(true, forKey: "notFirstRun")
            // TODO: Init the historic connection array
        }*/
        historyView.text = readDataFromStoredConnectionHistoryFile(file: "storedConnectionData.txt")
    }
    
    func readDataFromStoredConnectionHistoryFile(file:String) -> String!{
        guard let filePath = Bundle.main.path(forResource: file, ofType: "txt")
            else {
                return nil
        }
        do {
            let contents = try String(contentsOfFile: filePath, encoding: String.Encoding.ascii)
            return contents
        } catch {
            print("File read error for file \(filePath)")
            return nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            timer = Timer.scheduledTimer(timeInterval: timerScanInterval, target:self, selector: #selector(FirstViewController.pauseScan), userInfo: nil, repeats: false)
            
            //(withTimeInterval: timerScanInterval, target: self, selector: #selector(FirstViewController.pauseScan), userInfo: nil, repeats: false)
            
            // Initiate Scan for Peripherals
            let roomMonitorServiceUUID = CBUUID(string: Device.RoomMonitorServiceUUID)
            print("Scanning for SensorTag adverstising room monitor service \(roomMonitorServiceUUID)")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
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
            
            if peripheralName == sensorTagName {
                print("SENSOR TAG FOUND! ADDING NOW!!!")
                
                let currentTime = NSDate()
                var foundInHistory = false
                
                // to save power, stop scanning for other devices
                keepScanning = false
                
                /*
                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(sensorTag!, options: nil)
                 */
                
                for index in 0..<connectionHistory.count {
                    if connectionHistory[index].UUID == peripheral.identifier.uuidString {
                        print("Found peripheral in connection history")
                        print("Checking last connection time")
                        foundInHistory = true
                        let connectionTime = connectionHistory[index].lastConnectionTime
                        let timeoutTime = connectionTime.addingTimeInterval(gatherDataInterval)
                        if currentTime.compare(timeoutTime as Date) == ComparisonResult.orderedDescending {
                            print("Current time is later than timeout time. Can collect data again")
                            // save a reference to the sensor tag
                            sensorTag = peripheral
                            sensorTag!.delegate = self
                            
                            // Request a connection to the peripheral
                            centralManager.connect(sensorTag!, options: nil)
                            
                            // Update peripheral in to connection history
                            
                            let thisPeripheral = roomSensorNode(UUID: peripheral.identifier.uuidString, lastConnectionTime: currentTime)
                            connectionHistory.append(thisPeripheral)
                            connectionHistory.remove(at: index)
                            
                            // TODO: Store the historic connection array
                            
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
                    
                    // Put peripheral in to connection history
                    
                    let thisPeripheral = roomSensorNode(UUID: peripheral.identifier.uuidString, lastConnectionTime: currentTime)
                    connectionHistory.append(thisPeripheral)
                    
                    // TODO: Store the historic connection array
                    
                }
            }
        }
    }
    
    func pauseScan() {
        // Scanning uses up battery on phone, so pause the scan process for the designated interval.
        print("*** PAUSING SCAN...")
        timer = Timer.scheduledTimer(timeInterval: timerPauseInterval, target:self, selector: #selector(FirstViewController.resumeScan), userInfo: nil, repeats: false)
        centralManager.stopScan()
    }
    
    func resumeScan() {
        if keepScanning {
            // Start scanning again...
            print("*** RESUMING SCAN!")
            timer = Timer.scheduledTimer(timeInterval: timerScanInterval, target:self, selector: #selector(FirstViewController.pauseScan), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!")
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        peripheral.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("**** CONNECTION TO SENSOR TAG FAILED!!!")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("**** DISCONNECTED FROM SENSOR TAG!!!")
        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        sensorTag = nil
        keepScanning = true
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
                // If we found either the temperature or the humidity service, discover the characteristics for those services.
                if (service.uuid == CBUUID(string: Device.RoomMonitorServiceUUID)) {
                    peripheral.discoverCharacteristics(nil, for: service)
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
                    // Enable IR Temperature Sensor
                    activityStateCharacteristic = characteristic
                    sensorTag?.setNotifyValue(false, for: characteristic)
                    sensorTag?.readValue(for: characteristic)
                    print("Discovered most recent activity level")
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
            if characteristic.uuid == CBUUID(string: Device.MostRecentLightLevelUUID) {
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
                }
            } else if characteristic.uuid == CBUUID(string: Device.MostRecentActivityStateUUID) {
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
                }
            }
        }
    }

}



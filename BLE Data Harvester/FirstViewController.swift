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

    // define our scanning parameters
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    var keepScanning = false
    var pauseScanFlag = false
    var resumeScanFlag = false
    
    var centralManager:CBCentralManager!
    var sensorTag:CBPeripheral?
    var lightLevelCharacteristic:CBCharacteristic?
    var activityLevelCharacteristic:CBCharacteristic?
    let sensorTagName = "GH-SensorNode"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
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
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(getter: pauseScanFlag), userInfo: nil, repeats: false)
            
            // Initiate Scan for Peripherals
            let roomMonitorServiceUUID = CBUUID(string: Device.RoomMonitorServiceUUID)
            print("Scanning for SensorTag adverstising with UUID: \(roomMonitorServiceUUID)")
            centralManager.scanForPeripherals(withServices: [roomMonitorServiceUUID], options: nil)
        }
        
        if showAlert {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName == sensorTagName {
                print("SENSOR TAG FOUND! ADDING NOW!!!")
                // to save power, stop scanning for other devices
                keepScanning = false
                
                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(sensorTag!, options: nil)
            }
        }
    }
    
    func pauseScan() {
        // Scanning uses up battery on phone, so pause the scan process for the designated interval.
        print("*** PAUSING SCAN...")
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(getter: resumeScanFlag), userInfo: nil, repeats: false)
        centralManager.stopScan()
    }
    
    func resumeScan() {
        if keepScanning {
            // Start scanning again...
            print("*** RESUMING SCAN!")
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(getter: pauseScanFlag), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

}



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
    var pauseScan = false
    
    var centralManager:CBCentralManager!
    var sensorTag:CBPeripheral?
    var lightLevelCharacteristic:CBCharacteristic?
    var activityLevelCharacteristic:CBCharacteristic?
    
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
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(getter: pauseScan), userInfo: nil, repeats: false)
            
            // Initiate Scan for Peripherals
            //Option 1: Scan for all devices
            let roomMonitorServiceUUID = CBUUID(string: Device.RoomMonitorServiceUUID)
            centralManager.scanForPeripherals(withServices: [roomMonitorServiceUUID], options: nil)
            
            // Option 2: Scan for devices that have the service you're interested in...
            //let sensorTagAdvertisingUUID = CBUUID(string: Device.SensorTagAdvertisingUUID)
            //print("Scanning for SensorTag adverstising with UUID: \(sensorTagAdvertisingUUID)")
            //centralManager.scanForPeripherals(withServices: [sensorTagAdvertisingUUID], options: nil)
            
        }
        
        if showAlert {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
    }


}



//
//  FirstViewController.swift
//  BLE Data Harvester
//
//  Created by Sam Presley on 02/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//

import UIKit
import CoreBluetooth

var centralManager:CBCentralManager!
var sensorTag:CBPeripheral?

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

func centralManagerDidUpdateState(central: CBCentralManager){
    switch central.state {
    case .PoweredOn:
        // 1
        keepScanning = true
        // 2
        _ = NSTimer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
        // 3
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
    case .PoweredOff:
        state = "Bluetooth on this device is currently powered off."
    case .Unsupported:
        state = "This device does not support Bluetooth Low Energy."
    case .Unauthorized:
        state = "This app is not authorized to use Bluetooth Low Energy."
    case .Resetting:
        state = "The BLE Manager is resetting; a state update is pending."
    case .Unknown:
        state = "The state of the BLE Manager is unknown."
    }
}

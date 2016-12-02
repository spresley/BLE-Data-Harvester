//
//  device.swift
//  BLE Data Harvester
//
//  Created by Nathan Ruttley on 02/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Device {
    
    static let SensorTagAdvertisingUUID = "GH-SensorNode"
    
    static let RoomMonitorServiceUUID =      "AC8BA2AE-F020-4395-A301-6E833EBD4571"
    static let MostRecentLightLevelUUID =           "AC8B3A9A-F020-4395-A301-6E833EBD4571"
    static let MostRecentActivityStateUUIN =        "AC8BA6D8-F020-4395-A301-6E833EBD4571"
    static let HistoricalLightLevelUUID =           "8C8794B9-EE0A-4747-B9CB-4E17B11FC3EC"
    static let HistoricalActivityStateUUID =        "8C8765DD-EE0A-4747-B9CB-4E17B11FC3EC"
    static let TimeOfMostRecentMeasurementUUID =    "8C87AEDD-EE0A-4747-B9CB-4E17B11FC3EC"
    static let TimeOfHistoricalMeasurementUUID =    "8C87BCD4-EE0A-4747-B9CB-4E17B11FC3EC"
    
    static let TemperatureServiceUUID = "F000AA00-0451-4000-B000-000000000000"
    static let TemperatureDataUUID = "F000AA01-0451-4000-B000-000000000000"
    static let TemperatureConfig = "F000AA02-0451-4000-B000-000000000000"
    
    static let HumidityServiceUUID = "F000AA20-0451-4000-B000-000000000000"
    static let HumidityDataUUID = "F000AA21-0451-4000-B000-000000000000"
    static let HumidityConfig = "F000AA22-0451-4000-B000-000000000000"
    
    static let SensorDataIndexTempInfrared = 0
    static let SensorDataIndexTempAmbient = 1
    static let SensorDataIndexHumidityTemp = 0
    static let SensorDataIndexHumidity = 1
}

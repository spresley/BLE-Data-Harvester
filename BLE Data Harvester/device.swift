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
    
    static let SensorTagAdvertisingUUID = "ROOM"
    
    static let RoomMonitorServiceUUID =      "8C877E45-EE0A-4747-B9CB-4E17B11FC3EC" //"AC8BA2AE-F020-4395-A301-6E833EBD4571"
    static let MostRecentLightLevelUUID =           "8C8724F4-EE0A-4747-B9CB-4E17B11FC3EC" //"BC8B3A9A-F020-4395-A301-6E833EBD4571"
    static let MostRecentActivityStateUUID =        "8C870296-EE0A-4747-B9CB-4E17B11FC3EC" //"BC8BA6D8-F020-4395-A301-6E833EBD4571"
    static let HistoricalLightLevelUUID =           "AC8B3A9A-F020-4395-A301-6E833EBD4571" //8C8794B9EE0A4747B9CB4E17B11FC3EC
    static let HistoricalActivityStateUUID =        "AC8BA6D8-F020-4395-A301-6E833EBD4571" //8C8765DDEE0A4747B9CB4E17B11FC3EC
    static let TimeOfMostRecentMeasurementUUID =    "8C87AEDD-EE0A-4747-B9CB-4E17B11FC3EC" // "8C87AEDD-EE0A-4747-B9CB-4E17B11FC3EC"
    static let TimeOfHistoricalMeasurementUUID =    "AC8BADD4-F020-4395-A301-6E833EBD4571" // 8C87BCD4EE0A4747B9CB4E17B11FC3EC
}

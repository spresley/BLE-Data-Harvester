//
//  MQTT-config.swift
//  BLE Data Harvester
//
//  Created by Sam Presley on 02/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//
//  Contains the organisational host name and port number for connections to the projects instance of the IBM IoT Service

import Foundation

public class MQTTlogin{
    public static var host: String { return "f6z0bl.messaging.internetofthings.ibmcloud.com" }
    public static var port: UInt16 { return 1883 }
}

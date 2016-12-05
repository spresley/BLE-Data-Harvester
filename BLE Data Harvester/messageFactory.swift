//
//  messageFactory.swift
//  BLE Data Harvester
//
//  Created by Sam Presley on 04/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//

import Foundation


// creates a room monitor message
func createRoomMonitorMessage(activity_level: Double,
                              light_level: Double) ->String
{
    let jsonObject: NSMutableDictionary = NSMutableDictionary()
    
    jsonObject.setValue(activity_level, forKey: "activity_level")
    jsonObject.setValue(light_level, forKey: "light_level")
    
    let jsonData: NSData
    
    do {
        jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
        let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue) as! String
        print("json string = \(jsonString)")
        return jsonString
        
    } catch _ {
        print ("JSON Failure")
        return "error"
    }
}



// creates an accel message in the same format as the IBM IOT example for testing
func createAccelMessage(accel_x: Double,
                        accel_y: Double,
                        accel_z: Double,
                        roll: Double,
                        pitch: Double,
                        yaw: Double,
                        lat:Double,
                        lon:Double) ->String
{
    
    
    let jsonObject: NSMutableDictionary = NSMutableDictionary()
    
    jsonObject.setValue(accel_x, forKey: "acceleration_x")
    jsonObject.setValue(accel_y, forKey: "acceleration_y")
    jsonObject.setValue(accel_z, forKey: "acceleration_z")
    jsonObject.setValue(pitch, forKey: "pitch")
    jsonObject.setValue(roll, forKey: "roll")
    jsonObject.setValue(yaw, forKey: "yaw")
    jsonObject.setValue(lat, forKey: "lat")
    jsonObject.setValue(lon, forKey: "lon")
    
    let jsonData: NSData
    
    do {
        jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
        let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue) as! String
        print("json string = \(jsonString)")
        return jsonString
        
    } catch _ {
        print ("JSON Failure")
        return "error"
    }
}


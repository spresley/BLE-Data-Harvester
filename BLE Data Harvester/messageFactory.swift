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
                              light_level: Double,
                              time_stamp: String,
                              node_id: String) ->String
{
    let jsonObject: NSMutableDictionary = NSMutableDictionary()
    
    jsonObject.setValue(activity_level, forKey: "activity_level")
    jsonObject.setValue(light_level, forKey: "light_level")
    jsonObject.setValue(time_stamp, forKey: "time_stamp")
    jsonObject.setValue(node_id, forKey: "node_id")
    
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

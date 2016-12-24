//
//  RoomSensor+CoreDataProperties.swift
//  
//
//  Created by Nathan Ruttley on 24/12/2016.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension RoomSensor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RoomSensor> {
        return NSFetchRequest<RoomSensor>(entityName: "RoomSensor");
    }

    @NSManaged public var lastConnectionTime: NSDate?
    @NSManaged public var uuid: String?

}

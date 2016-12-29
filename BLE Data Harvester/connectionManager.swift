//
//  connectionManager.swift
//  BLE Data Harvester
//
//  Created by Sam Presley on 28/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//

import Foundation
import CocoaMQTT

class MQTTmanager: CocoaMQTTDelegate{
    
    var mqtt:CocoaMQTT?

    static let sharedInstance = MQTTmanager()
    var delegate : MQTTManagerDelegate?
    
    init(){
    }
    
    func initInstance(clientId:String, host:String) {
        let mqtt = CocoaMQTT(
                clientID: clientId,
                host: host,
                port: MQTTlogin.port
            )
            mqtt.delegate = self;
    }
    
    // Connect
    func connect(username:String, password:String) {
        mqtt?.username = username
        mqtt?.password = password
        mqtt?.connect()
    }
    
    // Publish
    func publish(topic:String, message:String) {
        let message = CocoaMQTTMessage(
            topic: topic,
            string: message
        )
        
        mqtt?.publish(message)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck \(ack.rawValue)")
        if ack == .accept {
            print("connected OK")
            //            connectivityState.text = "Connected"
            //buttonLabel.setTitle("Connected", for: .normal)
            isConnected = 1
            delegate?.updatedConnectionState(sender: self, state: true)
        }
        else{
            print("Connection failed")
            isConnected = 0
            delegate?.updatedConnectionState(sender: self, state: false)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string)")
        print("topic: \(message.topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("didReceivedMessage: \(message.string) with id \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        _console(info:"didReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        _console(info:"mqttDidDisconnect")
        delegate?.updatedConnectionState(sender: self, state: false)
        isConnected = 0
    }
    
    func _console(info: String) {
        print("Delegate: \(info)")
    }
    
    func setupConnection(clientID: String, authToken: String){
        print("Current Advertising ID:\(UIDevice.current.identifierForVendor!.uuidString)")
        let clientID = "d:f6z0bl:iPhone:"+clientID
        print("Client ID = \(clientID)")
        mqtt = CocoaMQTT(clientID: clientID, host: MQTTlogin.host, port: MQTTlogin.port)
        mqtt!.username = "use-token-auth"
        mqtt!.password = authToken
        mqtt!.keepAlive = 90
        mqtt!.delegate = self
        mqtt!.connect()
    }
    
    func sendRoomMonitorMessage(activity_level: Double, light_level: Double, time_stamp: Date){
        if isConnected == 1 {
            let dateAsString: String = time_stamp.iso8601
            
            var message = createRoomMonitorMessage(activity_level: activity_level, light_level: light_level, time_stamp: dateAsString)
            message = "{\"d\":\(message)}"
            let topic = "iot-2/evt/room-data/fmt/json"
            let mqttmessage = CocoaMQTTMessage.init(topic: topic, string: message)
            
            mqtt!.publish(mqttmessage)
        }
        else{
            print("Connect before sending message!")
        }
    }
    
    func sendRoomMonitorTestMessage(){
        let stringFromDate = Date().iso8601    // "2016-06-18T05:18:27.935Z"
        let rand = Double(arc4random_uniform(10))
        let rand2 = Double(arc4random_uniform(2))
        
        var message = createRoomMonitorMessage(activity_level: rand, light_level: rand2, time_stamp: stringFromDate)
        message = "{\"d\":\(message)}"
        let topic = "iot-2/evt/room-data/fmt/json"
        let mqttmessage = CocoaMQTTMessage.init(topic: topic, string: message)
        
        mqtt!.publish(mqttmessage)
    }
    
}


protocol MQTTManagerDelegate: class {
    func updatedConnectionState(sender: MQTTmanager, state: Bool)
}

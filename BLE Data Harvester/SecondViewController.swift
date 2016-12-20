//
//  SecondViewController.swift
//  BLE Data Harvester
//
//  Created by Sam Presley on 02/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//

import UIKit
import CocoaMQTT


class SecondViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var mqtt:CocoaMQTT?
    var mqttmessage:CocoaMQTTMessage!
    var topic:String = ""
    var message:String = ""
    
    func setupConnection(){
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        print("Client ID = \(clientID)")
        mqtt = CocoaMQTT(clientID: MQTTlogin.clientID, host: MQTTlogin.host, port: MQTTlogin.port)
        mqtt!.username = "use-token-auth"
        mqtt!.password = "test1234"
        mqtt!.keepAlive = 90
        mqtt!.delegate = self
        mqtt!.connect()
    }
    func sendAccelMessage(){
        var message = createAccelMessage(accel_x: 0, accel_y: 0, accel_z: 0, roll: 0, pitch: 0, yaw: 0, lat: 0, lon: 0)
        print("accel message: \(message)")
        
        message = "{\"d\":\(message)}"
        print("data message: \(message)")
        
        topic = "iot-2/evt/accel/fmt/json"
        print("topic to send: \(topic)")
        
        mqttmessage = CocoaMQTTMessage.init(topic: topic, string: message)
        
        mqtt!.publish(mqttmessage)
    }
    func sendRoomMonitorMessage(){
        let stringFromDate = Date().iso8601    // "2016-06-18T05:18:27.935Z"
        let rand = Double(arc4random_uniform(10))
        let rand2 = Double(arc4random_uniform(2))

        var message = createRoomMonitorMessage(activity_level: rand, light_level: rand2, time_stamp: stringFromDate)
        message = "{\"d\":\(message)}"
        topic = "iot-2/evt/room-data/fmt/json"
        mqttmessage = CocoaMQTTMessage.init(topic: topic, string: message)
        
        mqtt!.publish(mqttmessage)
    }
    
    @IBAction func connectButtonWasPressed(_ sender: Any) {
        setupConnection()
    }
    @IBAction func sendButtonWasPressed(_ sender: Any) {
        //sendAccelMessage()
        sendRoomMonitorMessage()
    }
    @IBOutlet weak var connectivityState: UILabel!
    @IBOutlet weak var buttonLabel: UIButton!
    
    
}



extension SecondViewController: CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck \(ack.rawValue)")
        if ack == .accept {
            print("connected OK")
        }
        connectivityState.text = "Connected"
        buttonLabel.setTitle("Connected", for: .normal)
        
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
        connectivityState.text = "Disconnected"
    }
    
    func _console(info: String) {
        print("Delegate: \(info)")
    }
    
}


//
// From: http://stackoverflow.com/questions/28016578/swift-how-to-create-a-date-time-stamp-and-format-as-iso-8601-rfc-3339-utc-tim
//
//

extension Date {
    struct Formatter {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            return formatter
        }()
    }
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}


extension String {
    var dateFromISO8601: Date? {
        return Date.Formatter.iso8601.date(from: self)
    }
}

// END FROM

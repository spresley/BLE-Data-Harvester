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
        
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        print("Client ID = \(clientID)")
        let mqtt = CocoaMQTT(clientID: MQTTlogin.clientID, host: MQTTlogin.host, port: MQTTlogin.port)
        mqtt.username = "use-token-auth"
        mqtt.password = "test1234"
       // mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt.keepAlive = 90
        mqtt.delegate = self
        mqtt.connect()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
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
    }
    
    func _console(info: String) {
        print("Delegate: \(info)")
    }
    
}

//
//  SettingsViewController.swift
//  
//
//  Created by Sam Presley on 21/12/2016.
//
//

import UIKit
import CocoaMQTT

class SettingsViewController: UIViewController {
    
    var isConnected = 0
    var clientID = ""
    var authToken = ""
    
    @IBOutlet weak var buttonLabel: UIButton!
    @IBOutlet weak var connectivityState: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if isConnected == 1{
            connectivityState.text = "Connected"
        }
        else{
            connectivityState.text = "Disconnected"
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var deviceID: UITextField!
    @IBOutlet weak var deviceAuthKey: UITextField!
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    var mqtt:CocoaMQTT?
    var mqttmessage:CocoaMQTTMessage!
    var topic:String = ""
    var message:String = ""
    
    
    @IBAction func connectButtonWasPressed(_ sender: Any) {
        
    }
    @IBAction func loginButtonWasPress(_ sender: Any) {
        if ((deviceID.text != "") && (deviceAuthKey.text != "")){

            print("login details present")
            print("Device ID:\(deviceID.text) Device Auth Key: \(deviceAuthKey.text)")
            clientID = deviceID.text!
            authToken = deviceAuthKey.text!
            
            setupConnection(clientID: clientID, authToken: authToken )
        }
        else{
            print("login details required")
        }

    }

    @IBAction func sendButtonWasPressed(_ sender: Any) {
        print("Send button was pressed")

        if isConnected == 1{
            sendRoomMonitorMessage()
        }
        else{
            print("Not logged in")
        }
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

    
}


extension SettingsViewController: CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck \(ack.rawValue)")
        if ack == .accept {
            print("connected OK")
            connectivityState.text = "Connected"
            //buttonLabel.setTitle("Connected", for: .normal)
            isConnected = 1
        }
        else{
            print("Connection failed")
            connectivityState.text = "Connection failed"
            isConnected = 0
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
        connectivityState.text = "Disconnected"
        isConnected = 0
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


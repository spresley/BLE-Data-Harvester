//
//  SettingsViewController.swift
//  
//
//  Created by Sam Presley on 21/12/2016.
//
//

import UIKit
import CocoaMQTT

var isConnected = 0

class SettingsViewController: UIViewController, MQTTManagerDelegate {
    
    var clientID = ""
    var authToken = ""
    var mqttmessage:CocoaMQTTMessage!
    var topic:String = ""
    var message:String = ""
    
    var sharedInstance = MQTTmanager.sharedInstance
    
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
        sharedInstance.delegate = self
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
    
    @IBAction func loginButtonWasPress(_ sender: Any) {
        if ((deviceID.text != "") && (deviceAuthKey.text != "")){

            print("login details present")
            print("Device ID:\(deviceID.text) Device Auth Key: \(deviceAuthKey.text)")
            clientID = deviceID.text!
            authToken = deviceAuthKey.text!

            sharedInstance.initInstance(clientId: clientID, host: MQTTlogin.host)
            sharedInstance.setupConnection(clientID: clientID, authToken: authToken)
        }
            
        else{
            print("login details required")
        }

    }

    @IBAction func sendButtonWasPressed(_ sender: Any) {
        print("Send button was pressed")

        if isConnected == 1{
            sharedInstance.sendRoomMonitorTestMessage()
        }
        else{
            print("Not logged in")
        }
    }

    func updatedConnectionState(sender:MQTTmanager,state: Bool){
        if state == true {
            connectivityState.text = "Connected"
        } else{
            connectivityState.text = "Disconnected"
        }
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


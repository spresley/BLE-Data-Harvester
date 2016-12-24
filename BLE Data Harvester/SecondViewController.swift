//
//  SecondViewController.swift
//  BLE Data Harvester
//
//  Created by Sam Presley on 02/12/2016.
//  Copyright © 2016 ELEC6245. All rights reserved.
//

import UIKit
import CocoaMQTT
import WebKit


class SecondViewController: UIViewController, WKUIDelegate {
        
    @IBOutlet var webView: WKWebView!
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myURL = URL(string: "https://www.apple.com")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    

    

    
}



//
//  GraphViewController.swift
//  Pods
//
//  Created by Sam Presley on 23/12/2016.
//
//

import UIKit

class GraphViewController: UIViewController {
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Graph view loaded")
    
        // Do any additional setup after loading the view.
        
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "APIkeys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        let keysdict = keys
        
        let cloudantUsername = keysdict?["cloudant-username"] as! String
        let cloudantPassword = keysdict?["cloudant-password"] as! String
        
       let url = URL(string: ("https://" + cloudantUsername + ":" + cloudantPassword + "@f810fc6b-39be-4c4c-9716-47f93c071d09-bluemix.cloudant.com/test-data/_design/design_doc/_view/by-date-minimised"))!
        let task = URLSession.shared.dataTask(with: url){(data, response, error) in
            if error != nil{
                print("error")
            } else{
                if let urlContent = data{
                    do{
                        let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options:[])
                        print(jsonResult)
                        
                        if let dictionary = jsonResult as? [String: AnyObject] {
                            if let total_rows = dictionary["total_rows"] as? Int {
                                // access individual value in dictionary
                                print(total_rows)
                            }
                            if let rows = dictionary["rows"]{
                                for (row) in rows as! [AnyObject] {
                                    if let value = row["value"] as? [String: AnyObject]{
                                        print(value)
                                        if let time_stamp = value["time_stamp"] as? String {
                                            print(time_stamp)
                                            if let activity_level = value["activity_level"] as? Int {
                                                print(activity_level)
                                                if let light_level = value["light_level"] as? Int {
                                                    print(light_level)
                                                    //Add data to array here
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch{
                        print("Json processing failed")
                    }
                }
        
            }
        }
        task.resume()
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

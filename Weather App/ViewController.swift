//
//  ViewController.swift
//  Weather App
//
//  Created by Lorsch House on 12/23/15.
//  Copyright © 2015 Couch Potato Sudios. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var currentWeatherImage: UIImageView!

    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var currentWeatherLabel: UILabel!
    @IBOutlet weak var rainChanceLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    
    
    var locationManager = CLLocationManager()
    
    //var url = ""
    
    var timesGone = 0
    
    var latitude: Double!
    
    //VALUES 
    
    var tempInt = 1116
    var windSpeed = 1116
    var precipChance = 1116
    var locationTitle = "1116, USA"
    var summary = "1116"
    var icon = "1116"
    var iconImage = "1116.png"
    
    var url: String = "" {
        
        didSet {
            
            while timesGone < 1 {
            
                print(url)
                print("running json")
                print(latitude)
                getJSON()
                timesGone++
            }
        }
    }
    
   
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        
        
    }

    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        let locValue: CLLocationCoordinate2D = (manager.location?.coordinate)!
        
        let lat = locValue.latitude
        let long = locValue.longitude
        
        latitude = locValue.latitude
        
        url = "https://api.forecast.io/forecast/73e98c14ffc7ff709531cb7b5c04289a/\(lat),\(long)"
        
        //ALCATRAZ URL - https://api.forecast.io/forecast/73e98c14ffc7ff709531cb7b5c04289a/37.8267,-122.423
        
        //FIND CITY
        
        var location = CLLocation(latitude: lat, longitude: long)
        
        //print(location)
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            //print(location)
            
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                let city = pm.locality
                let state = pm.administrativeArea
                
                self.locationTitle = "\(city!), \(state!)"
                
                
            }
            else {
               print("Problem with the data received from geocoder")
            }
        })
        
        
}

    
    
    func getJSON() {
        
        print(url)
        
        let jsonURL = NSURL(string: url)
        print("JSONURL: \(jsonURL)")
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(jsonURL!) {
            (data, response, error) -> Void in
            
            do {
                
                print("past task")
                
                let jsonData = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                
                
                let currentJSON = jsonData["currently"]
                
                print(currentJSON)
                
                
                //TEMP
                let temp = currentJSON!["apparentTemperature"] as? Float
                self.tempInt = Int(temp!)
                
                if self.tempInt != 1116 {
                
                    print(self.tempInt)
                    self.updateValues()
                }
                
                //WIND SPEED
                self.windSpeed = (currentJSON!["windSpeed"] as? Int)!
                print("Windspeed \(self.windSpeed)")
                
                //RAIN CHANCE
                self.precipChance = (currentJSON!["precipProbability"] as? Int)!
                print("Rain Chance \(self.precipChance)")

                
                //SUMMARY
                self.summary = (currentJSON!["summary"] as? String)!
                print("Summary \(self.summary)")

                //WEATHER ICON
                self.icon = (currentJSON!["icon"] as? String)!
                print("icon \(self.icon)")

                switch self.icon {
                    
                case "clear-day" :
                    self.iconImage = "Sun.png"
                case "rain" :
                    self.iconImage = "RainCloud.png"
                
                case "cloudy" :
                    self.iconImage = "Cloud.png"
                    
                case "partly-cloudy-day" :
                    self.iconImage = "PartlyCloudy.png"
                    
                default :
                    self.iconImage = "Sun.png"
                    
                    
                }
                
                self.updateValues()
                
            } catch _ {
                // Error
                
                print("error")
            }
        }
        
        task.resume()
        }
        

    
    
    func updateValues() {
        
        print("updating")
        dispatch_async(dispatch_get_main_queue()) {
            self.tempLabel.text = "\(self.tempInt)°"
            self.windLabel.text = "\(self.windSpeed) MPH"
            self.rainChanceLabel.text = "\(self.precipChance)% Rain"
            self.cityLabel.text = self.locationTitle
            self.currentWeatherLabel.text = self.summary
            self.currentWeatherImage.image = UIImage(named: self.iconImage)
            print(self.iconImage)
        }
       
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


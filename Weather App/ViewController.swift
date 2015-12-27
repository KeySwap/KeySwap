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
    
    var timesGone = 0
    
    var latitude: Double!
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    //VALUES 
    
    var tempInt = 1116
    var windSpeed = 1116
    var precipChance = 1116
    var locationTitle = "Loading..."
    var summary = "Loading..."
    var icon = "1116"
    var iconImage = "1116.png"
    
    var url: String = "" {
        
        didSet {
            
            while timesGone < 2 {
            
                print(url)
                print("running json")
                print(latitude)
                getJSON()
                timesGone++
            }
        }
    }
    
    func alert(message: String) {
        
        let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }

    
    override func viewDidAppear(animated: Bool) {
        updateValues()

    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
      
        
        let locValue: CLLocationCoordinate2D = (manager.location?.coordinate)!
        
        let lat = locValue.latitude
        let long = locValue.longitude
        
        latitude = locValue.latitude
        
        url = "https://api.forecast.io/forecast/73e98c14ffc7ff709531cb7b5c04289a/\(lat),\(long)"
        
        print(url)
        
        //ALCATRAZ URL - https://api.forecast.io/forecast/73e98c14ffc7ff709531cb7b5c04289a/37.8267,-122.423
        
        //FIND CITY
        
        let location = CLLocation(latitude: lat, longitude: long)
        
        updateValues()
        
        //print(location)
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            //print(location)
            
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                
                let timesErrored = 0
                
                while timesErrored < 1 {
                    
                    self.alert("Could not get a city/town from your current location")
                }

                
                
                
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                let city = pm.locality
                let state = pm.administrativeArea
                
                self.updateValues()
                
                print(city)
                print(state)
                
                //if no city or state is found then display error
                if state == nil || city == nil {
                    

                    self.locationTitle = "No state/province or city found"
                    
                    if state == nil && city != nil {
                        
                        self.locationTitle = "\(city), N/A"
                        
                    }
                    
                    if state != nil && city == nil {
                        
                        self.locationTitle = "N/A, \(state)"
                        
                    }

                    
                    
                } else {
                    
                    self.locationTitle = "\(city!), \(state!)"
                    self.updateValues()
                    self.getJSON()

                }
                
               
                
                self.updateValues()
                
            }
            else {
               print("Problem with the data received from geocoder")
            }
        })
        
}

    
    
    func getJSON() {
        
        print(url)
        
        self.updateValues()
        
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
                    
                case "partly-cloudy-night" :
                    self.iconImage = "PartlyCloudyNight.png"
                    
                case "snow" :
                    self.iconImage = "SnowCloud.png"
                    
                case "sleet" :
                    self.iconImage = "Sleet.png"
                    
                case "wind" :
                    self.iconImage = "Wind.png"
                    
                case "fog" :
                    self.iconImage = "Fog.png"
                
                case "clear-night" :
                    self.iconImage = "Moon.png"
                    
                default :
                    self.iconImage = "Sun.png"
                    
                    
                }
                
                self.updateValues()
                
            } catch _ {
                // Error
                
                self.alert("Could not retrieve weather data")
                
            }
        }
        
        task.resume()
        
        updateValues()
        
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

    //legally neccesary powered by forecast.io badge
    @IBAction func forecastOpen(sender: AnyObject) {
        
        UIApplication.sharedApplication().openURL(NSURL(string: "http://www.forecast.io")!)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


//
//  ViewController.swift
//  trnql Interplay
//
//  Created by Jonathan Sahoo on 11/20/15.
//  Copyright © 2015 trnql. All rights reserved.
//

import UIKit
import MapKit
import trnql

extension NSDate {
    func hoursFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Hour, fromDate: date, toDate: self, options: []).hour
    }
    func minutesFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Minute, fromDate: date, toDate: self, options: []).minute
    }
}

class ViewController: UIViewController, TrnqlDelegate, MKMapViewDelegate {
    
    
    @IBOutlet weak var locationImageBackdrop: UIImageView!
    @IBOutlet weak var locationImageIcon: UIImageView!
    @IBOutlet weak var currentAddressLabel: UILabel!
    @IBOutlet weak var saveLocationPromptLabel: UILabel!
    @IBOutlet weak var savePlaceButtonsContainerView: UIView!
    @IBOutlet weak var resetSavedLocationButton: UIButton!
    
    @IBOutlet weak var keyboardInputTextField: UITextField!
    @IBOutlet weak var textInputTypeImageIcon: UIImageView!
    
    @IBOutlet weak var temperatureImageIcon: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var nearbyPeopleMapView: MKMapView!
    
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantDistanceLabel: UILabel!
    @IBOutlet weak var foodImageLeft: UIImageView!
    @IBOutlet weak var foodImageRight: UIImageView!
    @IBOutlet weak var foodImageCenter: UIImageView!
    @IBOutlet weak var restaurantAddressLabel: UILabel!
    
    @IBOutlet weak var poiNameLabel: UILabel!
    @IBOutlet weak var poiDistanceLabel: UILabel!
    @IBOutlet weak var gasImageLeft: UIImageView!
    @IBOutlet weak var gasImageRight: UIImageView!
    @IBOutlet weak var gasImageCenter: UIImageView!
    @IBOutlet weak var poiAddressLabel: UILabel!
    
    @IBOutlet weak var numberOfPlacesFound: UIButton!
    
    @IBOutlet weak var sunriseSunsetTimeLabel: UILabel!
    
    let googleAPIKey = "INSERT_YOUR_KEY_HERE" // You can register for a free Google API Key here: https://console.developers.google.com
    
    var currentAddress: AddressEntry?
    var currentLocation: LocationEntry?
    var currentActivity: ActivityEntry?
    var currentWeather: WeatherEntry?
    var currentRestaurant: PlaceEntry?
    var currentOtherPOI: PlaceEntry?
    var currentPlaces: [PlaceEntry]?
    
    var personMapAnnotations = [PersonMapAnnotation]()
    var lastLocationForMapRefresh: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nearbyPeopleMapView.delegate = self

        Trnql.apiKey = "INSERT_YOUR_KEY_HERE" // You can register for a trnql API Key here: http://appserver.trnql.com:9090/developer_dashboard/dashboard.jsp
        SmartPeople.setSearchRadius(radius: 25, units: .Mile)
        SmartPeople.userToken = "Interplay User"
        
        let backItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        currentAddressLabel.text = "Updating location..."
        temperatureLabel.text = "Updating weather..."
        sunriseSunsetTimeLabel.text = "Updating weather..."
        
        let imageCornerRadius:CGFloat = 10
        foodImageLeft.layer.cornerRadius = imageCornerRadius
        foodImageCenter.layer.cornerRadius = imageCornerRadius
        foodImageRight.layer.cornerRadius = imageCornerRadius
        gasImageLeft.layer.cornerRadius = imageCornerRadius
        gasImageCenter.layer.cornerRadius = imageCornerRadius
        gasImageRight.layer.cornerRadius = imageCornerRadius
        
        restaurantNameLabel.text = "Searching for places..."
        restaurantDistanceLabel.text = ""
        foodImageLeft.hidden = true
        foodImageCenter.hidden = true
        foodImageRight.hidden = true
        poiNameLabel.text = "Searching for places..."
        poiDistanceLabel.text = ""
        gasImageLeft.hidden = true
        gasImageCenter.hidden = true
        gasImageRight.hidden = true
        
        navigationController?.navigationBar.translucent = false
        
        Trnql.addDelegate(self)
        SmartPlaces.includeImages = true
        SmartPlaces.types = [PlaceType.RESTAURANT, PlaceType.GAS_STATION, PlaceType.ATM, PlaceType.GROCERY_OR_SUPERMARKET, PlaceType.PARKING, PlaceType.PARK]
        Trnql.startAllServices() // Starts all services
        
        updateLocationBanner(UIImage(named: "earth")!)
        
        updateLocationCardUI(nil)
        updateActivityCardUI(nil)
        updateWeatherCardUIs(nil)
        
        
    }
    
    func updateLocationCardUI(address: AddressEntry?) {
        
        dispatch_async(dispatch_get_main_queue(), {
            if let address = address?.address {
                
                let homeAddress = (NSUserDefaults.standardUserDefaults().objectForKey("homeAddress") as? String) ?? ""
                let workAddress = (NSUserDefaults.standardUserDefaults().objectForKey("workAddress") as? String) ?? ""
                
                if address == homeAddress {
                    self.currentAddressLabel.text = "Home Sweet Home.\n\(address)"
                    self.locationImageIcon.image = UIImage(named: "home")
                    self.promptToSaveAddress(false)
                }
                else if address == workAddress {
                    self.currentAddressLabel.text = "You are at work. Stop slacking off!\n\(address)"
                    self.locationImageIcon.image = UIImage(named: "work")
                    self.promptToSaveAddress(false)
                }
                else {
                    self.currentAddressLabel.text = "You are currently at: \(address)"
                    self.locationImageIcon.image = UIImage(named: "placemark")
                    self.promptToSaveAddress(true)
                }
            }
            else {
                self.currentAddressLabel.text = "Location unknown"
                self.locationImageIcon.image = UIImage(named: "placemark")
                self.promptToSaveAddress(false)
            }
            
            if let lat = address?.latitude, lon = address?.longitude {
                
                let numberOfAPICalls = NSUserDefaults.standardUserDefaults().integerForKey("numberOfAPICalls")
                if numberOfAPICalls > 2 { // If there have already been 2 calls, check if sufficient time has passed to allow another API call
                    
                    if let timeOfLastAPICall = NSUserDefaults.standardUserDefaults().objectForKey("timeOfLastAPICall") as? NSDate {
                        
                        if NSDate().timeIntervalSinceDate(timeOfLastAPICall) > 120 {
                            self.updateLocationBanner(lat, lon)
                            NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "numberOfAPICalls")
                            NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "timeOfLastAPICall")
                        }
                    }
                    else {
                        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "timeOfLastAPICall")
                    }
                }
                else {
                    self.updateLocationBanner(lat, lon)
                    NSUserDefaults.standardUserDefaults().setInteger(numberOfAPICalls + 1, forKey: "numberOfAPICalls")
                    NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "timeOfLastAPICall")
                }
                
            }
            
            if let locality = address?.locality {
                self.title = "You are in \(locality)"
            }
            
            
        })
    }
    
    func updateLocationBanner(lat: Double, _ lon: Double) {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            
            if let image = self.getStreetViewImage(lat, lon) {
                self.updateLocationBanner(image)
            }
            else if let image = self.getPlacesImage(lat, lon) {
                self.updateLocationBanner(image)
            }
        })
    }
    
    func updateLocationBanner(image: UIImage) {
        
        dispatch_async(dispatch_get_main_queue(), {
            
            self.locationImageBackdrop.image = image
            
        })
    }
    
    func getStreetViewImage(lat: Double, _ lon: Double) -> UIImage? {
        
        let streetMapsUrl = "https://maps.googleapis.com/maps/api/streetview?size=400x400&location=\(lat),\(lon)&key=\(googleAPIKey)&fov=90&heading=150&pitch=10"
        if let data = NSData(contentsOfURL: NSURL(string: streetMapsUrl)!) {
            // The Google Street View Image API will return a placeholder image stating "Sorry we have no imagery here" if no images are available. This placeholder image is around 5000 bytes but has fluctuated slightly. Real place images are much larger. To be safe we are making sure that the image received is at least 7500 bytes which would indiciate that it most likely is a real place image.
            if data.length > 7500 {
                return UIImage(data: data)
            }
        }
        return nil
    }
    
    func getPlacesImage(lat: Double, _ lon: Double) -> UIImage? {
        
        let placesURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lon)&radius=500&key=\(googleAPIKey)"
        
        if let data = NSData(contentsOfURL: NSURL(string: placesURL)!) {
            
            let json = JSON(data: data)
            if let places = json["results"].array where places.count > 0 {
                
                for place in places {
                    
                    if let photos = place["photos"].array where photos.count > 0 {
                        if let reference = photos[0]["photo_reference"].string {
                            
                            let photoURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=500&photoreference=\(reference)&key=\(googleAPIKey)"
                            if let imageData = NSData(contentsOfURL: NSURL(string: photoURL)!), image = UIImage(data: imageData) {
                                return image
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func promptToSaveAddress(b: Bool) {
        
        if b {
            saveLocationPromptLabel.hidden = false
            savePlaceButtonsContainerView.hidden = false
            resetSavedLocationButton.hidden = true
        }
        else {
            saveLocationPromptLabel.hidden = true
            savePlaceButtonsContainerView.hidden = true
            resetSavedLocationButton.hidden = false
        }
    }
    
    func updateActivityCardUI(activityEntry: ActivityEntry?) {
        
        dispatch_async(dispatch_get_main_queue(), {
            if let activityEntry = activityEntry {
                
                if activityEntry.stationary || activityEntry.onFoot {
                    self.keyboardInputTextField.placeholder = "Keyboard Input Enabled (User is \(activityEntry.activityString))"
                    self.textInputTypeImageIcon.image = UIImage(named: "keyboard")
                    self.keyboardInputTextField.enabled = true
                }
                else {
                    self.keyboardInputTextField.placeholder = "Keyboard Input Disabled (User is \(activityEntry.activityString))"
                    self.textInputTypeImageIcon.image = UIImage(named: "microphone")
                    self.keyboardInputTextField.enabled = false
                }
            }
            else {
                
                self.keyboardInputTextField.placeholder = "Keyboard Input Enabled (User Activity Unknown)"
                self.textInputTypeImageIcon.image = UIImage(named: "keyboard")
                self.keyboardInputTextField.enabled = true
            }
            
            
        })
    }
    
    func updateWeatherCardUIs(weatherEntry: WeatherEntry?) {
        
        dispatch_async(dispatch_get_main_queue(), {
            if let weatherEntry = weatherEntry {
                
                // Temperature Card
                if let temp = weatherEntry.feelsLikeTemp {
                    
                    if temp >= 85 {
                        self.temperatureLabel.text = "It's hot, hot!"
                        self.temperatureImageIcon.image = UIImage(named: "fire")
                    }
                    else if temp >= 75 {
                        self.temperatureLabel.text = "It's nice out!"
                        self.temperatureImageIcon.image = UIImage(named: "sun")
                    }
                    else if temp >= 70 {
                        self.temperatureLabel.text = "It's neither hot nor cold"
                        self.temperatureImageIcon.image = UIImage(named: "thermometer")
                    }
                    else if temp >= 58 {
                        self.temperatureLabel.text = "It's cold enough to wear a sweater"
                        self.temperatureImageIcon.image = UIImage(named: "sweater")
                    }
                    else if temp >= 40 {
                        self.temperatureLabel.text = "It's cold enough to wear a jacket"
                        self.temperatureImageIcon.image = UIImage(named: "jacket")
                    }
                    else if temp > 32 {
                        self.temperatureLabel.text = "Baby it's cold outside!"
                        self.temperatureImageIcon.image = UIImage(named: "snowflake")
                    }
                    else {
                        self.temperatureLabel.text = "It's freezing (literally)!"
                        self.temperatureImageIcon.image = UIImage(named: "snowflake")
                    }
                }
                else {
                    self.temperatureLabel.text = "The temperature is unknown"
                    self.temperatureImageIcon.image = UIImage(named: "thermometer")
                }
                
                // Determine sunrise/sunset time
                if let sunrise = weatherEntry.sunriseTime, sunset = weatherEntry.sunsetTime {
                    
                    let now = NSDate()
                    let calendar = NSCalendar.currentCalendar()
                    
                    if sunrise.compare(now) == NSComparisonResult.OrderedDescending {
                        let timeRemaining = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: now, toDate: sunrise, options: [])
                        self.sunriseSunsetTimeLabel.text = "\(timeRemaining.hour) \(timeRemaining.hour != 1 ? "Hours" : "Hour"), \(timeRemaining.minute) \(timeRemaining.minute != 1 ? "Minutes" : "Minute") Until Sunrise"
                    }
                    else if sunrise.compare(now) == NSComparisonResult.OrderedSame{
                        self.sunriseSunsetTimeLabel.text = "The sunrise is now!"
                    }
                    else if sunset.compare(now) == NSComparisonResult.OrderedDescending {
                        let timeRemaining = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: now, toDate: sunset, options: [])
                        self.sunriseSunsetTimeLabel.text = "\(timeRemaining.hour) \(timeRemaining.hour != 1 ? "Hours" : "Hour"), \(timeRemaining.minute) \(timeRemaining.minute != 1 ? "Minutes" : "Minute") Until Sunset"
                    }
                    else if sunset.compare(now) == NSComparisonResult.OrderedSame{
                        self.sunriseSunsetTimeLabel.text = "The sunset is now!"
                    }
                    else if sunset.compare(now) == NSComparisonResult.OrderedAscending {
                        if let sunsetTime = weatherEntry.sunsetTimeString {
                            self.sunriseSunsetTimeLabel.text = "The sunset was at \(sunsetTime)."
                        }
                        else {
                            self.sunriseSunsetTimeLabel.text = "The sunset has passed."
                        }
                    }
                }
            }
            else {
                self.temperatureLabel.text = "The temperature is unknown"
                self.sunriseSunsetTimeLabel.text = "Sunrise/sunset time is unknown"
            }
            
            
            
        })
    }
    
    func updatePlaceCardUIs(places: [PlaceEntry]) {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            
            if places.count > 0 {
                
                self.numberOfPlacesFound.setTitle("Found \(places.count) Places Nearby", forState: .Normal)
                
                
                var restaurants = [PlaceEntry]()
                var otherPOIs = [PlaceEntry]()
                
                for place in places {
                    
                    
                    if let types = place.types {
                        if types.contains(PlaceType.RESTAURANT) {
                            restaurants.append(place)
                        }
                        else {
                            otherPOIs.append(place)
                        }
                    }
                }
                
                // RESTAURANT
                if restaurants.count > 0 {
                    
                    var restaurant: PlaceEntry?
                    var numOfRestaurantPhotos = 0
                    
                    var numberOfPhotosRequired = 2
                    repeat {
                        
                        if numberOfPhotosRequired > 0 {
                            
                            for theRestaurant in restaurants {
                                
                                let numOfPhotos = theRestaurant.images != nil ? theRestaurant.images!.count : 0
                                if numOfPhotos >= numberOfPhotosRequired {
                                    restaurant = theRestaurant
                                    numOfRestaurantPhotos = numOfPhotos
                                    break
                                }
                            }
                            numberOfPhotosRequired -= 1
                        }
                        else {
                            restaurant = restaurants[Int(arc4random_uniform(UInt32(restaurants.count)))]
                            numOfRestaurantPhotos = 0
                        }
                    } while restaurant == nil
                    
                    if let restaurant = restaurant {
                        
                        self.currentRestaurant = restaurant
                        
                        if numOfRestaurantPhotos > 0 {
                            
                            let photos = restaurant.images!
                            if numOfRestaurantPhotos > 1 {
                                
                                let randomPhotoIndex1 = Int(arc4random_uniform(UInt32(photos.count)))
                                var randomPhotoIndex2: Int
                                repeat {
                                    randomPhotoIndex2 = Int(arc4random_uniform(UInt32(photos.count)))
                                } while randomPhotoIndex1 == randomPhotoIndex2
                                
                                let photo1 = photos[randomPhotoIndex1]
                                let photo2 = photos[randomPhotoIndex2]
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.restaurantNameLabel.text = restaurant.name ?? ""
                                    self.restaurantDistanceLabel.text = self.distanceFromUserString(restaurant)
                                    self.restaurantAddressLabel.text = restaurant.address ?? ""
                                    self.foodImageCenter.hidden = true
                                    self.foodImageLeft.hidden = false
                                    self.foodImageRight.hidden = false
                                    self.foodImageLeft.image = photo1
                                    self.foodImageRight.image = photo2
                                    
                                })
                            }
                            else {
                                
                                let randomPhotoIndex1 = Int(arc4random_uniform(UInt32(photos.count)))
                                let photo1 = photos[randomPhotoIndex1]
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.restaurantNameLabel.text = restaurant.name ?? ""
                                    self.restaurantDistanceLabel.text = self.distanceFromUserString(restaurant)
                                    self.restaurantAddressLabel.text = restaurant.address ?? ""
                                    self.foodImageCenter.hidden = false
                                    self.foodImageLeft.hidden = true
                                    self.foodImageRight.hidden = true
                                    self.foodImageCenter.image = photo1
                                    
                                })
                            }
                        }
                        else {
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self.restaurantNameLabel.text = restaurant.name ?? ""
                                self.restaurantDistanceLabel.text = self.distanceFromUserString(restaurant)
                                self.restaurantAddressLabel.text = restaurant.address ?? ""
                                self.foodImageCenter.hidden = false
                                self.foodImageLeft.hidden = true
                                self.foodImageRight.hidden = true
                                self.foodImageCenter.image = nil
                                
                            })
                        }
                    }
                }
                else {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.restaurantNameLabel.text = "Searching for places..."
                        self.restaurantDistanceLabel.text = ""
                        self.restaurantAddressLabel.text = ""
                        self.foodImageCenter.hidden = true
                        self.foodImageLeft.hidden = true
                        self.foodImageRight.hidden = true
                        
                    })
                }
                
                // GAS STATION
                if otherPOIs.count > 0 {
                    
                    var otherPOI: PlaceEntry?
                    var numOfOtherPOIPhotos = 0
                    
                    var numberOfPhotosRequired = 2
                    repeat {
                        
                        if numberOfPhotosRequired > 0 {
                            
                            for thePOI in otherPOIs {
                                
                                let numOfPhotos = thePOI.images != nil ? thePOI.images!.count : 0
                                if numOfPhotos >= numberOfPhotosRequired {
                                    otherPOI = thePOI
                                    numOfOtherPOIPhotos = numOfPhotos
                                    break
                                }
                            }
                            numberOfPhotosRequired -= 1
                        }
                        else {
                            otherPOI = otherPOIs[Int(arc4random_uniform(UInt32(otherPOIs.count)))]
                            numOfOtherPOIPhotos = 0
                        }
                    } while otherPOI == nil
                    
                    if let poi = otherPOI {
                        
                        self.currentOtherPOI = poi
                        
                        if numOfOtherPOIPhotos > 0 {
                            
                            let photos = poi.images!
                            if numOfOtherPOIPhotos > 1 {
                                
                                let randomPhotoIndex1 = Int(arc4random_uniform(UInt32(photos.count)))
                                var randomPhotoIndex2: Int
                                repeat {
                                    randomPhotoIndex2 = Int(arc4random_uniform(UInt32(photos.count)))
                                } while randomPhotoIndex1 == randomPhotoIndex2
                                
                                let photo1 = photos[randomPhotoIndex1]
                                let photo2 = photos[randomPhotoIndex2]
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.poiNameLabel.text = poi.name ?? ""
                                    self.poiDistanceLabel.text = self.distanceFromUserString(poi)
                                    self.poiAddressLabel.text = poi.address ?? ""
                                    self.gasImageCenter.hidden = true
                                    self.gasImageLeft.hidden = false
                                    self.gasImageRight.hidden = false
                                    self.gasImageLeft.image = photo1
                                    self.gasImageRight.image = photo2
                                    
                                })
                            }
                            else {
                                
                                let randomPhotoIndex1 = Int(arc4random_uniform(UInt32(photos.count)))
                                let photo1 = photos[randomPhotoIndex1]
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.poiNameLabel.text = poi.name ?? ""
                                    self.poiDistanceLabel.text = self.distanceFromUserString(poi)
                                    self.poiAddressLabel.text = poi.address ?? ""
                                    self.gasImageCenter.hidden = false
                                    self.gasImageLeft.hidden = true
                                    self.gasImageRight.hidden = true
                                    self.gasImageCenter.image = photo1
                                    
                                })
                            }
                        }
                        else {
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self.poiNameLabel.text = poi.name ?? ""
                                self.poiDistanceLabel.text = self.distanceFromUserString(poi)
                                self.poiAddressLabel.text = poi.address ?? ""
                                self.gasImageCenter.hidden = false
                                self.gasImageLeft.hidden = true
                                self.gasImageRight.hidden = true
                                self.gasImageCenter.image = nil
                                
                            })
                        }
                    }
                }
                else {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.poiNameLabel.text = ""
                        self.poiDistanceLabel.text = ""
                        self.poiAddressLabel.text = ""
                        self.gasImageCenter.hidden = true
                        self.gasImageLeft.hidden = true
                        self.gasImageRight.hidden = true
                        
                    })
                }
            }
        })
    }
    
    func distanceFromUserString(place: PlaceEntry) -> String {
        if let distance = place.distanceFromUser(inUnits: .Meter) {
            return "\(Int(distance))m away"
        }
        return ""
    }
    
    
    //MARK: TrnqlDelegate Methods
    
    func smartActivityChange(userActivity: ActivityEntry?, error: NSError?) {
        
        if let error = error {
            print(error)
        }
        else if let userActivity = userActivity {
            currentActivity = userActivity
            updateActivityCardUI(userActivity)
        }
    }
    
    func smartAddressChange(address: AddressEntry?, error: NSError?) {
        
        if let error = error {
            print(error)
        }
        else if let address = address {
            currentAddress = address
            updateLocationCardUI(address)
        }
    }
    
    func smartLocationChange(location: LocationEntry?, error: NSError?) {
        
        if let error = error {
            print(error)
        }
        else if let locationEntry = location {
            // Center the map view around user on first location update only
            if currentLocation == nil {
                currentLocation = locationEntry
                if let coordinate = currentLocation?.location?.coordinate {
                    let regionRadius = SmartPeople.searchRadius
                    let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius, regionRadius)
                    nearbyPeopleMapView.setRegion(coordinateRegion, animated: true)
                }
            }
            currentLocation = locationEntry
            
            // Update map annotation every 1500 meters
            if let currentLocation = location?.location {
                if let lastLocationForMapRefresh = lastLocationForMapRefresh {
                    if lastLocationForMapRefresh.distanceFromLocation(currentLocation) >= 1500 || nearbyPeopleMapView.annotations.count == 0 {
                        if nearbyPeopleMapView.annotations.count > 0 {
                            nearbyPeopleMapView.removeAnnotations(self.nearbyPeopleMapView.annotations)
                        }
                        nearbyPeopleMapView.addAnnotations(personMapAnnotations)
                        self.lastLocationForMapRefresh = currentLocation
                    }
                }
                else {
                    nearbyPeopleMapView.addAnnotations(personMapAnnotations)
                    self.lastLocationForMapRefresh = currentLocation
                }
            }
            
        }
    }
    
    func smartPeopleChange(people: [PersonEntry]?, error: NSError?) {
        
        if let error = error {
            print(error)
        }
        else if let people = people {
            
            personMapAnnotations = [PersonMapAnnotation]()
            for person in people {
                personMapAnnotations.append(PersonMapAnnotation(person: person))
            }
        }
    }
    
    func smartPlacesChange(places: [PlaceEntry]?, error: NSError?) {
        
        if let error = error {
            print(error)
        }
        else if let places = places {
            currentPlaces = places
            updatePlaceCardUIs(places)
        }
    }
    
    func smartWeatherChange(weather: WeatherEntry?, error: NSError?) {
        
        if let error = error {
            print(error)
        }
        else if let weather = weather {
            updateWeatherCardUIs(weather)
            currentWeather = weather
        }
    }
    
    //MARK: IBActions
    
    @IBAction func setLocationAsHome(sender: UIButton) {
        
        if let currentAddressString = currentAddress?.address {
            NSUserDefaults.standardUserDefaults().setObject(currentAddressString, forKey: "homeAddress")
            updateLocationCardUI(currentAddress)
        }
        else {
            updateLocationCardUI(nil)
        }
        
    }
    
    @IBAction func setLocationAsWork(sender: UIButton) {
        
        if let currentAddressString = currentAddress?.address {
            NSUserDefaults.standardUserDefaults().setObject(currentAddressString, forKey: "workAddress")
            updateLocationCardUI(currentAddress)
        }
        else {
            updateLocationCardUI(nil)
        }
        
    }
    
    @IBAction func resetSavedLocation(sender: UIButton) {
        
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "homeAddress")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "workAddress")
        if let _ = currentAddress?.address {
            updateLocationCardUI(currentAddress)
        }
        else {
            updateLocationCardUI(nil)
        }
        
    }
    
    @IBAction func showSmartLocationDataset(sender: UIButton) {
        
        var dataset = [String]()
        
        if let currentLocation = currentLocation {
            
            if let altitude = currentLocation.altitude {
                dataset.append("Altitude: \(altitude)")
            }
            else {
                dataset.append("Altitude: ")
            }
            
            if let bearing = currentLocation.bearing {
                dataset.append("Bearing: \(bearing)")
            }
            else {
                dataset.append("Bearing: ")
            }
            
            if let speed = currentLocation.speed {
                dataset.append("Speed: \(speed)")
            }
            else {
                dataset.append("Speed: ")
            }
            
            if let time = currentLocation.time {
                dataset.append("Time: \(time)")
            }
            else {
                dataset.append("Time: ")
            }
        }
        
        if let currentAddress = currentAddress {
            
            let lat = "\(currentAddress.latitude)"
            dataset.append("Latitude: \(lat)")
            
            let long = "\(currentAddress.longitude)"
            dataset.append("Longitude: \(long)")
            
            let county = currentAddress.subAdminArea ?? ""
            dataset.append("County: \(county)")
            
            let country = currentAddress.countryName ?? ""
            dataset.append("Country: \(country)")
            
            let countryCode = currentAddress.countryCode ?? ""
            dataset.append("Country Code: \(countryCode)")
            
            let name = currentAddress.featureName ?? ""
            dataset.append("Name: \(name)")
            
            let address = currentAddress.address ?? ""
            dataset.append("Address: \(address)")
            
            dataset.append("Learn how at trnql.com/guides")
            
            if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("DatasetTableViewController") as? DatasetTableViewController {
                vc.dataset = dataset
                vc.title = "Location Data"
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    @IBAction func showSmartActivityDataset(sender: UIButton) {
        
        if let currentActivity = currentActivity {
            
            var dataset = [String]()
            
            dataset.append("In Vehicle: \(currentActivity.automotive)")
            dataset.append("On Bicycle: \(currentActivity.cycling)")
            dataset.append("Is Walking: \(currentActivity.walking)")
            dataset.append("Is Running: \(currentActivity.running)")
            dataset.append("On Foot: \(currentActivity.onFoot)")
            dataset.append("Is Still: \(currentActivity.stationary)")
            
            dataset.append("Learn how at trnql.com/guides")
            
            if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("DatasetTableViewController") as? DatasetTableViewController {
                vc.dataset = dataset
                vc.title = "Activity Data"
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
        }
    }
    
    @IBAction func showSmartWeatherDataset(sender: UIButton) {
        
        if let currentWeather = currentWeather {
            
            var dataset = [String]()
            
            let currentConditions = currentWeather.currentConditionsDescriptionString ?? ""
            dataset.append("Current Conditions: \(currentConditions)")
            
            let hiLo = currentWeather.highLowString ?? ""
            dataset.append("High/Low: \(hiLo)")
            
            let feelsLike = currentWeather.feelsLikeTempString ?? ""
            dataset.append("Feels Like: \(feelsLike)")
            
            dataset.append("10 Day Forecast:")
            
            // 10 Day Weather Forecast
            if let weatherForecastArray = currentWeather.weatherForecastArray {
                
                var weatherString = " - "
                for day in weatherForecastArray {
                    if let prediction = day.dayShortPrediction {
                        weatherString += "\(prediction) - "
                    }
                    else if let prediction = day.nightShortPrediction {
                        weatherString += "\(prediction) - "
                    }
                    
                    if let highTemp = day.highTempString {
                        weatherString += "Hi: \(highTemp) "
                    }
                    
                    if let lowTemp = day.lowTempString {
                        weatherString += "Lo: \(lowTemp)"
                    }
                    dataset.append(weatherString)
                    weatherString = " - "
                }
            }
            
            let rain = currentWeather.rainString ?? ""
            dataset.append("Rain: \(rain)")
            
            let wind = currentWeather.windString ?? ""
            dataset.append("Wind: \(wind)")
            
            let uvIndex = currentWeather.uvIndexString ?? ""
            dataset.append("UV Index: \(uvIndex)")
            
            let humidity = currentWeather.humidityString ?? ""
            dataset.append("Humidity: \(humidity)")
            
            let sunrise = currentWeather.sunriseTimeString ?? ""
            dataset.append("Sunrise: \(sunrise)")
            
            let sunset = currentWeather.sunsetTimeString ?? ""
            dataset.append("Sunset: \(sunset)")
            
            dataset.append("Learn how at trnql.com/guides")
            
            if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("DatasetTableViewController") as? DatasetTableViewController {
                vc.dataset = dataset
                vc.title = "Weather Data"
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            
        }
    }
    
    
    @IBAction func showSmartPlaceRestaurantDataset(sender: UIButton) {
        
        var dataset = [String]()
        
        dataset.append(currentRestaurant?.name ?? "-")
        dataset.append(currentRestaurant?.address ?? "-")
        dataset.append(currentRestaurant?.phoneNumber ?? "-")
        
        if let lat = currentRestaurant?.latitude {
            dataset.append("\(lat)")
        }
        else {
            dataset.append("-")
        }
        
        if let lon = currentRestaurant?.longitude {
            dataset.append("\(lon)")
        }
        else {
            dataset.append("-")
        }
        
        dataset.append(currentRestaurant?.intlPhoneNumber ?? "-")
        
        if let rating = currentRestaurant?.rating {
            dataset.append("\(rating)")
        }
        else {
            dataset.append("-")
        }
        
        if let val = currentRestaurant?.priceLevel {
            dataset.append("\(val)")
        }
        else {
            dataset.append("-")
        }
        
        if let val = currentRestaurant?.reviews where val.count > 0 {
            for review in val {
                dataset.append("\(review.text ?? "-")")
            }
        }
        else {
            dataset.append("-")
        }
        
        if let tags = currentRestaurant?.types where tags.count > 0 {
            dataset.append(tags.joinWithSeparator(", "))
        }
        else {
            dataset.append("-")
        }
        
        dataset.append(currentRestaurant?.googleMapsURL ?? "-")
        dataset.append(currentRestaurant?.vicinity ?? "-")
        dataset.append(currentRestaurant?.website ?? "-")
        
        dataset.append("Learn how at trnql.com/guides")
        
        if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("DatasetTableViewController") as? DatasetTableViewController {
            vc.dataset = dataset
            if let restaurantName = currentRestaurant?.name {
                vc.title = "\(restaurantName) Data"
            }
            else {
                vc.title = "Restaurant Data"
            }
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func showSmartPlaceOtherDataset(sender: UIButton) {
        
        var dataset = [String]()
        
        dataset.append(currentOtherPOI?.name ?? "-")
        dataset.append(currentOtherPOI?.address ?? "-")
        dataset.append(currentOtherPOI?.phoneNumber ?? "-")
        
        if let lat = currentOtherPOI?.latitude {
            dataset.append("\(lat)")
        }
        else {
            dataset.append("-")
        }
        
        if let lon = currentOtherPOI?.longitude {
            dataset.append("\(lon)")
        }
        else {
            dataset.append("-")
        }
        
        dataset.append(currentOtherPOI?.intlPhoneNumber ?? "-")
        
        if let rating = currentOtherPOI?.rating {
            dataset.append("\(rating)")
        }
        else {
            dataset.append("-")
        }
        
        if let val = currentOtherPOI?.priceLevel {
            dataset.append("\(val)")
        }
        else {
            dataset.append("-")
        }
        
        if let val = currentOtherPOI?.reviews where val.count > 0 {
            for review in val {
                dataset.append("\(review.text ?? "-")")
            }
        }
        else {
            dataset.append("-")
        }
        
        if let tags = currentOtherPOI?.types where tags.count > 0 {
            dataset.append(tags.joinWithSeparator(", "))
        }
        else {
            dataset.append("-")
        }
        
        dataset.append(currentOtherPOI?.googleMapsURL ?? "-")
        dataset.append(currentOtherPOI?.vicinity ?? "-")
        dataset.append(currentOtherPOI?.website ?? "-")
        
        dataset.append("Learn how at trnql.com/guides")
        
        if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("DatasetTableViewController") as? DatasetTableViewController {
            vc.dataset = dataset
            if let poiName = currentOtherPOI?.name {
                vc.title = "\(poiName) Data"
            }
            else {
                vc.title = "POI Data"
            }
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func showSmartPlacesAllPlacesNames(sender: UIButton) {
        
        var dataset = [String]()
        
        if let places = currentPlaces {
            for place in places {
                dataset.append(place.name ?? "-")
            }
        }
        
        dataset.append("Learn how at trnql.com/guides")
        
        if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("DatasetTableViewController") as? DatasetTableViewController {
            vc.dataset = dataset
            vc.title = "Places Dataset"
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    @IBAction func dismissSplashScreen(segue:UIStoryboardSegue) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasDisplayedSplashScreen")
    }
    
    //MARK: - MapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? PersonMapAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            }
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

        if let annotation = view.annotation as? PersonMapAnnotation {
            let person = annotation.person
            var dataset = [String]()
            
            dataset.append(person.userActivity ?? "No User Activity")
            dataset.append("\(person.latitude)")
            dataset.append("\(person.longitude)")
            dataset.append(person.dataPayload ?? "No Data Payload")
            dataset.append(person.userToken ?? "No User Token")
            dataset.append(person.platform ?? "No Platform")
            dataset.append("\(person.timestamp)")
            
            
            dataset.append("Learn how at trnql.com/guides")
            
            if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("DatasetTableViewController") as? DatasetTableViewController {
                vc.dataset = dataset
                vc.title = "Person Dataset"
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

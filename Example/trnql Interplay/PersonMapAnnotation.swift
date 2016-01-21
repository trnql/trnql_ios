//
//  PersonMapAnnotation.swift
//  trnql Interplay
//
//  Created by Jonathan Sahoo on 11/21/15.
//  Copyright © 2015 trnql. All rights reserved.
//

import MapKit
import trnql

class PersonMapAnnotation: NSObject, MKAnnotation {
    
    //MKAnnotationDelegate Fields
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let person: PersonEntry
    
    init(person: PersonEntry) {
        self.person = person
        title = person.userToken ?? "Unknown User"
        subtitle = person.userActivity ?? "Activity Unknown"
        if let lat = person.latitude, lon = person.longitude {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        else {
            coordinate = CLLocationCoordinate2D()
        }
        super.init()
    }
    

}

//
//  PassengerAnnotation.swift
//  Ride
//
//  Created by mohamed fawzy on 1/2/19.
//  Copyright © 2019 mohamed fawzy. All rights reserved.
//

import UIKit
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation {
    
   dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
     init(coordinate: CLLocationCoordinate2D, key: String) {
        self.coordinate = coordinate
        self.key = key
    }
}

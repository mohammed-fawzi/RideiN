//
//  DriverAnnotation.swift
//  Ride
//
//  Created by mohamed fawzy on 12/31/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import Foundation
import MapKit


class DriverAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var driverID: String
    
    init(coordinate: CLLocationCoordinate2D, driverID: String) {
        self.coordinate = coordinate
        self.driverID = driverID
    }
    
    
    func update(withCoordinate coordinate: CLLocationCoordinate2D){
        let location = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        UIView.animate(withDuration: 0.2) {
            self.coordinate = location
        }
    }
    
    
}

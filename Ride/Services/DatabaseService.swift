//
//  DatabaseService.swift
//  Ride
//
//  Created by mohamed fawzy on 12/28/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit
import Firebase
import MapKit



 let databaseReference =  Database.database().reference()

final class DatabaseService {
    
    static let instance = DatabaseService()
    
    private init(){}
    
    private let DATABASE_REF = databaseReference
    private let USER_REF = databaseReference.child("users")
    private let DRIVER_REF = databaseReference.child("drivers")
    private let TRIPS_REF = databaseReference.child("trips")
    
    var databaseRef : DatabaseReference {
        return DATABASE_REF
    }
    
    var usersRef: DatabaseReference {
        return USER_REF
    }
    
    var driversRef: DatabaseReference {
        return DRIVER_REF
    }
    
    var tripsRef: DatabaseReference {
        return TRIPS_REF
    }
    
    
    func createFirebaseDBUser(uID: String, userData: Dictionary<String,Any>, isDriver: Bool){
        if isDriver {
            driversRef.child(uID).updateChildValues(userData)
        }else {
            usersRef.child(uID).updateChildValues(userData)
        }
    }
    
    func updateUserLocation(userID: String, withCoordinate coordinate: CLLocationCoordinate2D ){
      
            usersRef.child(userID).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists()  {
                    self.usersRef.child(userID).updateChildValues([kCOORDINATES: [coordinate.latitude,coordinate.longitude]])
                }
            }
   
    }
    
    func updateDriverLocation(userID: String, withCoordinate coordinate: CLLocationCoordinate2D ){
            
            driversRef.child(userID).observeSingleEvent(of: .value) { (snapshot) in
                
                if snapshot.exists() {
                    
                    if  snapshot.childSnapshot(forPath: kIS_PICKUP_MODE_ENABLED).value as! Bool {
                        self.driversRef.child(userID).updateChildValues([kCOORDINATES: [coordinate.latitude,coordinate.longitude]])
                    }
                }

            }
     
    }
    
    func loadDriverAnnotaitonsFromDB(mapView: MKMapView){
       driversRef.observeSingleEvent(of: .value) { (snapshot) in
            for snapshot in snapshot.children.allObjects as! [DataSnapshot] {

                if snapshot.hasChild(kCOORDINATES) {
                  if  snapshot.childSnapshot(forPath: kIS_PICKUP_MODE_ENABLED).value as! Bool {

                    let driverDict = snapshot.value as! [String: Any]
                    let coordinateArray = driverDict[kCOORDINATES] as! [CLLocationDegrees]
                    let location = CLLocationCoordinate2D(latitude: coordinateArray[0], longitude: coordinateArray[1])

                    let driverAnnotation = DriverAnnotation(coordinate: location, driverID: snapshot.key)
                    
                    var driverIsVisible: Bool {
                        return mapView.annotations.contains(where: { (annotation) -> Bool in
                            if let driverAnnotation = annotation as? DriverAnnotation {
                                if  driverAnnotation.driverID == snapshot.key {
                                    driverAnnotation.update(withCoordinate: location)
                                    return true
                                }
                            }
                            return false
                        })
                    }
                    // if driver is not on the map add him
                    if !driverIsVisible {
                        mapView.addAnnotation(driverAnnotation)
                    }
                  }else {
                    // if pick up mode is not enabled remove driver annotation
                    for annotation in mapView.annotations {
                        if annotation.isKind(of: DriverAnnotation.self) {
                            if let annotation = annotation as? DriverAnnotation {
                                if annotation.driverID == snapshot.key {
                                    mapView.removeAnnotation(annotation)
                                }
                            }
                        }
                    }
                    }
                }
            }
        }
    }
    
//
//    func fetchDriversLocations(){
//        var locations: [CLLocationCoordinate2D] = []
//        driversRef.observeSingleEvent(of: .value) { (snapshot) in
//            for snapshot in snapshot.children.allObjects as! [DataSnapshot] {
//                if snapshot.hasChild(kCOORDINATES) {
//                    if let coordinate = snapshot.childSnapshot(forPath: kCOORDINATES).value as? [CLLocationCoordinate2D] {
//                        locations.append(contentsOf: coordinate)
//                    }
//                }
//                print("downloaded user.................")
//            }
//        }
//    }
    

    
}



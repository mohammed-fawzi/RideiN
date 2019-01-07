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



fileprivate let databaseReference =  Database.database().reference()

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
    
    
    //MARK:- users
    func createFirebaseDBUser(uID: String, userData: Dictionary<String,Any>, isDriver: Bool){
        if isDriver {
            driversRef.child(uID).updateChildValues(userData)
        }else {
            usersRef.child(uID).updateChildValues(userData)
        }
    }
    
    func updateUser(id: String, with userData: [String: Any]){
        
        usersRef.child(id).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists()  {
                self.usersRef.child(id).updateChildValues(userData)

            }
        }
        
    }
    
    func deleteFromUser(id: String, value: String){
        usersRef.child(id).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists()  {
                self.usersRef.child(id).child(value).removeValue()
                
            }
        }
    }
    
    func checkUser(id:String, forValue value: String, completion: @escaping (Bool) -> Void ){
        
        usersRef.child(id).child(value).observeSingleEvent(of: .value) { (snapShot) in
            if snapShot.exists() {
                completion(true)
            }else{
                completion(false)
            }
        }
    }
    
    func updateUserLocation(userID: String, withCoordinate coordinate: CLLocationCoordinate2D ){
      
            usersRef.child(userID).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists()  {
                    self.usersRef.child(userID).updateChildValues([kCOORDINATES: [coordinate.latitude,coordinate.longitude]])
                }
            }
   
    }
    
    
    func passengerIsOnTrip(passengerId: String, handler: @escaping (_ status: Bool, _ driverKey: String?, _ tripKey: String?) -> Void) {
        tripsRef.observe(.value, with: { (tripSnapshot) in
            if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                for trip in tripSnapshot {
                    if trip.key == passengerId {
                        if trip.childSnapshot(forPath: kTRIP_IS_ACCEPTED).value as? Bool == true {
                            let driverId = trip.childSnapshot(forPath: kDRIVERID).value as? String
                            handler(true, driverId, trip.key)
                        } else {
                            handler(false, nil, nil)
                        }
                    }
                }
            }
        })
    }
    
    //MARK:- drivers
    
    func userIsDriver(userId: String, handler: @escaping (_ status: Bool) -> Void) {
        
        driversRef.child(userId).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                handler(true)
            }else{
                handler(false)
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
    
    func driverIsAvailable(id:String, completion: @escaping (Bool?)-> Void){
        driversRef.child(id).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                if snapshot.childSnapshot(forPath: kIS_PICKUP_MODE_ENABLED).value as? Bool == true &&
                    snapshot.childSnapshot(forPath: kDRIVER_IS_ON_TRIP).value as? Bool == false {
                    completion(true)
                }else {
                    completion(false)
                }
            }
        }
    }
    
    func driverIsOnTrip(driverId: String, handler: @escaping (_ status: Bool, _ driverKey: String?, _ tripKey: String?) -> Void) {
        driversRef.child(driverId).child(kDRIVER_IS_ON_TRIP).observe(.value, with: { (driverTripStatusSnapshot) in
            if let driverTripStatusSnapshot = driverTripStatusSnapshot.value as? Bool {
                if driverTripStatusSnapshot == true {
                    self.tripsRef.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                        if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                            for trip in tripSnapshot {
                                if trip.childSnapshot(forPath: kDRIVERID).value as? String == driverId {
                                    handler(true, driverId, trip.key)
                                } else {
                                    return
                                }
                            }
                        }
                    })
                } else {
                    handler(false, nil, nil)
                }
            }
        })
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
    

    
    
    //MARK:- trips
    func createTrip(){
        if let userId = Auth.auth().currentUser?.uid {
            
            usersRef.child(userId).observeSingleEvent(of: .value) { (snapshot) in
                if let snapshot = snapshot.value as? [String: Any] {
                    let pickUpCoordinate = snapshot[kCOORDINATES] as! NSArray
                    let destinationCoordinate = snapshot[kDESTINATION_COORDINTE] as! NSArray
                    
                    let tripData = [kPICKUP_COORDINATE: pickUpCoordinate,
                                    kDESTINATION_COORDINTE: destinationCoordinate,
                                    kPASSENGER: userId,
                                    kTRIP_IS_ACCEPTED: false] as [String: Any]
                    self.tripsRef.child(userId).updateChildValues(tripData)

                }
            }
   
        }
    }
    
    func fetchTrip(forDriver driverId: String, completion: @escaping (_ trip: [String:Any]?)->Void){
        tripsRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                 for tripSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    if tripSnapshot.childSnapshot(forPath: kDRIVERID).value as? String == driverId {
                        completion(tripSnapshot.value as? [String:Any])
                    }
                }
            }
        }
    }
    
    func observeTrips(completion: @escaping ([String:Any]?)-> Void){
        
        tripsRef.observe(.value) { (snapshot) in
            if snapshot.exists() {
                
                for tripSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    if let tripDict = tripSnapshot.value as? [String: Any] {
                        completion(tripDict)
                    }
                }
            }
        }
    }
    
    func acceptTrip(withPassengerId passengerId: String,forDriverId driverId: String) {
        tripsRef.child(passengerId).updateChildValues([kTRIP_IS_ACCEPTED: true,
                                                       kDRIVERID: driverId])
        driversRef.child(driverId).updateChildValues([kDRIVER_IS_ON_TRIP: true])
    }
    
    func cancelTrip(withPassengerId passengerId: String,forDriverId driverId: String) {
        tripsRef.child(passengerId).removeValue()
        driversRef.child(driverId).updateChildValues([kDRIVER_IS_ON_TRIP: false])
        usersRef.child(passengerId).child(kDESTINATION_COORDINTE).removeValue()
    }
    
    
    
 
    
    
    

    
    
}



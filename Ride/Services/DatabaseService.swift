//
//  DatabaseService.swift
//  Ride
//
//  Created by mohamed fawzy on 12/28/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import Foundation
import Firebase


let databaseReference =  Database.database().reference()

final class DatabaseService {
    
    static let instance = DatabaseService()
    
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
    
}

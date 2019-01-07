//
//  PickUpViewController.swift
//  Ride
//
//  Created by mohamed fawzy on 1/3/19.
//  Copyright © 2019 mohamed fawzy. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class PickUpViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    let currentUserId = Auth.auth().currentUser?.uid
    
    var placeMark: MKPlacemark!
    var pickUpCoordinate: CLLocationCoordinate2D!
    var passengerId: String!
    
    
    func initData(coordinate:CLLocationCoordinate2D, passenger: String){
        self.pickUpCoordinate = coordinate
        self.passengerId = passenger
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        placeMark = MKPlacemark(coordinate: pickUpCoordinate)
        dropPinFor(placeMark: placeMark)
        centerMapOnLocation(location: placeMark.location!)
        
        
        DatabaseService.instance.tripsRef.child(passengerId).observe(.value) { (tripSnapshot) in
            if tripSnapshot.exists() {
                if tripSnapshot.childSnapshot(forPath: kTRIP_IS_ACCEPTED).value as! Bool {
                    self.dismiss(animated: true, completion: nil)
                }
            }else{
                self.dismiss(animated: true, completion: nil)
            }
        }

  

    }
    

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func acceptButtonTapped(_ sender: Any) {
        
        if let driverId = currentUserId {
            DatabaseService.instance.acceptTrip(withPassengerId: passengerId, forDriverId: driverId)

        }
    }
}



extension PickUpViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userAnnotation")
        annotationView.image = UIImage(named: "passengerPin")
        return annotationView
    }
    
}


extension PickUpViewController {
    
    func centerMapOnLocation(location: CLLocation){
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func dropPinFor(placeMark: MKPlacemark) {
        let userAnnotation = MKPointAnnotation()
        userAnnotation.coordinate = placeMark.coordinate
        mapView.addAnnotation(userAnnotation)
    }
    
}

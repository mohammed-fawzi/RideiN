//
//  HomeViewController.swift
//  Ride
//
//  Created by mohamed fawzy on 12/24/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import RevealingSplashView
import Firebase

class HomeViewController: UIViewController {
    
   //MARK:- IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var toLocationIndicatorView: UIView!
    @IBOutlet weak var centerMapButton: UIButton!
    
    //MARK:- Variables
    var delegate: CenterVCDelegate?
    
    var locationManager: CLLocationManager!
    
    
    let revealingSplachView = RevealingSplashView(iconImage: UIImage(named: "whiteRideLogo")!, iconInitialSize: CGSize(width: 128, height: 115), backgroundColor: UIColor(named: "navyBlue")!)
    
    var actionButtonShouldAnimate = true
    
    let tableView = UITableView()

  
    
    //MARK:- ViewController Life cylce

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
       
        toTextField.delegate = self
        
        setupTableView()
        
        setupRevealingSplachView()
        checkLocationAuthStatus()
        centerMapOnUserLocation()
        
        DatabaseService.instance.driversRef.observe(.value) { (snapshot) in
            DatabaseService.instance.loadDriverAnnotaitonsFromDB(mapView: self.mapView)
        }
        

        

        
    }
    
    
  
  

    
    
    //MARK:- IBActions
    @IBAction func MenuButtonTapped(_ sender: Any) {
        delegate?.toggleMenu()
    }
    
    @IBAction func actionButtonTapped(_ sender: RoundedShadowButton) {
        
        if actionButtonShouldAnimate {
            sender.animateButton(shouldAnimate: true, message: nil)
            actionButtonShouldAnimate = false

        }else {
            sender.animateButton(shouldAnimate: false , message: "done")
            actionButtonShouldAnimate = true

        }
        
    }
    
    @IBAction func centerMapButtonTapped(_ sender: Any) {
        centerMapOnUserLocation()
        UIView.animate(withDuration: 0.3) {
            self.centerMapButton.alpha = 0
        }

    }
    
    
}

//MARK:- Location manager delegate
extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthStatus()
        
        if status == .authorizedAlways {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
    

    func checkLocationAuthStatus(){
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            print("auth is granted.........")


        }else {
            print("request auth..........")
            locationManager.requestAlwaysAuthorization()
        }
    }
    
}


//MARK:- Map view Delegate
extension HomeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let id = Auth.auth().currentUser?.uid {
            DatabaseService.instance.updateUserLocation(userID: id, withCoordinate: userLocation.coordinate)
            DatabaseService.instance.updateDriverLocation(userID: id, withCoordinate: userLocation.coordinate)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let driverAnnotation = annotation as? DriverAnnotation {
            let annotationView: MKAnnotationView = MKAnnotationView(annotation: driverAnnotation, reuseIdentifier: "driver")
            annotationView.image = UIImage(named: "driverAnnotation")
            return annotationView
        }
        
        return nil
        
        
    }

    // show center map button when region changes
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.centerMapButton.alpha = 1
        }
    }
    
    func centerMapOnUserLocation(){
        let regionRadious: CLLocationDistance = 2000
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadious, longitudinalMeters: regionRadious)
        mapView.setRegion(coordinateRegion, animated: true)
    }


}


//MARK:- TextField Delegate
extension HomeViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == toTextField {
            animateTableView(shouldShow: true)
            
            UIView.animate(withDuration: 0.3) {
                self.toLocationIndicatorView.backgroundColor = .red
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == toTextField {
            //TODO: performSearch()
            textField.endEditing(true)
            return true
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            
            UIView.animate(withDuration: 0.3) {
                self.toLocationIndicatorView.backgroundColor = .lightGray
            }
        }
    }
}

//MARK:- TableView DataSource
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        
        return cell
    }
    
    
}

//MARK:- TableView Delegate
extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        animateTableView(shouldShow: false)
    }
}


//MARK:- Helpers
extension HomeViewController {
    
    //MARK: Splash View
    fileprivate func setupRevealingSplachView() {
        view.addSubview(revealingSplachView)
        revealingSplachView.animationType = .heartBeat
        revealingSplachView.startAnimation()
        revealingSplachView.heartAttack = true
    }
    
    
    //MARK: Table View
    fileprivate func setupTableView() {
        tableView.frame = CGRect(x: 20, y: view.frame.height , width: view.frame.width - 40, height: view.frame.height - 160)
        tableView.layer.cornerRadius = 5.0
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }
    
    fileprivate func animateTableView(shouldShow: Bool){
        if shouldShow {
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = 160
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.view.frame.height
            }
        }
    }
    

}

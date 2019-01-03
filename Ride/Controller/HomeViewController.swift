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
    
    //let currentUserId = Auth.auth().currentUser?.uid
    
    var delegate: CenterVCDelegate?
    
    var locationManager: CLLocationManager!
    
    
    let revealingSplachView = RevealingSplashView(iconImage: UIImage(named: "whiteRideLogo")!, iconInitialSize: CGSize(width: 128, height: 115), backgroundColor: UIColor(named: "navyBlue")!)
    
    var actionButtonShouldAnimate = true
    
    let tableView = UITableView()
    
    var searchResults: [MKMapItem] = []
    
    var route: MKRoute!

  
    
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
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
            performSearch()
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
        
        if let userID = Auth.auth().currentUser?.uid {
            DatabaseService.instance.checkUser(id: userID, forValue: kDESTINATION_COORDINTE) { (exist) in
                if exist {
                    self.zoom(toFitAnnotationsFromMapView: self.mapView)
                }else {
                    self.centerMapOnUserLocation()
                }
            }
        }
        
       
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
            annotationView.image = UIImage(named: "driverPin")
            return annotationView
        }
        else if let passengerAnnotation = annotation as? PassengerAnnotation {
            let annotationView = MKAnnotationView(annotation: passengerAnnotation, reuseIdentifier: "passengerAnnotation")
            annotationView.image = UIImage(named: "passengerPin")
            return annotationView
        }
        else if let destinationAnnotation = annotation as? MKPointAnnotation {
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "destinationAnnotation")
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: destinationAnnotation, reuseIdentifier: "destinationAnnotation")
            }else{
                annotationView?.annotation = destinationAnnotation
            }
            
            annotationView!.image = UIImage(named: "destinationPin")
            return annotationView
            
        }
        
        return nil
   
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRender = MKPolylineRenderer(overlay: route.polyline)
        polylineRender.strokeColor = UIColor.blue
        polylineRender.lineWidth = 5
        zoom(toFitAnnotationsFromMapView: mapView)
        return polylineRender
    }

    // show center map button when region changes
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.centerMapButton.alpha = 1
        }
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
            performSearch()
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
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchResults.removeAll()
        tableView.reloadData()
        removeDestinationPin()
        removeUserPin()
        mapView.removeOverlay(route.polyline)
        
        // remove destination coordinate from firebase
        if let userId = Auth.auth().currentUser?.uid {
            DatabaseService.instance.deleteFromUser(id: userId, value: kDESTINATION_COORDINTE)
        }
        
        centerMapOnUserLocation()
        
        return true
    }
}

//MARK:- TableView DataSource
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
     
        cell.textLabel?.text = searchResults[indexPath.row].name
        cell.detailTextLabel?.text = searchResults[indexPath.row].placemark.title
        return cell
    }
    
    
}

//MARK:- TableView Delegate
extension HomeViewController: UITableViewDelegate {
    

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if route != nil {
            mapView.removeOverlay(route.polyline)
        }
        
        toTextField.endEditing(true)
        let selectedMapItem = searchResults[indexPath.row]

        // change textField text to the selected destination
        toTextField.text = selectedMapItem.name
       
        dropPinFor(passengerLocation: locationManager.location?.coordinate)
        
        dropPinFor(placemark: selectedMapItem.placemark)
        
        createRouteTo(mapItem: selectedMapItem)
        
        // save destination coordinate to firebase
        let destinationCoordinate =  selectedMapItem.placemark.coordinate
        if let userId = Auth.auth().currentUser?.uid {
            DatabaseService.instance.updateUser(id: userId, with: [kDESTINATION_COORDINTE: [destinationCoordinate.latitude, destinationCoordinate.longitude]])
        }
        
        animateTableView(shouldShow: false)

        if toTextField.text == "" {
            searchResults.removeAll()
            tableView.reloadData()
        }
       
    }
    

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if toTextField.text == "" {
            toTextField.endEditing(true)
            animateTableView(shouldShow: false)
        }
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
    
    
    //MARK: Map View
    
    func centerMapOnUserLocation(){
        let regionRadious: CLLocationDistance = 2000
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadious, longitudinalMeters: regionRadious)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    fileprivate func performSearch(){
        searchResults.removeAll()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = toTextField.text
        request.region = mapView.region
        
        let search: MKLocalSearch = MKLocalSearch(request: request)
        search.start { (results, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            else if results!.mapItems.count == 0 {
                print("no results")
            }else{
                for mapItem in results!.mapItems {
                    self.searchResults.append(mapItem)
                    self.tableView.reloadData()
                }
            }
        }
        
    }
    
    fileprivate func dropPinFor(passengerLocation: CLLocationCoordinate2D?) {
        // dorp in passenger annotation
        //FIXME: should not drop in if user is driver
        if let passengerCoordinate = locationManager.location?.coordinate,
            let userId = Auth.auth().currentUser?.uid{
            let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate, key: userId)
            mapView.addAnnotation(passengerAnnotation)
        }
    }
    
    fileprivate func dropPinFor(placemark: MKPlacemark){
       
        removeDestinationPin()
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func removeDestinationPin(){
        
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self){
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    fileprivate func removeUserPin(){
        
        for annotation in mapView.annotations {
            if let annotation = annotation as? PassengerAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    
    fileprivate func createRouteTo(mapItem: MKMapItem) {
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem.forCurrentLocation()
        directionRequest.destination = mapItem
        directionRequest.transportType = .automobile
        
        let direction = MKDirections(request: directionRequest)
        direction.calculate { (response, error) in
            guard error == nil else {return}
            
            if let response = response {
                
                self.route = response.routes[0]
                self.mapView.addOverlay(self.route.polyline)
            }
        }
    }
    
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView){
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        // set annotations
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        // set region
        let center =  CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5)
        
        let span = MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0)
        
        var region = MKCoordinateRegion(center: center, span: span )
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
        
        
        
    }
    
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        
        if forActiveTripWithDriver {
            for annotation in mapView.annotations {
                if let annotation = annotation as? DriverAnnotation {
                    if annotation.driverID == key {
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                } else {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
        
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
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

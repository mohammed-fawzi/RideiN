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
    @IBOutlet weak var locationTextFieldsContainer: RoundedShadowView!
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var toLocationIndicatorView: UIView!
    @IBOutlet weak var centerMapButton: UIButton!
    @IBOutlet weak var actionButton: RoundedShadowButton!
    
    //MARK:- Variables
    
    var delegate: CenterVCDelegate?
    
    var locationManager: CLLocationManager!
    
    
    let revealingSplachView = RevealingSplashView(iconImage: UIImage(named: "whiteRideLogo")!, iconInitialSize: CGSize(width: 128, height: 115), backgroundColor: UIColor(named: "navyBlue")!)
    
    var actionButtonShouldAnimate = true
    
    let tableView = UITableView()
    
    var searchResults: [MKMapItem] = []
    
    var route: MKRoute!
    
    var buttonAction: ButtonAction = .requestTrip
  
    
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
        
        // displying driver annotations on the map
        DatabaseService.instance.driversRef.observe(.value) { (snapshot) in
            DatabaseService.instance.loadDriverAnnotaitonsFromDB(mapView: self.mapView)
            
            if let userId = Auth.auth().currentUser?.uid {
                DatabaseService.instance.passengerIsOnTrip(passengerId: userId, handler: { (isOnTrip, driverId, tripId) in
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverId)
                })
            }
            
        }
        
        // if there is a new trip display it for the available drivers
        DatabaseService.instance.observeTrips { (tripDictionary) in
            if let tripDict = tripDictionary {
                let pickUpCoordinateArray = tripDict[kPICKUP_COORDINATE] as! [CLLocationDegrees]
                //let destinationCoordinateArray = tripDict[kDESTINATION_COORDINTE] as! NSArray
                let passengerId = tripDict[kPASSENGER] as! String
                let isTripAccepted = tripDict[kTRIP_IS_ACCEPTED] as! Bool
                
                if let driverID = Auth.auth().currentUser?.uid {
                    
                    DatabaseService.instance.driverIsAvailable(id: driverID, completion: { (isAvailable) in
                        if let isAvailable = isAvailable  {
                            guard isTripAccepted == false else {return}
                            if isAvailable == true {
                                let pickUpVC = UIStoryboard(name: "PickUp", bundle: Bundle.main).instantiateInitialViewController() as! PickUpViewController
                                
                                pickUpVC.initData(coordinate: CLLocationCoordinate2D(latitude: pickUpCoordinateArray[0], longitude: pickUpCoordinateArray[1]), passenger: passengerId)
                                
                                self.present(pickUpVC, animated:  true)
                            }
                            
                        }
                    })
                }
                
            }
        }
        
        
        connectUserWithDriver()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let userId = Auth.auth().currentUser?.uid else {return}

        DatabaseService.instance.userIsDriver(userId: userId) { (isDriver) in
            if isDriver {
                self.actionButton.isHidden = true
                self.locationTextFieldsContainer.isHidden = true
                self.actionButton.isEnabled = true
                self.actionButton.alpha = 1
            }else{
                self.actionButton.isHidden = false
                self.locationTextFieldsContainer.isHidden = false
                self.actionButton.isEnabled = false
                self.actionButton.alpha = 0.8
            }
        }

            DatabaseService.instance.tripsRef.observe(.childRemoved) { (tripSnapshot) in
                if tripSnapshot.key == userId {
                    
                    self.removeOverlay()
                    self.removeUserPin()
                    self.removeDestinationPin()
                    self.centerMapOnUserLocation()
                    self.actionButton.setTitle(kREQUEST_RIDE, for: .normal)
                    self.actionButton.isEnabled = true
                    self.toTextField.text = ""
                    
                }
                else if tripSnapshot.childSnapshot(forPath: kDRIVERID).value as! String == userId {
                    self.removeOverlay()
                    self.removeUserPin()
                    self.removeDestinationPin()
                    self.centerMapOnUserLocation()
                    self.actionButton.isHidden = true
                }
            }
        
        
            // find trip belongs to driver
            DatabaseService.instance.fetchTrip(forDriver: userId) { (trip) in
                if let trip = trip {
 
                    let pickupMapItem = self.createMapItem(fromDictionary: trip, key: kPICKUP_COORDINATE)

                    let passengerId = trip[kPASSENGER] as! String
                    
                    // create route to passenger
                    let passengerAnnotation = PassengerAnnotation(coordinate: pickupMapItem.placemark.coordinate, key: passengerId)
                    self.mapView.addAnnotation(passengerAnnotation)
                    self.createRoute(fromMapItem: nil, toMapItem: pickupMapItem)
                   
                    self.setRegionForMonitoring(forAnnotationType: .pickUp, withCoordinate: pickupMapItem.placemark.coordinate)
                    
                    self.buttonAction = .getDirectionToPassenger
                    self.actionButton.setTitle(kGET_DIRECTIONS, for: .normal)
                    self.actionButton.isHidden = false
                }
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
        if Auth.auth().currentUser?.uid != nil {
            buttonSelector(forAction: buttonAction)

        }else {
            let vc = UIStoryboard.init(name: "Login", bundle: Bundle.main).instantiateInitialViewController() as! LoginViewController
            present(vc, animated: true)
        }
        
    }
    
    @IBAction func centerMapButtonTapped(_ sender: Any) {
        
        if let userID = Auth.auth().currentUser?.uid {
            DatabaseService.instance.checkUser(id: userID, forValue: kDESTINATION_COORDINTE) { (exist) in
                if exist {
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
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


        }else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        guard let driverId = Auth.auth().currentUser?.uid else {return}
        
        DatabaseService.instance.driverIsOnTrip(driverId: driverId) { (isOnTrip, driverId, tripId) in
            if isOnTrip {
                
                if region.identifier == kPICKUP {
                    self.buttonAction = .startTrip
                    self.actionButton.setTitle(kSTART_TRIP, for: .normal)
                }
                else if region.identifier == kDESTINATION {
                    self.buttonAction = .endTrip
                    self.actionButton.setTitle(kEND_TRIP, for: .normal)
                }
            }
            
        }
     
    }
    

    
}


//MARK:- Map view Delegate
extension HomeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let id = Auth.auth().currentUser?.uid {
            DatabaseService.instance.updateUserLocation(userID: id, withCoordinate: userLocation.coordinate)
            DatabaseService.instance.updateDriverLocation(userID: id, withCoordinate: userLocation.coordinate)
            
            DatabaseService.instance.userIsDriver(userId: id) { (isDriver) in
                if isDriver {
                    DatabaseService.instance.driverIsOnTrip(driverId: id, handler: { (isOnTrip, driverKey, tripKey) in
                        if isOnTrip {
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                        }else{
                            self.centerMapOnUserLocation()
                        }
                    })
                }else{
                    DatabaseService.instance.passengerIsOnTrip(passengerId: id, handler: { (isOnTrip, driverKey, tripKey) in
                        if isOnTrip{
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                        }else {
                            self.centerMapOnUserLocation()
                        }
                    })
                }
            }
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
        polylineRender.strokeColor = UIColor(named: "navyBlue")
        polylineRender.lineWidth = 5
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
        
        actionButton.isEnabled = false
        actionButton.alpha = 0.8

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
       let cell = UITableViewCell(style: .subtitle, reuseIdentifier: kLOCATION_CELL)
     
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
        
        createRoute(fromMapItem: nil, toMapItem: selectedMapItem)
        
        actionButton.isEnabled = true
        actionButton.alpha = 1

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

    func buttonSelector(forAction action: ButtonAction){
        guard let userId = Auth.auth().currentUser?.uid else {return}
       
        switch action {
        case .requestTrip:
            actionButton.animateButton(shouldAnimate: true, message: nil)
            DatabaseService.instance.createTrip()

        case .getDirectionToPassenger:
            DatabaseService.instance.driverIsOnTrip(driverId: userId) { (isOnTrip, driverId, TripId) in
                if isOnTrip{
                    DatabaseService.instance.fetchTrip(forDriver: userId, completion: { (tripDict) in
                        if let tripDict = tripDict {
                            let pickupMapItem = self.createMapItem(fromDictionary: tripDict, key: kPICKUP_COORDINATE)
                            pickupMapItem.name = "Passenger Pickup Point"
                            pickupMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                        }
                    })
                }
            }
            
        case .cancelTrip:
            DatabaseService.instance.passengerIsOnTrip(passengerId: userId) { (isOnTrip, driverId, tripId) in
                self.removeDestinationPin()
                self.removeOverlay()
                self.centerMapOnUserLocation()
                self.toTextField.text = ""
                DatabaseService.instance.cancelTrip(withPassengerId: userId, forDriverId: driverId!)
                self.buttonAction = .requestTrip
                
            }
        
        case .startTrip:
            DatabaseService.instance.driverIsOnTrip(driverId: userId) { (isOnTrip, driverId, tripId) in
                if isOnTrip {
                    self.removeOverlay()
                    DatabaseService.instance.tripsRef.child(tripId!).updateChildValues([kTRIP_ON_PROGRESS: true])
                    
                    DatabaseService.instance.fetchTrip(forDriver: driverId!, completion: { (tripDict) in
                        if let tripDict = tripDict {
                            let destinationMapItem = self.createMapItem(fromDictionary: tripDict, key: kDESTINATION_COORDINTE)
          
                            self.dropPinFor(placemark: destinationMapItem.placemark)
                            self.createRoute(fromMapItem: nil, toMapItem: destinationMapItem)
                            self.setRegionForMonitoring(forAnnotationType: .destination, withCoordinate: destinationMapItem.placemark.coordinate)
                            
                            self.buttonAction = .getDirectionToDestination
                            self.actionButton.setTitle(kGET_DIRECTIONS, for: .normal)
                            
                        }
                    })
                }
            }
            
        case .getDirectionToDestination:
            DatabaseService.instance.driverIsOnTrip(driverId: userId) { (isOnTrip, driverId, TripId) in
                if isOnTrip{
                    DatabaseService.instance.fetchTrip(forDriver: userId, completion: { (tripDict) in
                        if let tripDict = tripDict {
                            let destinationMapItem = self.createMapItem(fromDictionary: tripDict, key: kDESTINATION_COORDINTE)
                            destinationMapItem.name = "Destination Point"
                            destinationMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                        }
                    })
                }
            }
        case .endTrip:
            DatabaseService.instance.driverIsOnTrip(driverId: userId) { (isOnTrip, driverId, tripId) in
                if isOnTrip{
                    DatabaseService.instance.cancelTrip(withPassengerId: tripId!, forDriverId: driverId!)
                    self.removeOverlay()
                    self.removeUserPin()
                    self.removeDestinationPin()
                    self.centerMapOnUserLocation()
                    self.actionButton.isHidden = true
                }
            }
        }
    }
    
    fileprivate func createMapItem(fromDictionary dict: [String:Any], key:String)-> MKMapItem{
        let coordinateArray = dict[key] as! [CLLocationDegrees]
        let coordinate = CLLocationCoordinate2D(latitude: coordinateArray[0], longitude: coordinateArray[1])
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        
        return mapItem
    }
    
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
    
    fileprivate func removeDriverPin(){
        
        for annotation in mapView.annotations {
            if let annotation = annotation as? DriverAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    fileprivate func removeOverlay(){
        
        for overlay in mapView.overlays {
            if overlay is MKPolyline {
                mapView.removeOverlay(overlay)
            }
        }
    }
    
    
    fileprivate func createRoute(fromMapItem source: MKMapItem?, toMapItem destination: MKMapItem) {
        let directionRequest = MKDirections.Request()
        
        if let source = source {
            directionRequest.source = source
        }else{
            directionRequest.source = MKMapItem.forCurrentLocation()
        }
        directionRequest.destination = destination
        directionRequest.transportType = .automobile
        
        let direction = MKDirections(request: directionRequest)
        direction.calculate { (response, error) in
            guard error == nil else {return}
            
            if let response = response {
                
                self.route = response.routes[0]
                self.mapView.addOverlay(self.route.polyline)
                
                self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)

            }
        }
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
    
    func connectUserWithDriver(){
        guard let userId = Auth.auth().currentUser?.uid else{return}

        DatabaseService.instance.userIsDriver(userId: userId) { (isDriver) in
            if !isDriver {
                DatabaseService.instance.tripsRef.child(userId).observe(.value, with: { (tripSnapshot) in

                    guard let tripDict = tripSnapshot.value as? [String:Any] else {return}
                    if tripDict[kTRIP_IS_ACCEPTED] as! Bool {
                        self.removeOverlay()
                        self.removeUserPin()
                        self.removeDriverPin()

                        let driverId = tripDict[kDRIVERID] as! String

                        let pickupMapItem = self.createMapItem(fromDictionary: tripDict, key: kPICKUP_COORDINATE)

                        DatabaseService.instance.driversRef.child(driverId).observeSingleEvent(of: .value, with: { (driverSnapshot) in

                            if let driverSnapshot = driverSnapshot.value as? [String:Any] {
                                
                                let driverMapItem = self.createMapItem(fromDictionary: driverSnapshot, key: kCOORDINATES)
                                
                                // create annotations and route
                                let passengerAnnotation = PassengerAnnotation(coordinate: pickupMapItem.placemark.coordinate, key: userId)
                                let driverAnnotation = DriverAnnotation(coordinate: driverMapItem.placemark.coordinate, driverID: driverId)

                                self.mapView.addAnnotations([passengerAnnotation,driverAnnotation])
                                self.createRoute(fromMapItem: driverMapItem, toMapItem: pickupMapItem)
                                
                                DispatchQueue.main.async {
                                    self.actionButton.animateButton(shouldAnimate: false, message: kCANCEL_TRIP)
                                    self.buttonAction = .cancelTrip
                                }
                            }
                        })
                        
                        if tripDict[kTRIP_ON_PROGRESS] as? Bool == true {
                            self.removeOverlay()
                            self.removeUserPin()
                            self.removeDriverPin()
                            
                            let destinationMapItem = self.createMapItem(fromDictionary: tripDict, key: kDESTINATION_COORDINTE)

                            self.dropPinFor(placemark: destinationMapItem.placemark)
                            self.createRoute(fromMapItem: nil, toMapItem: destinationMapItem)
                            
                            self.actionButton.setTitle(kON_TRIP, for: .normal)
                            self.actionButton.isEnabled = false
                            
                        }
                        
                    }
                   
                })
            }
        }
    }
    
    func setRegionForMonitoring(forAnnotationType annotation: AnnotationType, withCoordinate coordinate: CLLocationCoordinate2D){
        
        if annotation == .pickUp {
            let pickUpRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: kPICKUP)
            locationManager.startMonitoring(for: pickUpRegion)
        }
        else if annotation == .destination  {
            let destionationRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: kDESTINATION)
            locationManager.startMonitoring(for: destionationRegion)
        }
    }
    
    //MARK: Table View
    fileprivate func setupTableView() {
        tableView.frame = CGRect(x: 20, y: view.frame.height , width: view.frame.width - 40, height: view.frame.height - 160)
        tableView.layer.cornerRadius = 5.0
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kLOCATION_CELL)
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

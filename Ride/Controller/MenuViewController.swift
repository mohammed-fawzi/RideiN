//
//  MenuViewController.swift
//  Ride
//
//  Created by mohamed fawzy on 12/25/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit
import Firebase

class MenuViewController: UIViewController {
    
    var islogedIn = false
    var currentUserID = Auth.auth().currentUser?.uid
    let appDelegate = AppDelegate().getAppDelegate()
    
    //MARK:- IBOutlets
    @IBOutlet weak var menuLabel: UILabel!
   
    @IBOutlet weak var userDetailsStackView: UIStackView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var NameLabel: UILabel!
    @IBOutlet weak var accountTypeLabel: UILabel!
    
    @IBOutlet weak var pickupModeStackView: UIStackView!
    @IBOutlet weak var pickUpModeSwitch: UISwitch!
    @IBOutlet weak var pickUpModeLabel: UILabel!
    
    @IBOutlet weak var SignUpLoginButton: UIButton!
    
    //MARK:- ViewController lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        observePassengerAndDrivers()
        
        if Auth.auth().currentUser != nil {
            currentUserID = Auth.auth().currentUser!.uid
            SignUpLoginButton.setTitle("Logout", for: .normal)
            islogedIn = true
            menuLabel.isHidden = true
            userDetailsStackView.isHidden = false
        }else{
            SignUpLoginButton.setTitle("Sin Up / Login", for: .normal)
            islogedIn = false
            menuLabel.isHidden = false
            userDetailsStackView.isHidden = true
            pickupModeStackView.isHidden = true
        }
      
    }
    
    
 
 
    //MARK:- IBActions
    @IBAction func paymentButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func tripsButtonTapped(_ sender: Any) {
    }
    @IBAction func helpButtonTapped(_ sender: Any) {
    }
    @IBAction func settingsButtonTapped(_ sender: Any) {

    }
    
    @IBAction func pickupSwitchToggled(_ sender: Any) {
        appDelegate.containerViewController.toggleMenu()
        if pickUpModeSwitch.isOn {
            pickUpModeLabel.text = "PICKUP MODE IS ENALBLED"
            DatabaseService.instance.driversRef.child(currentUserID!).updateChildValues([kIS_PICKUP_MODE_ENABLED: true])
        }else {
            pickUpModeLabel.text = "PICKUP MODE IS DISABLED"
            DatabaseService.instance.driversRef.child(currentUserID!).updateChildValues([kIS_PICKUP_MODE_ENABLED: false])

        }
        
    }
    
    @IBAction func loginLogoutButtonTapped(_ sender: UIButton) {
        
        if islogedIn {
            do {
                try Auth.auth().signOut()
            }
            catch {
                print("error while signing out: ", error.localizedDescription)
            }
            
            islogedIn = false
            SignUpLoginButton.setTitle("Sin Up / Login", for: .normal)
            menuLabel.isHidden = false
            userDetailsStackView.isHidden = true
            pickupModeStackView.isHidden = true
            
            if !pickupModeStackView.isHidden {
                DatabaseService.instance.driversRef.child(currentUserID!).updateChildValues([kIS_PICKUP_MODE_ENABLED: false])

            }
            
            
            
        }else {
            let vc = UIStoryboard.init(name: "Login", bundle: Bundle.main).instantiateInitialViewController() as! LoginViewController
            present(vc, animated: true)
        }
    }
    
    

}


//MARK:- Helpers
extension MenuViewController {
    
    
    // Database Helpers
    func observePassengerAndDrivers(){
        
        if let user = Auth.auth().currentUser {
            // check if user is passenger
            DatabaseService.instance.usersRef.child(user.uid).observeSingleEvent(of: .value) { (snapShot) in
                if  snapShot.exists()  {
                    
                    DispatchQueue.main.async {
                        self.NameLabel.text = user.email
                        self.accountTypeLabel.text = "PASSENGER"
                        self.pickupModeStackView.isHidden = true
                    }
                    
                }
            }
            
            // check if user is driver
            DatabaseService.instance.driversRef.child(user.uid).observeSingleEvent(of: .value) { (snapShot) in
                
                if  snapShot.exists()  {
                  
                    DispatchQueue.main.async {
                        self.NameLabel.text = user.email
                        self.accountTypeLabel.text = "Driver"
                        self.pickupModeStackView.isHidden = false
                    }
                    
                    
                    if  snapShot.childSnapshot(forPath: kIS_PICKUP_MODE_ENABLED).value as! Bool {
                        DispatchQueue.main.async {
                            self.pickUpModeSwitch.isOn = true
                        }
                    }else {
                        DispatchQueue.main.async {
                            self.pickUpModeSwitch.isOn = false
                        }
                    }
                    
                }
            }
            
        }
        
    }
}

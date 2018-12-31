//
//  LoginViewController.swift
//  Ride
//
//  Created by mohamed fawzy on 12/28/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    //MARK:- IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var accountTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var loginButton: RoundedShadowButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.bindToKeyboard()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tapGesture)
    
    }
    
    
    //MARK:- IBActions
    @IBAction func cancelButtonTapped(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    

    @IBAction func loginButtonTapped(_ sender: RoundedShadowButton) {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            loginButton.animateButton(shouldAnimate: true, message: nil)
            self.view.endEditing(true)
            
            if let email = emailTextField.text,
                let password = passwordTextField.text {
                
                signIn(email: email, password: password)
            }
            
        }
   
    }
    
   
    
}


//MARK:- Helpers
extension LoginViewController {
    
     @objc fileprivate func handleScreenTap(sender: UITapGestureRecognizer ){
        self.view.endEditing(true)
    }
    
    
    
    //MARK:- Database Helpers
    fileprivate func signIn(email: String, password: String) {
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if error == nil {
                // login successful user is exist
               
                print("login successful")
                self.dismiss(animated: true, completion: nil)
                
            }else {
                // login failed
                self.loginButton.animateButton(shouldAnimate: false, message: "Sign Up / Login")
                
                // handle login errors
                if let errorCode = AuthErrorCode(rawValue: error!._code){
                    
                    switch errorCode {
                    case .wrongPassword:
                        print("wrong password")
                        return
                    case .invalidEmail:
                        print("invalid email address")
                        return
                    default:
                        print("unexpected error please try again")
                    }
                }
                
                self.signUp(email: email, password: password)
                
            }
            
        }
    }
    
    
    fileprivate func signUp( email: String , password: String) {
        // user doesn't exist
        Auth.auth().createUser(withEmail: email, password: password, completion: { (result, error) in
            
            if error == nil {
                // sign up sucessful
                if let user = result?.user {
                    
                    self.updateDatabase(user)
                    
                }
                print("sign Up successful")
                self.dismiss(animated: true, completion: nil)
                
            } else {
                //sign Up failed
                if let errorCode = AuthErrorCode(rawValue: error!._code){
                    
                    switch errorCode {
                    case .invalidEmail:
                        print("invalid email address")
                    case .emailAlreadyInUse:
                        print("email already exist")
                    default:
                        print("unexpected error please try again")
                        
                    }
                }
            }
        })
    }
    
    fileprivate func updateDatabase(_ user: User) {
        if self.accountTypeSegmentedControl.selectedSegmentIndex == 0 {
            
            // user is a passenger
            let userData = [kPROVIDER: user.providerID] as [String: Any]
            
            DatabaseService.instance.createFirebaseDBUser(uID: user.uid, userData: userData, isDriver: false)
            
        }else {
            // user is a driver
            let userData = [kPROVIDER: user.providerID,
                            kISDRIVER : true,
                            kIS_PICKUP_MODE_ENABLED : false,
                            kDRIVER_IS_ON_TRIP: false] as [String: Any]
            
            DatabaseService.instance.createFirebaseDBUser(uID: user.uid, userData: userData, isDriver: true)
        }
    }
    
    
    
}



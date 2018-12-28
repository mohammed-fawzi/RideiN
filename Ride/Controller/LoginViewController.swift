//
//  LoginViewController.swift
//  Ride
//
//  Created by mohamed fawzy on 12/28/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.bindToKeyboard()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tapGesture)
        
      
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc func handleScreenTap(sender: UITapGestureRecognizer ){
        print("end")
        self.view.endEditing(true)
    }
    
}

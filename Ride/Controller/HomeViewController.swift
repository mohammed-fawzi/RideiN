//
//  HomeViewController.swift
//  Ride
//
//  Created by mohamed fawzy on 12/24/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    var shouldAnimate = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func actionButtonTapped(_ sender: RoundedShadowButton) {
        
        if shouldAnimate {
            sender.animateButton(shouldAnimate: true, message: nil)
            shouldAnimate = false

        }else {
            sender.animateButton(shouldAnimate: false , message: "done")
            shouldAnimate = true

        }
        
    }
    
}


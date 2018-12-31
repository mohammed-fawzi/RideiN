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

class HomeViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var delegate: CenterVCDelegate?

    let revealingSplachView = RevealingSplashView(iconImage: UIImage(named: "whiteRideLogo")!, iconInitialSize: CGSize(width: 128, height: 115), backgroundColor: UIColor(named: "navyBlue")!)
    var shouldAnimate = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(revealingSplachView)
        revealingSplachView.animationType = .heartBeat
        revealingSplachView.startAnimation()
        
        revealingSplachView.heartAttack = true
    }
    
    
    
    @IBAction func MenuButtonTapped(_ sender: Any) {
        delegate?.toggleMenu()
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


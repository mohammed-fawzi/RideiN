//
//  RoundedShadowButton.swift
//  Ride
//
//  Created by mohamed fawzy on 12/25/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit

class RoundedShadowButton: UIButton {
    
    let spinner: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = .whiteLarge
        activityIndicator.color = .darkGray
        activityIndicator.alpha = 0.0
        activityIndicator.hidesWhenStopped = true
        
        return activityIndicator
    }()
    
    var originalSize: CGRect?

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        originalSize = self.layer.frame
        layer.cornerRadius = 7.0
        layer.shadowRadius = 10.0
        layer.shadowOpacity = 0.3
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowOffset = .zero
        self.addSubview(spinner)

    }
    
    
    func animateButton(shouldAnimate: Bool , message: String?){
       
        
        if shouldAnimate {
            self.setTitle("", for: .normal)
            UIView.animate(withDuration: 0.2,
                           animations: {
                            self.layer.cornerRadius = self.frame.height / 2
                            
                            let newX = self.frame.midX - (self.frame.height/2)
                            let newY = self.frame.origin.y
                            
                            self.frame = CGRect(x: newX, y: newY , width: self.frame.height, height: self.frame.height)
                        },
                          completion: {(finished) in
                            if finished {
                                self.spinner.startAnimating()
                                self.spinner.center = CGPoint(x: self.frame.width/2 + 1, y: self.frame.height/2 + 1)
                                UIView.animate(withDuration: 0.2, animations: {
                                    self.spinner.alpha = 1.0
                                })
                            }
                
                        })
            
            self.isUserInteractionEnabled = false
        
        }else {
           
            self.isUserInteractionEnabled = true
            self.spinner.stopAnimating()

            UIView.animate(withDuration: 0.2) {
                self.layer.cornerRadius = 5.0
                self.frame = self.originalSize!
                if let message = message {
                    self.setTitle(message, for: .normal)
                }
            }
        }
        
        
        
        
        
    }

}

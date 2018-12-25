//
//  UIView+Extention.swift
//  Ride
//
//  Created by mohamed fawzy on 12/25/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit

extension UIView {
    
    @IBInspectable var radius: CGFloat  {
      
        get {
            return self.layer.cornerRadius
        }
        
        set {
            self.layer.cornerRadius = newValue
        }
    
    }
    
}

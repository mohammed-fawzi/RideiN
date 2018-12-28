//
//  CenterVCDelegate.swift
//  Ride
//
//  Created by mohamed fawzy on 12/26/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit

protocol CenterVCDelegate {
    func toggleMenu()
    func addMenuViewController()
    func animateMenu(shouldAnimate: Bool)
}

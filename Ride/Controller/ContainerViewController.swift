//
//  ContainerViewController.swift
//  Ride
//
//  Created by mohamed fawzy on 12/25/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit
import QuartzCore

enum menuState {
    case expanded
    case collapsed
}

enum showVC {
    case homeVC
}



var shownVC: showVC = .homeVC
class ContainerViewController: UIViewController {
    
    
    //MARK:- variables
    var homeVC: HomeViewController!
    var menuVC: MenuViewController!
    var centerVC: UIViewController!
    
    var menuCurrentState: menuState = .collapsed
    
    var isStatusBarHidden: Bool = false
    let centerVCExpandedOffset: CGFloat = 100
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var  prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCenterVC(screen: shownVC)
        
        
    }
    
  


}




//MARK:- centerVC Delegate
extension ContainerViewController: CenterVCDelegate {
    func toggleMenu() {
        
        let menuIsCollapsed: Bool = (menuCurrentState == .collapsed)
        
        if menuIsCollapsed {
            addMenuViewController()
        }
        animateMenu(shouldAnimate: menuIsCollapsed )
        
    }
    
    func addMenuViewController() {
        if menuVC == nil{
            menuVC = UIStoryboard.menuViewController()
            addChildViewController(VC: menuVC, at: 0)
        }
    }
    
    @objc func animateMenu(shouldAnimate: Bool) {
        
        if shouldAnimate {
            menuCurrentState = .expanded
            isStatusBarHidden = !isStatusBarHidden
            animateStatusBar()
            setUpWhiteCoverView()
            animateCenterVCXPosition(targetPosition: centerVC.view.frame.width - centerVCExpandedOffset)
            
            
        }else{
            isStatusBarHidden = !isStatusBarHidden
            animateStatusBar()
            hideWhiteCoverView()
            animateCenterVCXPosition(targetPosition: 0) { (finished) in
                if finished {
                    self.menuCurrentState = .collapsed
                    self.menuVC = nil

                }
            }

        }
    }
    
    
    func addChildViewController(VC: UIViewController , at: Int?){
        if  at != nil {
            view.insertSubview(VC.view, at: at!)
        }else {
            view.addSubview(VC.view)
        }
        
        addChild(VC)
        VC.didMove(toParent: self)
    }
    
    
}


//MARK:- Helpers
extension ContainerViewController {
    
    
    func initCenterVC(screen: showVC){
        var presentingVC: UIViewController
        
        shownVC = screen
        if homeVC == nil {
            homeVC = UIStoryboard.homeViewController()
            homeVC.delegate = self
        }
        
        presentingVC = homeVC
        
        if let centerViewController = centerVC {
            centerViewController.view.removeFromSuperview()
            centerViewController.removeFromParent()
        }
        
        centerVC = presentingVC
        centerVC.view.layer.shadowOpacity = 0.6
        addChildViewController(VC: centerVC, at: nil)
    }
    
    
    func  animateStatusBar(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    func setUpWhiteCoverView(){
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        whiteCoverView.backgroundColor = .lightGray
        whiteCoverView.alpha = 0.0
        whiteCoverView.tag = 13
        centerVC.view.addSubview(whiteCoverView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.animateMenu(shouldAnimate:)))
        tapGesture.numberOfTapsRequired = 1
        whiteCoverView.addGestureRecognizer(tapGesture)

        UIView.animate(withDuration: 0.2) {
            whiteCoverView.alpha = 0.3
        }
    }
    
    func hideWhiteCoverView(){
        
        for subView in centerVC.view.subviews {
            if subView.tag == 13 {
                UIView.animate(withDuration: 0.2, animations: {
                    subView.alpha = 0
                }, completion: {finished in
                    subView.removeFromSuperview()
                })
            }
        }
    }
    
    func animateCenterVCXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerVC.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
}


//MARK:- Storyboard Extention
private extension UIStoryboard {
    
   class func homeStorboard()-> UIStoryboard {
        return UIStoryboard(name: "Home", bundle: Bundle.main)
    }
    
    
   class func MenuStorboard()-> UIStoryboard {
        return UIStoryboard(name: "Menu", bundle: Bundle.main)
    }
    
  class  func homeViewController() -> HomeViewController {
        return homeStorboard().instantiateViewController(withIdentifier: "homeVC") as! HomeViewController
    }
    
   class func menuViewController() -> MenuViewController {
        return MenuStorboard().instantiateViewController(withIdentifier: "menuVC") as! MenuViewController
    }
}

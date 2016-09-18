//
//  UIExtensions.swift
//  UnFlare
//
//  Created by Floris Chabert on 9/16/16.
//  Copyright © 2016 floris. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func setupTitle(_ text: String, color: UIColor = UIColor.black) {
        let titleLabelView = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        titleLabelView.backgroundColor = UIColor.clear
        titleLabelView.textAlignment = .center;
        titleLabelView.textColor = color
        titleLabelView.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabelView.adjustsFontSizeToFitWidth = true
        titleLabelView.text = text
        
        DispatchQueue.main.async {
            self.navigationItem.titleView = titleLabelView;
            self.navigationItem.title = text
        }
    }
    
    func slideTitle(_ text: String? = nil) {
        let animation = CATransition()
        animation.duration = 0.2
        animation.type = kCATransitionFade;
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        
        DispatchQueue.main.async {
            self.navigationItem.titleView?.layer.add(animation, forKey:"changeTitle")
            (self.navigationItem.titleView as? UILabel)?.text = text ?? self.navigationItem.title;
        }
    }
}


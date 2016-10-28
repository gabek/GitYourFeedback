//
//  UIViewControllerExtension.swift
//  Pods
//
//  Created by Sidney de Koning on 27/10/2016.
//
//

import Foundation

extension UIViewController {
    
    static var topmostViewController: UIViewController? {
        var vc: UIViewController?
        
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        
        vc = rootViewController
        
        while let presentedViewController = vc?.presentedViewController {
            vc = presentedViewController
        }
        
        return vc
    }
}

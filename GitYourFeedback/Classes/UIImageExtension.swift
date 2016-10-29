//
//  UIImageExtension.swift
//  Pods
//
//  Created by Sidney de Koning on 27/10/2016.
//
//

import Foundation

extension UIImage {
    
    func resize(to size: CGSize) -> UIImage {
                
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
    func sizeWith(multiplier: CGFloat) -> CGSize {
        return CGSize(width: Int(size.width * multiplier), height: Int(size.height * multiplier))
    }
    
}

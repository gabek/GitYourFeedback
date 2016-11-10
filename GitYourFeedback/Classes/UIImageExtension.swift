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
    
    func resizeToUploadingSize() -> UIImage {
        let recommendedSize = CGSize(width: 450, height: 800)

        let widthFactor = size.width / recommendedSize.width
        let heightFactor = size.height / recommendedSize.height
        
        var resizeFactor = widthFactor
        if size.height > size.width {
            resizeFactor = heightFactor
        }
        
        let newSize = CGSize(width: size.width / resizeFactor, height: size.height / resizeFactor)
        let resized = resize(to: newSize)
        return resized        
    }
}

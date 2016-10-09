//
//  MediaQuery.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/11/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import Photos

struct MediaQuery {
    static func fetchLastImage(completionHandler: @escaping (UIImage?) -> Void) {
        
        let imgManager = PHImageManager.default()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        // Sort the images by creation date
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        
        // If the fetch result isn't empty,
        // proceed with the image request
        if fetchResult.count > 0 {
            // Perform the image request
            imgManager.requestImage(for: fetchResult.object(at: fetchResult.count - 1) as PHAsset, targetSize: CGSize(width: 300, height: 100), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
                
                completionHandler(image)
            })
        } else {
            completionHandler(nil)
        }
    }
    
    static func hasPhotosAccess() -> Bool {
        let access = PHPhotoLibrary.authorizationStatus()
        return access == PHAuthorizationStatus.authorized
    }
    
    static func requestPhotosAccess(completionHandler: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization { (status) in
            completionHandler(status)
        }
    }

}

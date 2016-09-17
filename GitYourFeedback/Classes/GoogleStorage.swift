//
//  GoogleStroage.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/10/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation

class GoogleStorage {
    var bucket: String?
    
    func upload(data: Data, urlString: String, completionHandler: @escaping (String?, String?) -> Void) {
        // Tell Google this is a one-time, non-multipart upload
        let fullUrlString = urlString + "&uploadType=media"
        
        guard let url = URL(string: fullUrlString) else {
            fatalError("Unable create a HTTP request from string: \(fullUrlString)")
            return
        }
        
        var request = createRequest(remoteUrl: url)
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        
        let uploadTask = URLSession.shared.uploadTask(with: request, from: data) { (data, response, httpError) in
            guard let data = data else {
                fatalError("No response from Google Cloud Storage")
                return
            }
            
            OperationQueue.main.addOperation {
                if let publicUrlString = self.parseResponseForPublicUrl(responseJsonData: data) {
                    completionHandler(publicUrlString, nil)
                } else {
                    let errorString = "Could not upload to \(urlString).  \(response?.description)"
                    completionHandler(nil, errorString)
                }
            }
            
        }
        uploadTask.resume()
    }

    private func createRequest(remoteUrl: URL) -> URLRequest {
        var request = URLRequest(url: remoteUrl)
        request.httpMethod = "POST"
        request.setValue("image/jpg", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    private func parseResponseForPublicUrl(responseJsonData: Data) -> String? {
        var jsonResults: [String:Any]?
        
        do {
            guard let results = try JSONSerialization.jsonObject(with: responseJsonData, options: []) as? [String:Any] else {
                return nil
            }
            jsonResults = results
        } catch {
            fatalError("Parsing failed: \((error as NSError).localizedDescription)")
            return nil
        }
        
        if let bucket = jsonResults?["bucket"] as? String, let name = jsonResults?["name"] as? String {
            let publicUrl = "https://storage.googleapis.com/\(bucket)/\(name)"
            return publicUrl
        }

        return nil
    }
}



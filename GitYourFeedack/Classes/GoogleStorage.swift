//
//  GoogleStroage.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/10/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation

class GoogleStorage {
    var bucket: String

    init(bucket: String) {
        self.bucket = bucket
    }
    
    func upload(data: Data, remotefilename: String, completionHandler: @escaping (String?, Error?) -> Void) {
        var request = createRequest(remotefilename: remotefilename)
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        let publicUrl = "https://storage.googleapis.com/\(bucket)/\(remotefilename)"
        
        let uploadTask = URLSession.shared.uploadTask(with: request, from: data) { (data, response, httpError) in
            let dataString = String(data: data!, encoding: String.Encoding.utf8)
            print(dataString)

            if let response = response as? HTTPURLResponse, response.statusCode == 200 && httpError == nil {
                completionHandler(publicUrl, httpError)
            } else {
                completionHandler(nil, httpError)
            }
        }
        uploadTask.resume()
    }
    
    private func createRequest(remotefilename: String) -> URLRequest {
        let url = URL(string: "https://www.googleapis.com/upload/storage/v1/b/\(bucket)/o?name=\(remotefilename)&uploadType=media")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpg", forHTTPHeaderField: "Content-Type")
        return request
    }
}

extension String {
    static func random(length: Int = 20) -> String {
        let charSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var c = charSet.characters.map { String($0) }
        var s:String = ""
        for _ in (1...length) {
            s.append(c[Int(arc4random()) % c.count])
        }
        return s
    }
}



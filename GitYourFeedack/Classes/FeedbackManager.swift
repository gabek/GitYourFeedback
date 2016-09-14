//
//  FeedbackManager.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/10/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import UIKit

public protocol FeedbackManagerUploadTargetDelegate {
    func uploadUrl() -> String
}

public class FeedbackManager: NSObject {
    var uploadUrlDelegate: FeedbackManagerUploadTargetDelegate?
    
    var githubApiToken: String
    var githubRepo: String
    var labels: [String]?
    
    let googleStorage = GoogleStorage()
    
    public init(githubApiToken: String, repo: String, googleUploadTargetFileDelegate: FeedbackManagerUploadTargetDelegate, labels: [String]? = nil) {
        self.githubApiToken = githubApiToken
        self.githubRepo = repo
        self.labels = labels
        self.uploadUrlDelegate = googleUploadTargetFileDelegate
        
        super.init()
        listenForScreenshot()
    }

    private func listenForScreenshot() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil, queue: OperationQueue.main) { notification in
            self.display()
        }
    }
    
    public func display(viewController: UIViewController? = nil) {
        var vc: UIViewController?
        
        // If no view controller was supplied then try to use the root vc
        if let viewController = viewController {
            vc = viewController
        } else if let viewController = UIApplication.shared.keyWindow?.rootViewController {
            vc = viewController
        }
        
        if let vc = vc {
            vc.present(FeedbackViewController(reporter: self), animated: true, completion: nil)
        } else {
            fatalError("No view controller to present GKBugreporter on")
        }
    }
    
    func submit(title: String, body: String, screenshotData: Data?, completionHandler: @escaping (Bool) -> Void) {
        if let screenshotData = screenshotData {
            
            guard let googleStorageUrl = uploadUrlDelegate?.uploadUrl() else {
                fatalError("No URL to upload the screenshot to.")
                return
            }

            googleStorage.upload(data: screenshotData, urlString: googleStorageUrl) { (publicUrl, error) in
                guard let publicUrl = publicUrl else {
                    return
                }

                let finalBody = body + "\n\n![Screenshot](\(publicUrl))"
                self.createIssue(title: title, body: finalBody, labels: self.labels, completionHandler: completionHandler)
            }
        } else {
            self.createIssue(title: title, body: body, labels: labels, completionHandler: completionHandler)
        }
    }
    
    private func createIssue(title: String, body: String, labels: [String]? = nil, completionHandler: @escaping (Bool) -> Void) {
        var payload: [String:Any] = ["title": title, "body": body]
        if let labels = labels {
            payload["labels"] = labels
        }
        
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        } catch let error as NSError {
            print(error)
            completionHandler(false)
        }

        if let jsonData = jsonData {
            var request = createRequest()
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                completionHandler(true)
            }
            task.resume()
        }
    }
    
    private func createRequest() -> URLRequest {
        let url = URL(string: "https://api.github.com/repos/\(githubRepo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let basicAuthString = "gabek:\(self.githubApiToken)"
        let userPasswordData = basicAuthString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData?.base64EncodedString()
        let authString = "Basic \(base64EncodedCredential!)"
        request.setValue(authString, forHTTPHeaderField: "Authorization")
        return request
    }
}

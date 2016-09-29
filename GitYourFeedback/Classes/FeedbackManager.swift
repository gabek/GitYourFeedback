//
//  FeedbackManager.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/10/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import UIKit

// This is required in order to know where to upload your screenshot to at the
// time of submission.  Generate the filename any way you like as long as 
// the result is a valid Google Cloud Storage destination.
public protocol FeedbackRemoteStorageDelegate {
    func uploadUrl(_ completionHandler: (String) -> Void)
}

public class FeedbackManager: NSObject {
    var feedbackRemoteStorageDelegate: FeedbackRemoteStorageDelegate?
    
    // The Personal Access Token to access Github
    var githubApiToken: String
    // The user that generated the above Personal Access Token and has access
    // to the repository.
    var githubUser: String
    
    // The Github repository in username/repo format where the issue will
    // be saved.
    var githubRepo: String
    // An array of strings that will be the labels associated to each issue.
    var githubIssueLabels: [String]?
    
    let googleStorage = GoogleStorage()
    
    public init(githubApiToken: String, githubUser: String, repo: String, feedbackRemoteStorageDelegate: FeedbackRemoteStorageDelegate, issueLabels: [String]? = nil) {
        self.githubApiToken = githubApiToken
        self.githubRepo = repo
        self.githubUser = githubUser
        self.githubIssueLabels = issueLabels
        self.feedbackRemoteStorageDelegate = feedbackRemoteStorageDelegate
        
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
            
            feedbackRemoteStorageDelegate?.uploadUrl({ (googleStorageUrl) in
                googleStorage.upload(data: screenshotData, urlString: googleStorageUrl) { (publicUrl, error) in
                    guard let publicUrl = publicUrl else {
                        return
                    }
                    
                    let finalBody = body + "\n\n![Screenshot](\(publicUrl))"
                    self.createIssue(title: title, body: finalBody, labels: self.githubIssueLabels, completionHandler: completionHandler)
                }
            })
            

        } else {
            self.createIssue(title: title, body: body, labels: githubIssueLabels, completionHandler: completionHandler)
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
        
        // Github uses HTTP Basic auth using the username and Personal Access
        // Toekn for authentication.
        let basicAuthString = "\(githubUser):\(githubApiToken)"
        let userPasswordData = basicAuthString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData?.base64EncodedString()
        let authString = "Basic \(base64EncodedCredential!)"
        request.setValue(authString, forHTTPHeaderField: "Authorization")
        return request
    }
    
    public static var userEmailAddress: String? {
        set {
            Helpers.saveEmail(email: newValue)
        }
        
        get {
            return Helpers.email()
        }
    }
}

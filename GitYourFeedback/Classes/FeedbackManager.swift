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
@objc public protocol FeedbackManagerDatasource {
    @objc func uploadUrl(_ completionHandler: (String) -> Void)
	@objc optional func additionalData() -> String?
}

public class FeedbackManager: NSObject {
    var datasource: FeedbackManagerDatasource?
    
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
    
    var feedbackViewController: FeedbackViewController?
    
    public init(githubApiToken: String, githubUser: String, repo: String, feedbackRemoteStorageDelegate: FeedbackManagerDatasource, issueLabels: [String]? = nil) {
        self.githubApiToken = githubApiToken
        self.githubRepo = repo
        self.githubUser = githubUser
        self.githubIssueLabels = issueLabels
        self.datasource = feedbackRemoteStorageDelegate
        
        super.init()
        listenForScreenshot()
    }

    private func listenForScreenshot() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil, queue: OperationQueue.main) { notification in
            self.display(viewController: nil, shouldFetchScreenshot: true)
        }
    }
    
    public func display(viewController: UIViewController? = nil, shouldFetchScreenshot: Bool = false) {
        var vc: UIViewController?
        
        // If no view controller was supplied then try to use the root vc
        if let viewController = viewController {
            vc = viewController
        } else if let viewController = UIApplication.shared.keyWindow?.rootViewController {
            vc = viewController
        }
        
        if let vc = vc {
            feedbackViewController = FeedbackViewController(reporter: self, shouldFetchScreenshot: shouldFetchScreenshot)
            vc.present(feedbackViewController!, animated: true, completion: nil)
        } else {
            fatalError("No view controller to present FeedbackManager on")
        }
    }
    
    internal func submit(title: String, body: String, screenshotData: Data?, completionHandler: @escaping (Result<Bool>) -> Void) {
        if let screenshotData = screenshotData {
            
            datasource?.uploadUrl({ (googleStorageUrl) in
                var screenshotURL: String?
                
                googleStorage.upload(data: screenshotData, urlString: googleStorageUrl) { (result) in
                    do {
                        screenshotURL = try result.resolve()
                    } catch GitYourFeedbackError.ImageUploadError(let errorMessage){
                        completionHandler(Result.Failure(GitYourFeedbackError.ImageUploadError(errorMessage)))
                    } catch {
                        completionHandler(Result.Failure(GitYourFeedbackError.ImageUploadError(error.localizedDescription)))
                    }
                    
                    guard let screenshotUrl = screenshotURL else {
                        return
                    }
                    
                    self.createIssue(title: title, body: body, labels: self.githubIssueLabels, screenshotURL: screenshotURL, completionHandler: completionHandler)
                }
            })
            

        } else {
            self.createIssue(title: title, body: body, labels: githubIssueLabels, screenshotURL: nil, completionHandler: completionHandler)
        }
    }
    
    private func createIssue(title: String, body: String, labels: [String]? = nil, screenshotURL: String?, completionHandler: @escaping (Result<Bool>) -> Void) {
        var finalBody = body
        
        if let additionalDataString = datasource?.additionalData?() {
            finalBody += "\n\n" + additionalDataString
        }
        
        if let screenshotURL = screenshotURL {
            finalBody += "\n\n![Screenshot](\(screenshotURL))"
        }
        
        var payload: [String:Any] = ["title": title, "body": finalBody]
        if let labels = labels {
            payload["labels"] = labels
        }
        
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        } catch let error as NSError {
            print(error)
            completionHandler(Result.Failure(error))
        }

        if let jsonData = jsonData {
            var request = createRequest()
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    return
                }
                
                // If it wasn't successful, handle the error
                if response.statusCode != 201 {
                    self.handleGithubError(response: response, completionHandler: completionHandler)
                    return
                }
                
                completionHandler(Result.Success(true))
            }
            task.resume()
        }
    }
    
    private func handleGithubError(response: HTTPURLResponse, completionHandler: @escaping (Result<Bool>) -> Void) {
        var errorMessage = String()
        
        if let status = response.allHeaderFields["Status"] as? String {
            errorMessage += status
        }
        
        errorMessage += " for repo \(githubRepo)."
        DispatchQueue.main.sync {
            completionHandler(Result.Failure(GitYourFeedbackError.GithubSaveError(errorMessage)))
        }
    }
    
    private func createRequest() -> URLRequest {
        let url = URL(string: "https://api.github.com/repos/\(githubRepo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Github uses HTTP Basic auth using the username and Personal Access
        // Toekn for authentication.
        let authString = "\(githubUser):\(githubApiToken)".gitHubAuthString()
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

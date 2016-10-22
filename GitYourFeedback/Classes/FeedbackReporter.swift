//
//  FeedbackManager.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/10/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import UIKit

/// This is required in order to know where to upload your screenshot to at the time of submission.
/// Generate the filename any way you like as long as the result is a valid Google Cloud Storage destination.
@objc public protocol FeedbackReporterDatasource {
    
    @objc func uploadUrl(_ completion: (String) -> Void)
	@objc optional func additionalData() -> String?
}

public protocol FeedbackOptions {
    /// The Personal Access Token to access a repository
    var token: String { get set }
    /// The user that generated the above Personal Access Token and has access to the repository.
    var user: String { get set }
    /// The repository in username/repo format where the issue will be saved.
    var repo: String { get set }
    /// An array of strings that will be the labels associated to each issue.
    var issueLabels: [String] { get set }
}

open class FeedbackReporter {
    
    private (set) var options: FeedbackOptions?
    open var datasource: FeedbackReporterDatasource?
    
    private let googleStorage = GoogleStorage()
    
    var feedbackViewController: FeedbackViewController?
    
    public init(options: FeedbackOptions) {
        self.options = options
        
        self.listenForScreenshot()
    }

    private func listenForScreenshot() {
        let name = NSNotification.Name.UIApplicationUserDidTakeScreenshot
        
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: OperationQueue.main) { notification in
            self.display(viewController: nil, shouldFetchScreenshot: true)
        }
    }
    
    public func display(viewController: UIViewController?, shouldFetchScreenshot: Bool = false) {
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
    
    internal func submit(title: String, body: String, screenshotData: Data?, completionHandler: @escaping (Bool) -> Void) {
        
        if let screenshotData = screenshotData {
            datasource?.uploadUrl({ (googleStorageUrl) in
                googleStorage.upload(data: screenshotData, urlString: googleStorageUrl) { (screenshotURL, error) in
                    guard let screenshotURL = screenshotURL else { return }
                    
                    self.createIssue(title: title, body: body, labels: self.options?.issueLabels, screenshotURL: screenshotURL, completionHandler: completionHandler)
                }
            })
            

        } else {
            self.createIssue(title: title, body: body, labels: self.options?.issueLabels, screenshotURL: nil, completionHandler: completionHandler)
        }
    }
    
    private func createIssue(title: String, body: String, labels: [String]? = nil, screenshotURL: String?, completionHandler: @escaping (Bool) -> Void) {
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
            completionHandler(false)
        }

        if let jsonData = jsonData {
            guard var request = createRequest() else { return }
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    return
                }
                
                // If it wasn't successful, handle the error
                if response.statusCode != 201 {
                    self.handleGithubError(response: response)
                    return
                }
                
                completionHandler(true)
            }
            task.resume()
        }
    }
    
    private func handleGithubError(response: HTTPURLResponse) {
        var errorMessage = String()
        
        if let status = response.allHeaderFields["Status"] as? String {
            errorMessage += status
        }
        
        errorMessage += " for repo \(self.options?.repo)."
        DispatchQueue.main.sync {
            self.feedbackViewController?.displayErrorMessage(title: "Error saving feedback", body: errorMessage)
        }
    }
    
    private func createRequest() -> URLRequest? {
        guard let repo = self.options?.repo else { return nil }
        
        let url = URL(string: "https://api.github.com/repos/\(repo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Github uses HTTP Basic auth using the username and Personal Access Token for authentication.
        let basicAuthString = "\(self.options?.user):\(self.options?.token)"
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

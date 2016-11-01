//
//  FeedbackReporter.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/10/16.
//  Copyright © 2016 Gabe Kangas. All rights reserved.
//

import Foundation
import UIKit

import Mustache

/// This is required in order to know where to upload your screenshot to at the time of submission.
/// Generate the filename any way you like as long as the result is a valid Google Cloud Storage destination.
@objc public protocol FeedbackReporterDatasource {
    
    @objc func uploadUrl(_ completion: (String) -> Void)
	@objc optional func additionalData() -> String?
    /// An array of strings that will be the labels associated to each issue.
	@objc optional func issueLabels() -> [String]?
}

public protocol FeedbackOptions {
    /// The Personal Access Token to access a repository
    var token: String { get set }
    /// The user that generated the above Personal Access Token and has access to the repository.
    var user: String { get set }
    /// The repository in username/repo format where the issue will be saved.
    var repo: String { get set }
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
	
    public func display(viewController: UIViewController? = nil, shouldFetchScreenshot: Bool = false) {
        guard let topmostViewController = UIViewController.topmostViewController else {
            fatalError("No view controller to present FeedbackManager on")
        }
        
        // Don't allow the the UI to be presented if it's already the top VC
        if topmostViewController is FeedbackViewController {
            return
        }
        
        feedbackViewController = FeedbackViewController(reporter: self, shouldFetchScreenshot: shouldFetchScreenshot)
        topmostViewController.present(feedbackViewController!, animated: true, completion: nil)
    }
    
    internal func submit(title: String, body: String?, email: String, screenshotData: Data?, completionHandler: @escaping (Result<Bool>) -> Void) {
        // Verify we have a datasource, it's requird.
        guard let datasource = datasource else {
            assertionFailure("A datasource must be set in order to how to upload screenshots.")
            return
        }
        
        // Optional additional data string provided by the datasource
        let additionalDataString = datasource.additionalData?()
        
        if let screenshotData = screenshotData {
            
            datasource.uploadUrl({ (googleStorageUrl) in
                
                var screenshotURL: String?
                
                googleStorage.upload(data: screenshotData, urlString: googleStorageUrl) { (result) in
                    
                    do {
                        screenshotURL = try result.resolve()
                    } catch GitYourFeedbackError.ImageUploadError(let errorMessage){
                        completionHandler(Result.Failure(GitYourFeedbackError.ImageUploadError(errorMessage)))
                    } catch {
                        completionHandler(Result.Failure(GitYourFeedbackError.ImageUploadError(error.localizedDescription)))
                    }
                    
                    guard let screenshotURL = screenshotURL else { return }
                    let issueBody = self.generateIssueContents(title: title, body: body, email: email, screenshotURL: screenshotURL, additionalData: additionalDataString)
                    self.createIssue(issueTitle: title, issueBody: issueBody, screenshotURL: screenshotURL, completionHandler: completionHandler)
                }
            })

        } else {
            let issueBody = self.generateIssueContents(title: title, body: body, email: email, screenshotURL: nil, additionalData: additionalDataString)
            self.createIssue(issueTitle: title, issueBody: issueBody, screenshotURL: nil, completionHandler: completionHandler)
        }
    }
    
    private func generateIssueContents(title: String, body: String?, email: String, screenshotURL: String?, additionalData: String?) -> String {
        let bundle = Bundle(for: FeedbackInterfaceViewController.self)
        let template = try! Template(named: "issueTemplate", bundle: bundle, templateExtension: "md", encoding: String.Encoding.utf8)
        template.register(StandardLibrary.each, forKey: "each")

        var templateData = [String:Any]()
        templateData["title"] = title
        templateData["email"] = email
        templateData["applicationDetails"] = Helpers.applicationDetails()
        
        if let additionalData = additionalData {
            templateData["additionalData"] = additionalData
        }
        
        if let screenshotURL = screenshotURL {
            templateData["screenshotURL"] = screenshotURL
        }
        
        if let body = body {
            templateData["body"] = body
        }
        
        let rendering = try! template.render(templateData)
        return rendering
    }
    
    private func createIssue(issueTitle: String, issueBody: String, screenshotURL: String?, completionHandler: @escaping (Result<Bool>) -> Void) {
        var payload: [String:Any] = ["title": "Feedback: " + issueTitle, "body": issueBody]
        if let labels = self.datasource?.issueLabels?() {
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
            guard var request = createRequest() else { return }
            
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
        
        errorMessage += " for repo \(self.options?.repo)."
        DispatchQueue.main.sync {
            completionHandler(Result.Failure(GitYourFeedbackError.GithubSaveError(errorMessage)))
        }
    }
    
    private func createRequest() -> URLRequest? {
        guard let repo = self.options?.repo else { return nil }
        
        let url = URL(string: "https://api.github.com/repos/\(repo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
		
		guard let user = options?.user, let token = options?.token else {
			return nil
		}
		
        let basicAuth = "\(user):\(token)".basicAuthString()
        
        request.setValue(basicAuth, forHTTPHeaderField: "Authorization")
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

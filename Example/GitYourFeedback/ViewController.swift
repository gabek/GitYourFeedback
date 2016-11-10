//
//  ViewController.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 09/11/2016.
//  Copyright (c) 2016 Gabe Kangas. All rights reserved.
//

import UIKit
import GitYourFeedback

class ViewController: UIViewController {

    var feedback: FeedbackReporter!
    let feedbackReportingOptions = FeedbackReportingOptions(token: Config.githubApiToken, user: Config.githubUser, repo: Config.githubRepo)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.feedback = FeedbackReporter(options: feedbackReportingOptions)
        self.feedback.datasource = self
        
        view.backgroundColor = UIColor.white
        
        view.addSubview(button)
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(self, action: #selector(display), for: .touchUpInside)
        
        view.addSubview(label)
        label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -50).isActive = true
    }
    
    func display() {
        self.feedback.display(viewController: self)
    }
    
    private let button: UIButton = {
        let button = UIButton(type: UIButtonType.roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Provide Feedback", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.blue
        return button
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Take a screenshot or press button to provide feedback"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
}

extension ViewController: FeedbackReporterDatasource {
    
    public func uploadUrl(_ completionHandler: (String) -> Void) {
        let filename = String(Date().timeIntervalSince1970) + ".jpg"
        let url = "https://www.googleapis.com/upload/storage/v1/b/\(Config.googleStorageBucket)/o?name=\(filename)"
        completionHandler(url)
    }
    
    public func additionalData() -> String? {
        return "This is additional data that was added via the FeedbackManagerDatasource.\n\nYou can put whatever you want here."
    }
	
	public func issueLabels() -> [String]? {
		return ["Feedback", "Bugs", "Anything"]
	}
}

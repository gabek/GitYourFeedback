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

    var feedback: FeedbackManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        feedback = FeedbackManager(githubApiToken: Config.githubApiToken, githubUser: Config.githubUser, repo: Config.githubRepo, feedbackRemoteStorageDelegate: self, issueLabels: ["Feedback", "Bugs"])
        
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
        feedback.display(viewController: self)
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

extension ViewController: FeedbackRemoteStorageDelegate {
    func uploadUrl() -> String {
        let filename = String(Date().timeIntervalSince1970) + ".jpg"
        let url = "https://www.googleapis.com/upload/storage/v1/b/\(Config.googleStorageBucket)/o?name=\(filename)"
        return url
    }
}

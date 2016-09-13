//
//  ViewController.swift
//  GitYourFeedack
//
//  Created by Gabe Kangas on 09/11/2016.
//  Copyright (c) 2016 Gabe Kangas. All rights reserved.
//

import UIKit
import GitYourFeedack

class ViewController: UIViewController {

     let feedback = FeedbackManager(githubApiToken: Config.githubApiToken, repo: Config.githubRepo, googleStorageBucket: Config.googleStorageBucket, labels: ["Test Label 1", "Test Label 2"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        view.addSubview(button)
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(self, action: #selector(display), for: .touchUpInside)
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
}

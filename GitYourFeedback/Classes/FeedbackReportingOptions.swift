//
//  FeedbackReportingOptions.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 11/8/16.
//
//

import Foundation

public struct FeedbackReportingOptions: FeedbackOptions {
    public init(token: String, user: String, repo: String) {
        self.token = token
        self.user = user
        self.repo = repo
    }
    
    // The GitHub personal access token for the below user
    public var token: String
    /// The user that generated the above Personal Access Token and has access to the repository.
    public var user: String
    /// The Github repository in username/repo format where the issue will be saved.
    public var repo: String
}

# GitYourFeedack

[![CI Status](http://img.shields.io/travis/Gabe Kangas/GitYourFeedack.svg?style=flat)](https://travis-ci.org/Gabe Kangas/GitYourFeedack)
[![Version](https://img.shields.io/cocoapods/v/GitYourFeedack.svg?style=flat)](http://cocoapods.org/pods/GitYourFeedack)
[![License](https://img.shields.io/cocoapods/l/GitYourFeedack.svg?style=flat)](http://cocoapods.org/pods/GitYourFeedack)
[![Platform](https://img.shields.io/cocoapods/p/GitYourFeedack.svg?style=flat)](http://cocoapods.org/pods/GitYourFeedack)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
* Google Cloud Storage bucket for storing the screenshots.
* Github repository for storing the issues.

## Installation

GitYourFeedack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "GitYourFeedack"
```

1. Generate a [Personal Access Token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) for the Github user who will be saving the issues in your repo.

2. In your project's `Info.plist` add a key of `NSPhotoLibraryUsageDescription` with a string explaining that your use of the photo library is for submitting screenshots.

3. In your AppDelegate, or some other long-lived controller:

```
let feedback = FeedbackManager(githubApiToken: "abc123", repo: "gabek/GKBugreportertest", googleStorageBucket: "myapp-storage-bucket.appspot.com", labels: ["Feedback", "Bugs", "Whatever Github Labels You Want"])
```

4. The user feedback interface can be presented in either of these ways:

* Manually fire `feedback.display()` with an optional specific view controller to present from
* or it can automatically show up as the result of the user taking a screenshot.

## Author

Gabe Kangas, gabek@real-ity.com

## License

GitYourFeedack is available under the MIT license. See the LICENSE file for more info.

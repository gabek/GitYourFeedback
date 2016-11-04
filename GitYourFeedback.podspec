#
# Be sure to run `pod lib lint GitYourFeedback.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GitYourFeedback'
  s.version          = '0.1.1'
  s.summary          = 'Let users submit feedback and bugs with screenshots, directly from your iOS app to Github Issues.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Instead of routing your users to GitHub and expecting them to file issues, or copying and pasting from emails into GitHub, allow users to easily submit feedback and bugs right from within your application.
                       DESC

  s.homepage         = 'https://github.com/gabek/GitYourFeedback'
  s.screenshots     = 'https://raw.githubusercontent.com/gabek/GitYourFeedback/master/ClientScreenshot.png', 'https://github.com/gabek/GitYourFeedback/raw/master/GithubScreenshot.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Gabe Kangas' => 'gabek@real-ity.com' }
  s.source           = { :git => 'https://github.com/gabek/GitYourFeedback.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/gabek'

  s.ios.deployment_target = '9.0'

  s.source_files = 'GitYourFeedback/Classes/**/*'

  s.resources = 'GitYourFeedback/Assets/**/*'

  s.dependency 'GRMustache.swift'
  s.dependency 'CLImageEditor'
  s.dependency 'CLImageEditor/TextTool'
end

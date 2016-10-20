//
//  Helpers.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 9/12/16.
//
//

import Foundation

struct Helpers {
    static let defaultsSuiteName = "com.gabekangas.gityourfeedback"
    static let emailKey = "emailAddress"
    
    static func saveEmail(email: String?) {
        let defaults = UserDefaults(suiteName: Helpers.defaultsSuiteName)
        defaults?.set(email, forKey: Helpers.emailKey)
        defaults?.synchronize()
    }
    
    static func email() -> String? {
        let defaults = UserDefaults(suiteName: Helpers.defaultsSuiteName)
        if let email = defaults?.value(forKey: Helpers.emailKey) as? String? {
            return email
        }
        return nil
    }
    
    static func templateText() -> String {
        var template = "\n\n ------------------------ Details ------------------------"
        
        // App bundle, version and build number
        if let appDisplayVersion = Helpers.appDisplayVersion() {
            template += "\n**App Version:** \(appDisplayVersion)"
        }
		
		// iOS Version
		template += "\n**iOS Version:** " + UIDevice.current.systemVersion
		
        // Device name and screen resolution
        let width = String(Int(UIScreen.main.bounds.size.width))
        let height = String(Int(UIScreen.main.bounds.size.height))
        template += "\n**Device:** " + UIDevice.modelName()
		template += "\n**Screen:** " + "\(width) x \(height)"
		
		// Timezone and Language
		if let timezone = TimeZone.current.abbreviation() {
			template += "\n**Timezone:** " + timezone
		}
		template += "\n**Language:** " + NSLocale.preferredLanguages[0]
        
        return template
    }
    
    static func appDisplayVersion() -> String? {
        if let bundleId = Bundle.main.bundleIdentifier, let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String {
            return "\(bundleId) \(appVersion) build \(buildNumber)"
        }
        return nil
    }
}

extension UIDevice {
    
    static func modelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}

extension URLComponents {
	mutating func appendQueryItem(name name: String, value: String) {
		var queryItems: [URLQueryItem] = self.queryItems ?? [URLQueryItem]()
		queryItems.append(URLQueryItem(name: name, value: value))
		self.queryItems = queryItems
	}
}

extension String {
    func gitHubAuthString() -> String {
        let userPasswordData = data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData?.base64EncodedString()
        let authString = "Basic \(base64EncodedCredential!)"
        return authString
    }
	
	var isValidEmail: Bool {
		do {
			let regex = try NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
			return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count)) != nil
		} catch {
			return false
		}
	}

}

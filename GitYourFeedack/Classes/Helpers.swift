//
//  Helpers.swift
//  Pods
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
}

//
//  Errors.swift
//  GitYourFeedback
//
//  Created by Gabe Kangas on 10/17/16.
//
//
// Using the approach partially documented at
// http://alisoftware.github.io/swift/async/error/2016/02/06/async-errors/ so
// check that out if you want to contribute.

import Foundation

enum Result<T> {
    case Success(T)
    case Failure(Error)
}

enum GitYourFeedbackError: Error {
    case ImageUploadError(String)
    case GithubSaveError(String)
}


extension Result {
    // Return the value if it's a .Success or throw the error if it's a .Failure
    func resolve() throws -> T {
        switch self {
        case Result.Success(let value): return value
        case Result.Failure(let error): throw error
        }
    }
    
    // Construct a .Success if the expression returns a value or a .Failure if it throws
    init( _ throwingExpr: () throws -> T) {
        do {
            let value = try throwingExpr()
            self = Result.Success(value)
        } catch {
            self = Result.Failure(error)
        }
    }
}

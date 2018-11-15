//
//  ApplicationHeader.swift
//  iosinfinitescrollingcloudant
//
//  Created by Aaron Liberatore on 2/14/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation

enum ApplicationError: Error {

    case invalidCredentials

    case missingCredentials

    case invalidDatabase

    case missingField

    case JSONParseError

    case error(String)
}

extension ApplicationError: CustomStringConvertible {

    var title: String {
        switch self {
        case .invalidCredentials : return "Invalid Cloudant Credentials"
        case .missingCredentials : return "Missing Cloudant Credentials"
        case .invalidDatabase    : return "Invalid Database"
        case .missingField       : return "Missing Document Field"
        case .JSONParseError     : return "JSON Deserialization Error"
        case .error              : return "An Error Occurred"
        }
    }

    public var description: String {
        let readme = "Please check the readme for instructions on setting up your Cloudant database."

        switch self {
        case .error(let msg):
            return msg
        case .invalidCredentials:
            return "The provided credentials are invalid. Ensure that the correct values are in your BMSCredentials.plist."
        case .missingCredentials:
            return "The Cloudant credentials do not exist. \(readme)"
        case .invalidDatabase:
            return "A database does not exist for the given Cloudant instance. \(readme)"
        case .missingField:
            return "A Cloudant document with a field name does not exist. \(readme)"
        case .JSONParseError:
            return "The parser could not parse the provided json. Please ensure document consistency in order to use this application."
        }
    }
}

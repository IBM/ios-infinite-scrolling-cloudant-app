//
//  CloudantItem.swift
//  iosinfinitescrollingcloudant
//
//  Created by Aaron Liberatore on 2/14/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import Foundation

/// Wrapper for the Cloudant Data
struct CloudantItem: Decodable {

    private let doc: CloudantDoc

    var id: String {
        return doc.id
    }

    var rev: String {
        return doc.rev
    }

    var fieldValue: String {
        return doc.value
    }
}

/// Structure to encapsulate the document containing all the Cloudant fields
struct CloudantDoc: Decodable {

    var id: String

    var rev: String

    var value: String

    // Custom Dynamic CodingKeys implementation to be used by the JSONDecoder
    private struct CodingKeys: CodingKey {

        var intValue: Int?

        var stringValue: String

        init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }

        init?(stringValue: String) { self.stringValue = stringValue }

        static let id = CodingKeys(stringValue: "_id")!

        static let rev = CodingKeys(stringValue: "_rev")!

        static func makeKey(name: String) -> CodingKeys {
            return CodingKeys(stringValue: name)!
        }
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        guard let field = CloudantViewModel.cloudantField else {
            throw ApplicationError.error("A field name does not exist")
        }

        id = try values.decode(String.self, forKey: .id)
        rev = try values.decode(String.self, forKey: .rev)
        value = try values.decode(String.self, forKey: CodingKeys.makeKey(name: field))
    }
}

/// Structure to encapsulate the rows object returned by Cloudant
struct CloudantRows: Decodable {
    let rows: [CloudantItem]
    let total_rows: Int
}

//
//  CloudantViewModel.swift
//  iosinfinitescrollingcloudant
//
//  Created by Aaron Liberatore on 2/14/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import SwiftSpinner
import BMSCore

/// Protocol defining a data receiver
protocol CloudantDataReceiver: class {
    func didRecieveItems()
    func showError(_ error: ApplicationError)
}

/// Model containing all the data logic
class CloudantViewModel {

    // Data Receiver
    weak var delegate: CloudantDataReceiver?

    // Cloudant item field
    static var cloudantField: String?

    // Items
    var state: [CloudantItem] = []

    // The key to start retrieving data from
    private var startKey: String?

    // Number of documents to retrieve at a time
    private let block: Int = 10

    // Indicates whether the view model has been configured
    private var isConfigured: Bool = false

    // Indicates whether the view model is already querying the database
    private var isLoading: Bool = false

    // Size of Database
    private var databaseCount: Int = 0

    // Cloudant Database name
    private var cloudantDB: String?

    // Cloudant Endpoint
    private let cloudantURL: URL

    // Default Shared session
    private var session: URLSession = URLSession.shared

    // Default URLSessionConfiguration
    private var sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default

    // Logger
    fileprivate let logger = Logger.logger(name: "CloudantClient")

    // Initializer
    public init(userId: String, password: String, cloudantURL: URL) {

        // Set Credentials
        self.cloudantURL = cloudantURL

        // Configure url session authorization
        setupSession(userId: userId, password: password)

        // Configure database options
        setupDatabase()
    }

    /// MARK: - Public API

    // When the user displays xx% of the data, retrieve more.
    public func tryToRetrieveItems(_ indexPath: IndexPath) {

        // When should we reload the page 0% -> 100% of rows already seen
        // Defaults to 100%
        let displayedPercentage = 1.0
        let limit = Int(floor(Double(state.count) * displayedPercentage))

        // If we've viewed xx% of the cells, try to retrieve more.
        if state.count < databaseCount, indexPath.row + 1 == limit {
            retrieveItems()
        }
    }

    // Retrieves the item from the state
    public func retrieveItem(at indexPath: IndexPath) -> CloudantItem? {
        return state[indexPath.row]
    }

    // Initiates a network call to retrieve more items from the database
    public func retrieveItems() {
        guard isConfigured, !isLoading else {
            return
        }

        isLoading = true
        getItems()
    }

    // Number of items in state
    public func numberOfItemsInState() -> Int {
        return state.count
    }

    /// MARK: - Configuration

    // Configure Session authorization
    private func setupSession(userId: String, password: String) {

        // Encode authorization header
        let authStr = userId + ":" + password

        // Encode string as base64
        guard let data = authStr.data(using: .utf8)?.base64EncodedString() else {
            logger.error(message: "Could not encode authorization header")
            delegate?.showError(.error("Could not encode authorization header. Please check that your credentials use utf8 encodable charcaters."))
            return
        }

        // Append to session
        let authData = "Basic \(data)"
        sessionConfig.httpAdditionalHeaders = ["Authorization": authData]
        self.session = URLSession(configuration: sessionConfig)
    }

    // Configure database and field to be used
    private func setupDatabase() {

        SwiftSpinner.show("Configuring Cloudant")

        /// Retrieve an available database
        getCloudantDBName { db in

            self.cloudantDB = db
            self.logger.debug(message: "Using the cloudant database: \(db)")

            /// Retrieve a field from the database
            self.getCloudantFieldName { field in

                CloudantViewModel.cloudantField = field
                self.logger.debug(message: "Using the cloudant field: \(field)")

                DispatchQueue.main.async {
                    self.isConfigured = true
                    self.retrieveItems()
                    SwiftSpinner.hide()
                }
            }
        }
    }
}

/// Extension for database requests
extension CloudantViewModel {

    // Get items from Cloudant
    fileprivate func getItems() {

        logger.debug(message: "Retrieving documents")

        // Ensure we have a database
        guard let db = checkEmpty(cloudantDB) else {
            self.delegate?.showError(.invalidDatabase)
            return
        }

        // Ensure we have the necessary fields
        guard checkEmpty(CloudantViewModel.cloudantField) != nil else {
            self.delegate?.showError(.missingField)
            return
        }

        // Convert url to URLComponents
        guard var queryURL = URLComponents(string: cloudantURL.absoluteString) else {
            logger.error(message: "Could not create URLComponents from cloudantURL")
            self.delegate?.showError(.error("Unable to parse url"))
            return
        }

        // Append path and query Items
        queryURL.path = "/" + db + "/_all_docs"
        var items = [ URLQueryItem(name: "include_docs", value: "true"),
                      URLQueryItem(name: "limit", value: String(block))
                    ]

        if let key = startKey {
             items.append(URLQueryItem(name: "startkey", value: "\"\(key)\""))
             items.append(URLQueryItem(name: "skip", value: String(1)))
        }

        queryURL.queryItems = items

        // Convert back to URL
        guard let url = queryURL.url else {
            logger.error(message: "Could not create url string from URLComponents")
            self.delegate?.showError(.error("Unable to parse url"))
            return
        }

        request(url: url) { data in
            do {
                self.isLoading = false
                let response = try JSONDecoder().decode(CloudantRows.self, from: data)
                if let item = response.rows.last {
                    self.startKey = item.id
                }
                self.state.append(contentsOf: response.rows)
                self.databaseCount = response.total_rows
                self.delegate?.didRecieveItems()
            } catch {
                self.delegate?.showError(.JSONParseError)
            }
        }
    }

    // Get the first DB name from Cloudant that does not start with a _. Admin permissions are required for this method to work
    fileprivate func getCloudantDBName(success: @escaping (String) -> Void) {

        logger.debug(message: "Retrieving an available Cloudant Database")

        let queryURL = cloudantURL.appendingPathComponent("/_all_dbs")

        request(url: queryURL) { data in
            let dbs = try? JSONDecoder().decode([String].self, from: data)

            guard let db = dbs?.first else {
                self.logger.error(message: "There are no databases available")
                self.delegate?.showError(.invalidDatabase)
                return
            }

            success(db)
        }
    }

    //Get the first Cloudant field name that does not start with a _
    fileprivate func getCloudantFieldName(success: @escaping (String) -> Void) {

        logger.debug(message: "Retrieving Cloudant Field Name")

        // Convert url to URLComponents
        guard var queryURL = URLComponents(string: self.cloudantURL.absoluteString),
              let db = checkEmpty(cloudantDB) else {
            delegate?.showError(.error("Could not retrieve a field name"))
            return
        }

        // Update path and query items
        queryURL.path = "/" + db + "/_all_docs"
        queryURL.queryItems = [ URLQueryItem(name: "include_docs", value: "true"),
                                URLQueryItem(name: "limit", value: "1") ]

        // Convert to URL
        guard let url = queryURL.url else {
            delegate?.showError(.error("Could not retrieve a field name"))
            return
        }

        // Perform request
        request(url: url) { data in
            do {
                // Deserialize JSON
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let totalRows = json["total_rows"] as? String, let count = Int(totalRows) {
                        self.databaseCount = count
                    }
                    let rows = json["rows"] as? [Any]
                    if let row = rows?.first as? [String: Any] {
                        if let doc = row["doc"] as? [String: Any] {
                            for (key, _) in doc {
                                if !key.hasPrefix("_") && CloudantViewModel.cloudantField == nil {
                                    return success(key)
                                }
                            }
                        }
                    }
                }
                self.delegate?.showError(.missingField)
            } catch {
                self.delegate?.showError(.JSONParseError)
            }
        }
    }

    // Overload to accept url
    private func request(url: URL, success: @escaping (Data) -> Void) {
        request(request: URLRequest(url: url), success: success)
    }

    // Helper method to execute requests and parse response
    private func request(request: URLRequest, success: @escaping (Data) -> Void) {

        logger.debug(message: "\nRequesting URL: \(String(describing: request.url?.absoluteString ?? ""))")

        /// Execute request
        session.dataTask(with: request) { data, _, sessionError in

            /// Retrieve data
            guard let data = data, sessionError == nil else {
                let msg = sessionError?.localizedDescription ?? "No data provided from Cloudant"
                self.delegate?.showError(.error(msg))
                return
            }

            /// Handle data
            success(data)

        }.resume()
    }

    /// Helper method to check if a string is nil or empty
    private func checkEmpty(_ str: String?) -> String? {
        if let s = str {
            return s.isEmpty ? nil : s
        }
        return nil
    }
}

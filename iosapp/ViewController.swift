//
//  ViewController.swift
//  iosinfinitescrollingcloudant
//
//  Created by Aaron Liberatore on 2/14/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import SwiftSpinner
import BMSCore






class ViewController: UITableViewController {

    @IBOutlet var cloudantTableView: UITableView!

    // Logger
    let logger = Logger.logger(name: "ViewController")
    // Cloudant Driver
    var client: CloudantViewModel?

    

    override func viewDidLoad() {

        // Setup refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        self.tableView.addSubview(refreshControl)

        // Register observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        // Set up Cloudant Driver
        configureCloudant()

        
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        self.client?.retrieveItems()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Callback for view becoming active
    @objc func didBecomeActive(notification: NSNotification) {
        
        
    }

    // Refresh Handler
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.logger.debug(message: "Refreshing data")
        self.client?.retrieveItems()
        refreshControl.endRefreshing()
    }

    // Setup cloudant driver
    func configureCloudant() {

        // Retrieve plist
        guard let path = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist"),
            let credentials = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
                showError(.missingCredentials)
                return
        }
        
        guard let cloudantConfig = credentials["cloudant"] as? NSDictionary else {
            showError(.missingCredentials)
            return
        }

        // Retrieve credentials
        guard let userId = cloudantConfig["username"] as? String, !userId.isEmpty,
            let password = cloudantConfig["password"] as? String, !password.isEmpty,
            let url = cloudantConfig["url"] as? String, !url.isEmpty, let cloudantURL = URL(string: url) else {
                showError(.missingCredentials)
                return
        }

        self.client = CloudantViewModel(userId: userId, password: password, cloudantURL: cloudantURL)
        self.client?.delegate = self
    }
}

extension ViewController: CloudantDataReceiver {

    // Callback method to reload the tableview when more data is available
    func didRecieveItems() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // Display alert error
    func showError(_ error: ApplicationError) {
        // Log Error
        logger.error(message: error.title + " : " + error.description)
        // Hide Spinner
        SwiftSpinner.hide()
        // Present error in alert controller
        DispatchQueue.main.async {
            if self.presentedViewController == nil {
                // Set alert properties
                let alert = UIAlertController(title: error.title, message: error.description, preferredStyle: .alert)
                // Add an action to the alert
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                // Show the alert
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

// TableViewController Conformance
extension ViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return client?.numberOfItemsInState() ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "CloudantTableViewCell"

        // Fetches the appropriate cloudant item for the data source layout.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CloudantTableViewCell else {
            return CloudantTableViewCell()
        }

        guard let item = client?.retrieveItem(at: indexPath) else {
            return CloudantTableViewCell()
        }

        cell.titleLabel.text = item.fieldValue
        cell.selectionStyle = .none

        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        client?.tryToRetrieveItems(indexPath)
    }
}



[![](https://img.shields.io/badge/IBM%20Cloud-powered-blue.svg)](https://bluemix.net)
[![Platform](https://img.shields.io/badge/platform-ios_swift-lightgrey.svg?style=flat)](https://developer.apple.com/swift/)

# Create an infinite scrolling iOS application in Swift, backed by a NoSQL database

In this code pattern, you will create an infinite scrolling iOS application, similar to the user experience you'd find in popular apps like Twitter or Instagram. Instead of building a paginated list of data, data will be continuously pulled from a Cloudant NoSQL database. 

When you have completed this code pattern, you will understand how to:

* provision and integrate a Cloudant NoSQL database,
* enable infinite scrolling in the application, and
* connect to additional IBM Cloud services.

## Steps

1. [Install developer tools](#1-install-developer-tools)
2. [Install dependencies](#2-install-dependencies)
3. [Load sample data](#3-load-sample-data)

### 1. Install developer tools

Ensure you have the [required developer tools installed from Apple](https://developer.apple.com/download/):

* iOS 9.0+
* Xcode 9.0
* Swift 4.0

### 2. Install dependencies

This pattern uses the IBM Cloud Mobile services and Cloudant SDKs in order to use the functionality of the Mobile Analytics, Push Notifications, and Cloudant services.

The IBM Cloud Mobile services SDK uses [CocoaPods](https://cocoapods.org/) to manage and configure dependencies.

You can install CocoaPods using the following command:

```bash
sudo gem install cocoapods
```

If the CocoaPods repository is not configured, run the following command (this may take a long time depending on your network connection and installation state):

```bash
pod setup
```

A pre-configured `Podfile` has been included in this repository. To download and install the required dependencies, run the following command from your project directory:

```bash
pod install
```

If you run into any issues during the pod install, it is recommended to run a pod update by using the following commands:

```bash
pod update
```

```bash
pod install
```

Finally, open the Xcode workspace: `{APP_Name}.xcworkspace`.

No additional configuration is required for the iOS app. Your unique Cloudant credentials have been injected in during generation. The application will default to the first database and field it finds, so be sure to import valid data.

### 3. Load sample data

To help demonstrate the infinite scrolling capability, we need to load a dataset large enough to require scrolling into our NoSQL database. This repository contains a file called `countries.json` which contains 245 documents, each with the names of a country. From the root of the repository, run:

```bash
chmod +x setup_cloudant.sh
sh setup_cloudant.sh
```

## Run

In Xcode, click **Product** > **Run** to start the app.

![Cloudant App Screenshot](README_Images/cloudant.png)

## License

[Apache 2.0](LICENSE)

import AVFoundation
import Flutter
import GoogleMaps
import CoreLocation
import UIKit
import CoreMedia
import Stripe
import ContactsUI
import Foundation
import Photos
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate, CNContactPickerDelegate {
    let locationManager = CLLocationManager()
    var dartDefinesDictionary = [String:String]()
    var isDarkMode = ""
    var result: FlutterResult?
    var contactPickerResult: FlutterResult?
    var contactPickerMaxCount: Int = 5

    override func applicationWillTerminate(_ application: UIApplication) {
        self.clearAllNotifications()
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let maxCount = max(1, contactPickerMaxCount)
        guard let presenter = picker.presentingViewController else { return }
        if contacts.count > maxCount {
            picker.dismiss(animated: true) {
                self.contactPickerResult?(FlutterError(
                    code: "LIMIT_EXCEEDED",
                    message: "You can select only \(maxCount) contacts",
                    details: nil
                ))
                self.contactPickerResult = nil
                self.contactPickerMaxCount = 5
                self.showLimitAlert(from: presenter, max: maxCount)
            }
            return
        }
        let limitedContacts = Array(contacts.prefix(maxCount))
        let contactList = limitedContacts.compactMap { contact -> [String: Any]? in
            guard let phone = contact.phoneNumbers.first?.value.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                  !phone.isEmpty else {
                return nil
            }
            return [
                "name": CNContactFormatter.string(from: contact, style: .fullName) ?? "",
                "phone": phone
            ]
        }
        picker.dismiss(animated: true) {
            self.contactPickerResult?(contactList)
            self.contactPickerResult = nil
            self.contactPickerMaxCount = 5
        }
        contactPickerResult?(contactList)
        contactPickerResult = nil
        contactPickerMaxCount = 5
    }

    func showLimitAlert(from presenter: UIViewController, max: Int) {
        let alert = UIAlertController(
            title: "Limit exceeded",
            message: "You can select only \(max) contacts",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true) {
            self.contactPickerResult?([])
            self.contactPickerResult = nil
            self.contactPickerMaxCount = 5
        }
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        setupFlutterChannels(binaryMessenger: engineBridge.applicationRegistrar.messenger())
    }

    private func setupFlutterChannels(binaryMessenger: FlutterBinaryMessenger) {
        let locationChannel = FlutterMethodChannel(name: "getLocation",
                                                   binaryMessenger: binaryMessenger)
        locationChannel.setMethodCallHandler({ [weak self]
            (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self else { return }

            if call.method == "getLocation" {
                self.locationManager.startUpdatingLocation()
                result("\(self.locationManager.location?.coordinate.latitude ?? 0.0)///\(self.locationManager.location?.coordinate.longitude ?? 0.0)///\(0.0)")
            } else if call.method == "setMapKey" {
                if let jsonResult = call.arguments as? Dictionary<String, AnyObject> {
                    let googleMapsApiKey = jsonResult["key"] as? String ?? ""
                    GMSServices.initialize()
                    GMSServices.provideAPIKey(googleMapsApiKey)
                }
            } else if call.method == "CheckLocationService" {
                result(CLLocationManager.locationServicesEnabled())
            } else if call.method == "securityKey" {
                result(Bundle.main.infoDictionary!["API_Security_Key"] as! String)
            } else if call.method == "EnableLocationService" {
                let alert = UIAlertController(
                    title: "Location is Disabled",
                    message: "To use location, go to your Settings App > Privacy > Location Services.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                if let presenter = self.topViewController() {
                    presenter.present(alert, animated: true, completion: nil)
                }
                result(true)
            } else if call.method == "changeThemeMode" {
                guard let args = call.arguments as? [String: Any] else { return }
                self.isDarkMode = args["isDarkMode"] as! String
                if self.isDarkMode == "false" {
                    if #available(iOS 13.0, *) {
                        UIApplication.shared.statusBarStyle = .darkContent
                    }
                } else {
                    UIApplication.shared.statusBarStyle = .lightContent
                }
            } else if call.method == "appversion" {
                result(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
            }
            if call.method == "clearNotify" {
                self.clearAllNotifications()
            }
        })

        let contactPickerChannel = FlutterMethodChannel(
            name: "contact_picker",
            binaryMessenger: binaryMessenger
        )
        contactPickerChannel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "pickContacts":
                if self.contactPickerResult != nil {
                    result(FlutterError(code: "ALREADY_ACTIVE", message: "A contact picker is already open", details: nil))
                    return
                }
                let args = call.arguments as? [String: Any]
                let maxCount = max(1, args?["maxCount"] as? Int ?? 5)
                self.contactPickerMaxCount = maxCount
                self.contactPickerResult = result
                let picker = CNContactPickerViewController()
                picker.delegate = self
                picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
                guard let presenter = self.topViewController() else {
                    self.contactPickerResult = nil
                    result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Unable to present contact picker", details: nil))
                    return
                }
                presenter.present(picker, animated: true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        let audioChannel = FlutterMethodChannel(name: "audio_merge",
                                                binaryMessenger: binaryMessenger)
        audioChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self else { return }
            if call.method == "mergeAudioFiles" {
                guard let args = call.arguments as? [String: Any],
                      let inputPaths = args["inputPaths"] as? [String],
                      let outputPath = args["outputPath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                    return
                }
                self.mergeAudioFiles(inputPaths: inputPaths, outputPath: outputPath) { success, error in
                    if success {
                        result(outputPath)
                    } else {
                        result(FlutterError(code: "MERGE_FAILED", message: error?.localizedDescription ?? "Unknown error", details: nil))
                    }
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    } // end setupFlutterChannels



    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if StripeAPI.handleURLCallback(with: url) {
            return true
        }
        return super.application(app, open: url, options: options)
    }

    private func clearAllNotifications() {
        if #available(iOS 10.0, *) {
            UIApplication.shared.applicationIconBadgeNumber = 0
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications()
            center.removeAllPendingNotificationRequests()
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    private func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .rootViewController
    ) -> UIViewController? {
        if let navigationController = base as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }
        if let tabBarController = base as? UITabBarController {
            return topViewController(base: tabBarController.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }

    func mergeAudioFiles(inputPaths: [String], outputPath: String, completion: @escaping (Bool, Error?) -> Void) {
        let composition = AVMutableComposition()
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var insertTime = kCMTimeZero

        for path in inputPaths {
            let url = URL(fileURLWithPath: path)
            let asset = AVAsset(url: url)
            do {
                if let track = asset.tracks(withMediaType: .audio).first {
                    let range = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
                    try audioTrack?.insertTimeRange(range, of: track, at: insertTime)
                    insertTime = CMTimeAdd(insertTime, asset.duration)
                }
            } catch {
                completion(false, error)
                return
            }
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, NSError(domain: "AudioMerge", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
            return
        }

        let outputURL = URL(fileURLWithPath: outputPath)
        try? FileManager.default.removeItem(at: outputURL)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(true, nil)
            case .failed:
                completion(false, exportSession.error)
            case .cancelled:
                completion(false, NSError(domain: "AudioMerge", code: -2, userInfo: [NSLocalizedDescriptionKey: "Export cancelled"]))
            default:
                completion(false, NSError(domain: "AudioMerge", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unknown export status"]))
            }
        }
    }

} // end AppDelegate
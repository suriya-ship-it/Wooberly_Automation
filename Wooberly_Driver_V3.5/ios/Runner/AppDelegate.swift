import UIKit
import AVFoundation
import Flutter
import GoogleMaps
import CoreLocation
import Apollo
import CoreData

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate, FlutterStreamHandler, UIAlertViewDelegate {

    // MARK: - FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil
    }

    // MARK: - Properties
    var batteryChannel: FlutterMethodChannel!
    let locationManager = CLLocationManager()
    var timer: Timer?
    var stringToken = ""
    var declineduration = 20
    var userid = ""
    var deviceid = ""
    var mapkey = ""
    var isDarkMode = ""
    var token: [NSManagedObject] = []
    var lastTimestamp = Date.distantPast
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var knownHeading = CLHeading()
    var isEnterForeground: Bool = false
    let preferences = UserDefaults.standard
    let LocationFetchinterval = "LocationFetchinterval"

    private var _eventSink: FlutterEventSink?

    var declineTimer: Timer?
    var declineTimerBookingId: String?
    var backgroundAudioPlayer: AVAudioPlayer?
    var backgroundAVPlayer: AVPlayer?

    var locationlat = String()
    var locationsArray = [Double]()
    var rotationbearing = Double()
    var dartDefinesDictionary = [String: String]()
    var isNeedUpdateLocation: Bool = false

    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "database")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - FlutterImplicitEngineDelegate
    //
    // With the UIScene lifecycle, GeneratedPluginRegistrant and all method channel
    // setup must move here from application(_:didFinishLaunchingWithOptions:).
    // This is called once the implicit FlutterEngine is initialised, before the
    // scene is connected, so accessing window/rootViewController here is safe.
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        // 1. Register all plugins
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        let messenger = engineBridge.applicationRegistrar.messenger()

        // 2. bringtoforeground channel
        let bringtoforegroundChannel = FlutterMethodChannel(
            name: "bringtoforeground",
            binaryMessenger: messenger)
        bringtoforegroundChannel.setMethodCallHandler { (call, result) in
            if call.method == "bringtoforeground" {
                // handle foreground request if needed
            }
        }

        // 3. Auth token / trip info channel
        let tokenChannel = FlutterMethodChannel(
            name: "getAuthToken",
            binaryMessenger: messenger)
        tokenChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            if call.method == "getAuthToken" {
                guard let args = call.arguments as? [String: Any] else { return }
                self.stringToken = args["token"] as? String ?? ""
                self.declineduration = args["declineduration"] as? Int ?? 20
                self.userid     = args["userid"] as? String ?? ""
                self.deviceid   = args["deviceid"] as? String ?? ""
                let tripAudioURL = args["tripAudioURL"] as? String ?? ""

                if self.stringToken.isEmpty {
                    self.deleteAllRecords()
                } else {
                    self.save(token: self.stringToken, userid: self.userid, deviceid: self.deviceid, declineduration: self.declineduration, tripAudioURL: tripAudioURL)
                    if !tripAudioURL.isEmpty && tripAudioURL != "null" {
                        self.downloadAndCacheAudio(urlString: tripAudioURL)
                    }
                }
                result(nil)
            }

            if call.method == "setTripInfo" {
                guard let args = call.arguments as? [String: Any] else { return }
                let riderid    = args["riderid"] as? String ?? ""
                let bookingid  = args["bookingid"] as? String ?? ""
                let userid     = args["userid"] as? String ?? ""
                let declineduration = args["declineduration"] as? Int ?? self.declineduration

                if self.stringToken.isEmpty {
                    self.deleteAllRecords()
                } else {
                    self.saveTripInfo(userid: userid, riderid: riderid, bookingid: bookingid, declineduration: declineduration)
                }
                result(nil)
            }

            if call.method == "stopBackgroundAudio" {
                self.stopBackgroundAudio()
                result(nil)
            }
        }

        // 4. Location / map / app-version channel
        let locationChannel = FlutterMethodChannel(
            name: "getLocation",
            binaryMessenger: messenger)
        locationChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            if call.method == "getLocation" {
                self.isNeedUpdateLocation = true
                self.startLocationUpdate(requestAuth: true)
                
                if(self.locationsArray.isEmpty){
                    
                    result("\(self.locationManager.location?.coordinate.latitude ?? 0.0)///\(self.locationManager.location?.coordinate.longitude ?? 0.0)///\(0.0)")
                } else {
                    result("\(self.locationsArray.first ?? 0.0)///\(self.locationsArray.last ?? 0.0)///\(0.0)")
                }
            } else if call.method == "isiOSAppInBackground" {
                result(UIApplication.shared.applicationState == .background)
            } else if call.method == "setMapKey" {
                if let jsonResult = call.arguments as? [String: AnyObject] {
                    let googleMapsApiKey = jsonResult["key"] as? String ?? ""
                    GMSServices.initialize()
                    GMSServices.provideAPIKey(googleMapsApiKey)
                }
            } else if call.method == "appversion" {
                result(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
            } else if call.method == "CheckLocationService" {
                if #available(iOS 14.0, *) {
                    result(CLLocationManager.locationServicesEnabled())
                } else {
                    let status = CLLocationManager.authorizationStatus()
                    result(status != .denied)
                }
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
                self.isDarkMode = args["isDarkMode"] as? String ?? "false"
                if self.isDarkMode == "false" {
                    if #available(iOS 13.0, *) {
                        UIApplication.shared.statusBarStyle = .darkContent
                    }
                } else {
                    UIApplication.shared.statusBarStyle = .lightContent
                }
            }
        }

        // 5. Background location event channel
        let eventChannel = FlutterEventChannel(
            name: "Background Location Fetch",
            binaryMessenger: messenger)
        eventChannel.setStreamHandler(self)

        // 6. Stop/Start iOS service channel
        let serviceChannel = FlutterMethodChannel(
            name: "Stop iOS Service Channel",
            binaryMessenger: messenger)
        serviceChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            if call.method == "stopService" {
                self.timer?.invalidate()
                self.timer = nil
                result("")
            } else if call.method == "startService" {
                guard let args = call.arguments as? [String: Any] else { return }
                let locationinterval = args["locationFetchInterval"] as? Int ?? 30
                self.preferences.set(locationinterval, forKey: self.LocationFetchinterval)
                self.preferences.synchronize()
                let currentLevel = Double(self.preferences.integer(forKey: self.LocationFetchinterval))
                if self.timer == nil {
                    self.timer = Timer.scheduledTimer(
                        timeInterval: currentLevel,
                        target: self,
                        selector: #selector(self.updatelocation),
                        userInfo: nil,
                        repeats: true)
                }
                result("")
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        // 7. Audio merge channel
        let audioChannel = FlutterMethodChannel(
            name: "audio_merge",
            binaryMessenger: messenger)
        audioChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

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

        // 8. Wakelock channel
        let wakeLockChannel = FlutterMethodChannel(
            name: "Wakelock channel",
            binaryMessenger: messenger)
        wakeLockChannel.setMethodCallHandler { (call, result) in
            let dictionary = call.arguments as? [String: Any]
            UIApplication.shared.isIdleTimerDisabled = (dictionary?["lockStatus"] as? String == "1")
        }

        // 9. Start location updates
        self.startLocationUpdate()
    }

    // MARK: - application(_:didFinishLaunchingWithOptions:)
    //
    // Keep this minimal. Do NOT access window/rootViewController or register
    // plugins here — the UIScene lifecycle means the window may not exist yet.
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIApplication.shared.beginReceivingRemoteControlEvents()

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        if let launchOptions = launchOptions, launchOptions.keys.contains(.location) {
            self.locationManager.delegate = self
            self.locationManager.allowsBackgroundLocationUpdates = true
            self.locationManager.showsBackgroundLocationIndicator = true
            self.locationManager.pausesLocationUpdatesAutomatically = false
            self.locationManager.startMonitoringSignificantLocationChanges()
            self.locationManager.startUpdatingLocation()
        } else {
            self.locationManager.stopMonitoringSignificantLocationChanges()
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - App lifecycle

    override func applicationWillTerminate(_ application: UIApplication) {
        isEnterForeground = false
        self.startLocationUpdate()
        self.locationManager.startMonitoringSignificantLocationChanges()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        isEnterForeground = true
        self.stopBackgroundAudio()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        isEnterForeground = false
        self.startLocationUpdate()
        self.locationManager.startMonitoringSignificantLocationChanges()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func startLocationUpdate(requestAuth: Bool = false) {
           self.locationManager.delegate = self
           self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
           // Use 5.0m distance filter instead of kCLDistanceFilterNone to reduce GPS chip overheating
           self.locationManager.distanceFilter = 5.0
           let status = CLLocationManager.authorizationStatus()
           if status == .authorizedAlways || status == .authorizedWhenInUse {
               self.locationManager.showsBackgroundLocationIndicator = true
               self.locationManager.allowsBackgroundLocationUpdates = true
               self.locationManager.pausesLocationUpdatesAutomatically = false
               self.locationManager.stopUpdatingLocation()
               self.locationManager.stopMonitoringSignificantLocationChanges()
               self.locationManager.startUpdatingLocation()
           } else if requestAuth {
               self.locationManager.requestAlwaysAuthorization()
               self.locationManager.showsBackgroundLocationIndicator = true
               self.locationManager.allowsBackgroundLocationUpdates = true
               self.locationManager.pausesLocationUpdatesAutomatically = false
               self.locationManager.stopUpdatingLocation()
               self.locationManager.stopMonitoringSignificantLocationChanges()
               self.locationManager.startUpdatingLocation()
           }
       }

    func deleteAllRecords() {
        let context = self.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "AuthToken")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("There was an error")
        }
        // Also clear UserDefaults so background sessions are properly invalidated
        preferences.removeObject(forKey: "bg_token")
        preferences.removeObject(forKey: "bg_userid")
        preferences.removeObject(forKey: "bg_deviceid")
        preferences.removeObject(forKey: "bg_riderid")
        preferences.removeObject(forKey: "bg_bookingid")
        preferences.removeObject(forKey: "declineduration")
        preferences.removeObject(forKey: "bg_tripAudioURL")
        preferences.removeObject(forKey: "local_trip_audio_path")
        
        // Also delete the physical cached audio file if it exists
        let destinationURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("background_trip_audio.mp3")
        try? FileManager.default.removeItem(at: destinationURL)
        
        preferences.synchronize()
        self.locationManager.stopUpdatingLocation()
        self.locationManager.stopMonitoringSignificantLocationChanges()
    }

    func bearingBetween(startLatitude: Double, startLongitude: Double, endLatitude: Double, endLongitude: Double) {
        let PI = 3.14159
        let lat1  = startLatitude  * PI / 180
        let long1 = startLongitude * PI / 180
        let lat2  = endLatitude    * PI / 180
        let long2 = endLongitude   * PI / 180

        let dLon = long2 - long1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var brng = atan2(y, x)
        brng = degrees(n: brng)
        brng = ((brng + 360).truncatingRemainder(dividingBy: 360))
        rotationbearing = brng
    }

    func radians(n: Double) -> Double { n * (M_PI / 180) }
    func degrees(n: Double) -> Double { n * (180 / M_PI) }
    func logC(val: Double, forBase base: Double) -> Double { log(val) / log(base) }

    @objc func updatelocation() {
        let state = UIApplication.shared.applicationState
        isEnterForeground = (state == .active)

      

        if isEnterForeground {
            _eventSink?("\(self.locationManager.location?.coordinate.latitude ?? 0.0)///\(self.locationManager.location?.coordinate.longitude ?? 0.0)///\(0)///\(0)///")
        } else {
            self.locationManager.stopUpdatingLocation()
            self.locationManager.startUpdatingLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied:
            print("Location permission denied")
        case .restricted:
            print("Location permission restricted")
        case .notDetermined:
            print("Location permission notDetermined")
        @unknown default:
            fatalError()
        }
    }

    @objc func update() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        knownHeading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue = manager.location?.coordinate else { return }

        let previouslat = locationsArray.first
        let previouslng = locationsArray.last
        locationsArray.removeAll()
        locationsArray.append(locValue.latitude)
        locationsArray.append(locValue.longitude)

        // Read auth data from UserDefaults — safe in background/terminated state even on locked device
        let bgToken    = preferences.string(forKey: "bg_token")    ?? ""
        let bgDeviceId = preferences.string(forKey: "bg_deviceid") ?? ""
        let bgUserId   = preferences.string(forKey: "bg_userid")   ?? ""
        let bgRiderId  = preferences.string(forKey: "bg_riderid")  ?? ""
        let bgBookingId = preferences.string(forKey: "bg_bookingid") ?? "0"
        let declineduration = preferences.object(forKey: "declineduration") as? Int ?? 20

        guard !bgToken.isEmpty, !bgDeviceId.isEmpty else {
            self.locationManager.stopMonitoringSignificantLocationChanges()
            self.locationManager.stopUpdatingLocation()
            return
        }

        if !isEnterForeground {

            let now = Date()
            let interval = TimeInterval(now.timeIntervalSince(lastTimestamp))
            let currentLevel = Double(self.preferences.integer(forKey: self.LocationFetchinterval))

            if interval >= currentLevel {
                lastTimestamp = now
                bearingBetween(
                    startLatitude:  previouslat ?? 0.0,
                    startLongitude: previouslng ?? 0.0,
                    endLatitude:    locValue.latitude,
                    endLongitude:   locValue.longitude)

                var apollo_headerClient: ApolloClient!
                apollo_headerClient = {
                    let configuration = URLSessionConfiguration.default
                    configuration.httpAdditionalHeaders = ["auth": bgToken]
                    let url = URL(string: Bundle.main.infoDictionary!["URL"] as! String)!
                    return ApolloClient(networkTransport: HTTPNetworkTransport(url: url, configuration: configuration))
                }()

                print("updatelocation: latt", locationsArray.first ?? 0)
                print("updatelocation:long", locationsArray.last ?? 0)
                var updateLocation = SendDriverLocationQuery(
                    lat: locationsArray.first!,
                    lng: locationsArray.last!,
                    deviceId: bgDeviceId,
                    rotation: rotationbearing)

                if bgBookingId != "0", !bgBookingId.isEmpty {
                    updateLocation = SendDriverLocationQuery(
                        lat: locationsArray.first ?? 0.0,
                        lng: locationsArray.last!,
                        riderId:   bgRiderId.isEmpty  ? nil : bgRiderId,
                        deviceId:  bgDeviceId,
                        rotation:  rotationbearing,
                        bookingId: Int(bgBookingId))
                }

                self.startBackgroundTask()
                apollo_headerClient.fetch(query: updateLocation, cachePolicy: .fetchIgnoringCacheData) { [weak self] (result, error) in
                    guard let self = self else { return }
                    print("SendDriverLocationQuery", result?.data?.sendDriverLocation?.status ?? -1)
                    print("bgToken", bgToken ?? "")
                    print("bgDeviceId", bgDeviceId ?? "")
                    print("declineduration", declineduration)
                    guard result?.data?.sendDriverLocation?.status == 200 else {
                        self.endBackgroundTask()
                        return
                    }

                    let getTripStatus = GetTripStatusQuery()
                    apollo_headerClient.fetch(query: getTripStatus, cachePolicy: .fetchIgnoringCacheData) { [weak self] (getTripStatusresult, error) in
                        guard let self = self else { return }
                        let tripStatus = getTripStatusresult?.data?.getTripStatus?.result?.tripStatus
                        print("istripCreated", tripStatus ?? "nil")
                        print("istripCreated", getTripStatusresult?.data?.getTripStatus?.result?.updatedAt ?? "nil")
                        
                        if tripStatus == "created" {
                            guard let bookingId = getTripStatusresult?.data?.getTripStatus?.result?.id,
                                  let riderId = getTripStatusresult?.data?.getTripStatus?.result?.riderId else {
                                self.endBackgroundTask()
                                return
                            }

                            let updatedAtMs = Double(getTripStatusresult?.data?.getTripStatus?.result?.updatedAt ?? "") ?? 0.0

                            self.scheduleDeclineTimerIfNeeded(
                                bookingId: String(bookingId),
                                riderId: riderId,
                                userId: bgUserId,
                                token: bgToken,
                                updatedAtMs: updatedAtMs,
                                declineDurationSeconds: declineduration
                            )
                           // self.playBackgroundAudio()
                            self.endBackgroundTask()
                        } else {
                          //  self.stopBackgroundAudio()
                            self.endBackgroundTask()
                        }
                    }
                }
            } else {
                locationsArray.append(locValue.latitude)
                locationsArray.append(locValue.longitude)
            }
        }
    }

    func startBackgroundTask() {
        self.endBackgroundTask()
        self.backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DriverLocationUpdate") { [weak self] in
            self?.endBackgroundTask()
        }
    }

    func endBackgroundTask() {
        if self.backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
    }

    /// Schedules a decline-booking timer for the remaining duration only if one
    /// isn't already running for this booking. Since sendDriverLocation (and
    /// therefore this whole getTripStatus check) fires repeatedly on an interval,
    /// this guard is what stops it from resetting an already-running countdown.
    func scheduleDeclineTimerIfNeeded(
        bookingId: String,
        riderId: String,
        userId: String,
        token: String,
        updatedAtMs: Double,
        declineDurationSeconds: Int
    ) {
        if declineTimer != nil, declineTimerBookingId == bookingId {
            // Already counting down for this exact booking — leave it alone.
            return
        }

        // Timer belongs to a stale/different booking (or none) — clear it before starting fresh.
        invalidateDeclineTimer()

        let nowMs = Date().timeIntervalSince1970 * 1000
        let elapsedSeconds = (nowMs - updatedAtMs) / 1000
        let remainingSeconds = Double(declineDurationSeconds) - elapsedSeconds

        declineTimerBookingId = bookingId

        if remainingSeconds <= 0 {
            fireDeclineBooking(token: token, bookingId: bookingId, userId: userId, riderId: riderId)
            return
        }

        // Timers need a run loop to fire; schedule explicitly on the main run loop
        // in .common mode so it still fires while the app is backgrounded.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let timer = Timer(timeInterval: remainingSeconds, repeats: false) { [weak self] _ in
                self?.fireDeclineBooking(token: token, bookingId: bookingId, userId: userId, riderId: riderId)
            }
            RunLoop.main.add(timer, forMode: .common)
            self.declineTimer = timer
        }
    }

    func invalidateDeclineTimer() {
        declineTimer?.invalidate()
        declineTimer = nil
        declineTimerBookingId = nil
    }

    func fireDeclineBooking(token: String, bookingId: String, userId: String, riderId: String) {
        invalidateDeclineTimer()
        self.stopBackgroundAudio()
     if !isEnterForeground {
        let bookingfield: [String: Any] = [
            "auth": token,
            "bookingId": bookingId,
            "userId": userId,
            "riderId": riderId
        ]

        var bookingdata = ""
        do { bookingdata = try self.json(from: bookingfield) }
        catch { print("json error: ", error) }

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["auth": token]
        guard let url = URL(string: Bundle.main.infoDictionary!["URL"] as! String) else { return }
        let client = ApolloClient(networkTransport: HTTPNetworkTransport(url: url, configuration: configuration))

        let declineBooking = DeclineBookingQuery(requestStatus: "decline", data: bookingdata)
        client.fetch(query: declineBooking, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            if result?.data?.declineBooking?.status == 200 {
                print("booking is declined (timer expired)")
            } else {
              print("booking is declined (timer expired) 400")
              }
        }
        }
    }


    

    func json(from object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object)
        return String(data: data, encoding: .utf8)!
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered Region")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited Region")
        locationManager.stopMonitoring(for: region)
        locationManager.startUpdatingLocation()
    }

    func createRegion(location: CLLocation?) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self),
              let location = location else {
            print("System can't track regions")
            return
        }
        let coordinate = location.coordinate
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            radius: 50.0,
            identifier: "aabb")
        region.notifyOnExit  = true
        region.notifyOnEntry = true
        self.startLocationUpdate()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        print("error\(error)")
    }

    // MARK: - CoreData

    func save(token: String, userid: String, deviceid: String, declineduration: Int, tripAudioURL: String = "") {
        let managedContext = self.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "AuthToken", in: managedContext)!
        let person = NSManagedObject(entity: entity, insertInto: managedContext)
        person.setValue(token,    forKeyPath: "token")
        person.setValue(userid,   forKey: "userid")
        person.setValue(deviceid, forKey: "deviceid")
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        // Mirror to UserDefaults so background/terminated location updates can read safely
        preferences.set(token,    forKey: "bg_token")
        preferences.set(userid,   forKey: "bg_userid")
        preferences.set(deviceid, forKey: "bg_deviceid")
        preferences.set(declineduration, forKey: "declineduration")
        preferences.set(tripAudioURL, forKey: "bg_tripAudioURL")
        preferences.synchronize()
        self.startLocationUpdate()
    }

    func saveTripInfo(userid: String, riderid: String, bookingid: String, declineduration: Int) {
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AuthToken")
        fetchRequest.predicate = NSPredicate(format: "userid = %@", userid)
        do {
            let results = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
            if let results = results, results.count != 0 {
                results[results.count - 1].setValue(riderid,   forKey: "riderid")
                results[results.count - 1].setValue(bookingid, forKey: "bookingid")
            }
        } catch {
            print("Fetch Failed: \(error)")
        }
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        // Mirror trip info to UserDefaults so background/terminated location updates can read safely
        preferences.set(riderid,   forKey: "bg_riderid")
        preferences.set(bookingid, forKey: "bg_bookingid")
        preferences.set(declineduration, forKey: "declineduration")
        preferences.synchronize()
    }

    // MARK: - Background Audio Playback

    func downloadAndCacheAudio(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        let destinationURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("background_trip_audio.mp3")
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self else { return }
            if let localURL = localURL {
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    
                    var attributes = [FileAttributeKey: Any]()
                    attributes[.protectionKey] = FileProtectionType.none
                    try FileManager.default.setAttributes(attributes, ofItemAtPath: destinationURL.path)
                    
                    self.preferences.set(destinationURL.path, forKey: "local_trip_audio_path")
                    self.preferences.synchronize()
                    print("Successfully downloaded and cached background audio with none file protection to: \(destinationURL.path)")
                } catch {
                    print("Error caching audio file: \(error)")
                }
            } else if let error = error {
                print("Error downloading audio file: \(error)")
            }
        }
        task.resume()
    }

    func playBackgroundAudio() {
        if (backgroundAudioPlayer?.isPlaying == true) || (backgroundAVPlayer?.rate ?? 0.0 > 0.0) {
            print("Background audio is already playing.")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }

        let localPath = preferences.string(forKey: "local_trip_audio_path") ?? ""
        if !localPath.isEmpty, FileManager.default.fileExists(atPath: localPath) {
            let url = URL(fileURLWithPath: localPath)
            do {
                backgroundAudioPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundAudioPlayer?.numberOfLoops = -1
                backgroundAudioPlayer?.prepareToPlay()
                backgroundAudioPlayer?.play()
                print("Playing cached background audio: \(localPath)")
                return
            } catch {
                print("Failed to play cached audio: \(error)")
            }
        }

        let bgTripAudioURL = preferences.string(forKey: "bg_tripAudioURL") ?? ""
        if !bgTripAudioURL.isEmpty && bgTripAudioURL != "null" && bgTripAudioURL.hasPrefix("http") {
            if let url = URL(string: bgTripAudioURL) {
                let playerItem = AVPlayerItem(url: url)
                backgroundAVPlayer = AVPlayer(playerItem: playerItem)
                
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(playerItemDidReachEnd(notification:)),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: playerItem
                )
                
                backgroundAVPlayer?.play()
                print("Playing streaming background audio: \(bgTripAudioURL)")
                return
            }
        }

        // Search both App.framework/flutter_assets/assets and Bundle.main
        var path: String? = nil
        let frameworkPath = Bundle.main.bundlePath + "/Frameworks/App.framework"
        if let frameworkBundle = Bundle(path: frameworkPath) {
            path = frameworkBundle.path(forResource: "flutter_assets/assets/ride_request", ofType: "mp3")
        }
        if path == nil {
            path = Bundle.main.path(forResource: "flutter_assets/assets/ride_request", ofType: "mp3")
        }

        if let audioPath = path {
            let url = URL(fileURLWithPath: audioPath)
            do {
                backgroundAudioPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundAudioPlayer?.numberOfLoops = -1
                backgroundAudioPlayer?.prepareToPlay()
                backgroundAudioPlayer?.play()
                print("Playing bundled fallback background audio")
            } catch {
                print("Failed to play bundled fallback audio: \(error)")
            }
        } else {
            print("Bundled fallback audio file not found in App.framework or Main bundle.")
        }
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
            backgroundAVPlayer?.play()
        }
    }

    func stopBackgroundAudio() {
        if backgroundAudioPlayer?.isPlaying == true {
            backgroundAudioPlayer?.stop()
        }
        backgroundAudioPlayer = nil
        
        backgroundAVPlayer?.pause()
        backgroundAVPlayer = nil
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    // MARK: - Audio merge

    func mergeAudioFiles(inputPaths: [String], outputPath: String, completion: @escaping (Bool, Error?) -> Void) {
        let composition = AVMutableComposition()
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var insertTime = CMTime.zero

        for path in inputPaths {
            let url   = URL(fileURLWithPath: path)
            let asset = AVAsset(url: url)
            do {
                if let track = asset.tracks(withMediaType: .audio).first {
                    let range = CMTimeRange(start: CMTime.zero, duration: asset.duration)
                    try audioTrack?.insertTimeRange(range, of: track, at: insertTime)
                    insertTime = CMTimeAdd(insertTime, asset.duration)
                }
            } catch {
                completion(false, error)
                return
            }
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, NSError(domain: "AudioMerge", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
            return
        }

        let outputURL = URL(fileURLWithPath: outputPath)
        try? FileManager.default.removeItem(at: outputURL)
        exportSession.outputURL      = outputURL
        exportSession.outputFileType = .m4a

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(true, nil)
            case .failed:
                completion(false, exportSession.error)
            case .cancelled:
                completion(false, NSError(domain: "AudioMerge", code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Export cancelled"]))
            default:
                completion(false, NSError(domain: "AudioMerge", code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown export status"]))
            }
        }
    }

     func topViewController(controller: UIViewController? = nil) -> UIViewController? {
            let root = controller ?? UIApplication.shared.keyWindow?.rootViewController
            if let navigationController = root as? UINavigationController {
                return topViewController(controller: navigationController.visibleViewController)
            }
            if let tabController = root as? UITabBarController {
                if let selected = tabController.selectedViewController {
                    return topViewController(controller: selected)
                }
            }
            if let presented = root?.presentedViewController {
                return topViewController(controller: presented)
            }
            return root
        }
}

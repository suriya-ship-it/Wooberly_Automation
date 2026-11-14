package com.radicalstart.wooberlydriver

import android.Manifest.permission.ACCESS_BACKGROUND_LOCATION
import android.Manifest.permission.ACCESS_FINE_LOCATION
import android.annotation.SuppressLint
import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.content.*
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.Uri
import android.os.*
import android.preference.PreferenceManager
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.location.LocationManagerCompat
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetPasswordOption
import androidx.credentials.PasswordCredential
import androidx.credentials.CreatePasswordRequest
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.exceptions.ClearCredentialException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import android.content.Context
import android.content.IntentSender
import android.location.Location


import android.app.KeyguardManager

class MainActivity : FlutterFragmentActivity(), LifecycleDetector.Listener{

    lateinit var intent: Any
    private lateinit var locationresult: Result
    var hashMap = HashMap<String, String>()
    lateinit var wakeLock: PowerManager.WakeLock
    private var locationResult1: MethodChannel.Result? = null
    @Volatile private var isFlutterUiReady: Boolean = false

    // FusedLocationProviderClient for one-shot location in getLocation()
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCancellationSource: CancellationTokenSource? = null

    // Credential Manager for Zero-Tap Sign-In / Restore Credentials (Google Play requirement Apr 2027)
    private lateinit var credentialManager: CredentialManager

    fun wakeUpScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            @Suppress("DEPRECATION")
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                "driverapp:WAKELOCK"
            )
            wakeLock?.acquire(3000L)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        // Keep the native splash until Flutter renders its first frame.
        splashScreen.setKeepOnScreenCondition { !isFlutterUiReady }
        super.onCreate(savedInstanceState)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        credentialManager = CredentialManager.create(this)
    }

    @RequiresApi(Build.VERSION_CODES.M)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        LifecycleDetector.listener = this

        MethodChannel(
            flutterEngine.dartExecutor,
            "splash_screen"
        ).setMethodCallHandler { call, result ->
            if (call.method == "ready") {
                isFlutterUiReady = true
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // ── Zero-Tap Sign-In / Restore Credentials (Google Play requirement Apr 2027) ──
        // Flutter side calls:
        //   - saveCredential(id: String, password: String)  → after successful login
        //   - restoreCredential()                           → on app launch / splash
        //   - clearCredential()                             → on logout
        MethodChannel(
            flutterEngine.dartExecutor,
            "restore_credentials"
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "saveCredential" -> {
                    val id = call.argument<String>("id") ?: ""
                    val password = call.argument<String>("password") ?: ""
                    if (id.isEmpty() || password.isEmpty()) {
                        result.error("INVALID_ARGS", "id and password must not be empty", null)
                        return@setMethodCallHandler
                    }
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            credentialManager.createCredential(
                                context = this@MainActivity,
                                request = CreatePasswordRequest(id, password)
                            )
                            CoroutineScope(Dispatchers.Main).launch { result.success(true) }
                        } catch (e: CreateCredentialException) {
                            Log.w("RestoreCredentials", "saveCredential failed: ${e.message}")
                            CoroutineScope(Dispatchers.Main).launch { result.success(false) }
                        }
                    }
                }

                "restoreCredential" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val response = credentialManager.getCredential(
                                context = this@MainActivity,
                                request = GetCredentialRequest(
                                    listOf(GetPasswordOption())
                                )
                            )
                            val credential = response.credential
                            if (credential is PasswordCredential) {
                                val map = mapOf(
                                    "id" to credential.id,
                                    "password" to credential.password
                                )
                                CoroutineScope(Dispatchers.Main).launch { result.success(map) }
                            } else {
                                CoroutineScope(Dispatchers.Main).launch { result.success(null) }
                            }
                        } catch (e: GetCredentialException) {
                            // No credential found or user cancelled – not an error for the app
                            Log.d("RestoreCredentials", "restoreCredential: ${e.message}")
                            CoroutineScope(Dispatchers.Main).launch { result.success(null) }
                        }
                    }
                }

                "clearCredential" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            credentialManager.clearCredentialState(ClearCredentialStateRequest())
                            CoroutineScope(Dispatchers.Main).launch { result.success(true) }
                        } catch (e: ClearCredentialException) {
                            Log.w("RestoreCredentials", "clearCredential failed: ${e.message}")
                            CoroutineScope(Dispatchers.Main).launch { result.success(false) }
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor,
            "bringtoforeground"
        ).setMethodCallHandler { call, result ->
            if (call.method == "bringtoforeground") {
                wakeUpScreen()
                val intent2: Intent? =
                    this.packageManager.getLaunchIntentForPackage(this.packageName)
                intent2?.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                this.startActivity(intent2)
                result.success(null)
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor,
            "getLocation"
        ).setMethodCallHandler { call, result ->
            locationresult = result
            if (call.method == "getLocation") {
                getLocation(result)
            } else if (call.method == "setMapKey") {
                val mapKey = call.argument<String>("key")
                mapKey?.let {
                    setMapKey(it)
                }
            }
            else if (call.method == "CheckLocationService") {
                result.success(CheckLocationService())
            } else if (call.method == "EnableLocationService") {
                EnableLocationService(result)
            }else if (call.method == "openLocationSettings") {
                try {
                    val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    // Fallback to general settings
                    try {
                        val fallbackIntent = Intent(Settings.ACTION_SETTINGS)
                        fallbackIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(fallbackIntent)
                        result.success(false) // opened fallback
                    } catch (ex: Exception) {
                        result.error(
                            "SETTINGS_ERROR",
                            "Could not open settings: ${ex.message}",
                            null
                        )
                    }
                }
            }

            else if (call.method == "drawoverapp") {
                if (!Settings.canDrawOverlays(this)) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:" + applicationContext.packageName)
                    )
                    startActivityForResult(intent, 4908)
                }

            } else if (call.method == "batteryoptimization") {
                val  pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:" + applicationContext.packageName)
                )


                startActivityForResult(intent, 5908)

            } else if (call.method == "osversion") {
                result.success(Build.VERSION.SDK_INT)
            }

            else if (call.method == "isAllowDrawOverApps") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    result.success(Settings.canDrawOverlays(this))
                }
            } else if (call.method == "setTripInfo") {
                riderId = call.argument("riderid")!!
                deviceID = call.argument("deviceId")!!
                bookingId = call.argument("bookingid")!!

                val prefs: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
                var editor = prefs.edit()
                editor.putString("riderid", riderId)
                editor.putString("bookingId", bookingId.toString())
                editor.commit()

            } else if (call.method == "appversion") {
                val packageManager = this!!.packageManager
                val info = packageManager.getPackageInfo(this!!.packageName, 0)
                result.success(info.versionName)
            }else if(call.method == "securityKey"){
                result.success(baseContext.getString(R.string.api_security_key))
            }
        }


        val startServiceChannel = EventChannel(
            flutterEngine.dartExecutor,
            "Background Location Fetch"
        )
        startServiceChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any, events: EventChannel.EventSink) {
                if (arguments == "updateLocation") {
                    AppService.setEvent(events)
                }
            }

            override fun onCancel(listener: Any) {

            }
        })

        MethodChannel(
            flutterEngine.dartExecutor,
            "BackGround Service Channel"
        ).setMethodCallHandler { call, result ->
            val authToken: String = call.argument("authWithUserId")!!
            val authAndUserId = authToken.split("&&")
            auth = authAndUserId[0]
            userId = authAndUserId[1]
            deviceID = authAndUserId[2]
            permissionStatus = authAndUserId[3]
            socketUrl = getString(R.string.socket_url)
            url = getString(R.string.graphql_url)
            requestTime = Integer.parseInt(authAndUserId[6]) * 1000
            locationFetchTime = Integer.parseInt(authAndUserId[7])

            val prefs: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
            var editor = prefs.edit()
            editor.putInt("requestTime", requestTime)
            editor.putInt("locationFetchTime", locationFetchTime)
            editor.commit()

            if (auth.isNotEmpty()) {
                AppService.startService(this@MainActivity, auth, userId, deviceID)
            }
            result.success("service started")
        }

        MethodChannel(flutterEngine.dartExecutor, "Stop Service Channel").setMethodCallHandler(
            object : MethodChannel.MethodCallHandler {
                override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                    val authToken: String = call.argument("authWithUserId")!!
                    val authAndUserId = authToken.split("&&")
                    auth = authAndUserId[0]
                    userId = authAndUserId[1]

                    AppService.declineHandler.removeCallbacksAndMessages(null)
                    if (call.method == "stopService") {
                        AppService.stopService(this@MainActivity)
                    }
                    result.success("service stopped")
                }
            })



        MethodChannel(
            flutterEngine.dartExecutor,
            "activityConfigure"
        ).setMethodCallHandler { call, result ->
            if (call.method == "moveTaskToBack") {
                this.moveTaskToBack(true)
                result.success(null)
            }
        }



        MethodChannel(
            flutterEngine.dartExecutor,
            "Wakelock channel"
        ).setMethodCallHandler { call, result ->
            val lockStatus: String = call.argument("lockStatus") ?: "0"
            if (lockStatus == "1") {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }

        MethodChannel(flutterEngine.dartExecutor, "audio_merge").setMethodCallHandler { call, result ->
            if (call.method == "mergeAudioFiles") {
                val inputPaths = call.argument<List<String>>("inputPaths")
                val outputPath = call.argument<String>("outputPath")
                if (inputPaths != null && outputPath != null) {
                    if (mergeAudioFiles(inputPaths, outputPath)) {
                        result.success(outputPath)
                    } else {
                        result.error("MERGE_FAILED", "Failed to merge audio files", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun mergeAudioFiles(inputPaths: List<String>, outputPath: String): Boolean {
        try {
            val muxer = android.media.MediaMuxer(outputPath, android.media.MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val bufferInfo = android.media.MediaCodec.BufferInfo()
            var audioTrackIndex = -1
            var totalDurationUs: Long = 0

            if (inputPaths.isEmpty()) return false

            val extractor = android.media.MediaExtractor()
            try {
                extractor.setDataSource(inputPaths[0])
            } catch (e: Exception) {
                return false
            }

            var trackIndex = -1
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(android.media.MediaFormat.KEY_MIME)
                if (mime?.startsWith("audio/") == true) {
                    trackIndex = i
                    audioTrackIndex = muxer.addTrack(format)
                    break
                }
            }
            extractor.release()

            if (audioTrackIndex == -1) return false

            muxer.start()

            for (path in inputPaths) {
                val partExtractor = android.media.MediaExtractor()
                try {
                    partExtractor.setDataSource(path)
                } catch (e: Exception) {
                    continue
                }

                var srcTrackIndex = -1
                for (i in 0 until partExtractor.trackCount) {
                    val format = partExtractor.getTrackFormat(i)
                    val mime = format.getString(android.media.MediaFormat.KEY_MIME)
                    if (mime?.startsWith("audio/") == true) {
                        srcTrackIndex = i
                        break
                    }
                }

                if (srcTrackIndex >= 0) {
                    partExtractor.selectTrack(srcTrackIndex)
                    val buffer = java.nio.ByteBuffer.allocate(1024 * 1024)

                    while (true) {
                        val sampleSize = partExtractor.readSampleData(buffer, 0)
                        if (sampleSize < 0) break

                        bufferInfo.offset = 0
                        bufferInfo.size = sampleSize
                        bufferInfo.flags = partExtractor.sampleFlags
                        bufferInfo.presentationTimeUs = partExtractor.sampleTime + totalDurationUs

                        muxer.writeSampleData(audioTrackIndex, buffer, bufferInfo)
                        partExtractor.advance()
                    }

                    val format = partExtractor.getTrackFormat(srcTrackIndex)
                    if (format.containsKey(android.media.MediaFormat.KEY_DURATION)) {
                        totalDurationUs += format.getLong(android.media.MediaFormat.KEY_DURATION)
                    }
                }
                partExtractor.release()
            }

            muxer.stop()
            muxer.release()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun setMapKey(mapKey: String) {
        try {
            val applicationInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            applicationInfo.metaData.putString("com.google.android.geo.API_KEY", mapKey)
        } catch (e: PackageManager.NameNotFoundException) {
            e.printStackTrace()
        }
    }


    fun startTracking() {
        // Android 11+ (API 30+): background location MUST be requested separately
        // after fine location is already granted. Requesting both together is rejected.
        if (ActivityCompat.checkSelfPermission(
                applicationContext,
                ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // Step 1: request only fine/coarse location
            ActivityCompat.requestPermissions(
                this,
                arrayOf(ACCESS_FINE_LOCATION),
                100
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            ActivityCompat.checkSelfPermission(
                applicationContext,
                ACCESS_BACKGROUND_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // Step 2: fine location already granted – now request background location
            ActivityCompat.requestPermissions(
                this,
                arrayOf(ACCESS_BACKGROUND_LOCATION),
                101
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            100 -> {
                // Fine location granted – now request background location if needed
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
                ) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                        ActivityCompat.checkSelfPermission(
                            applicationContext,
                            ACCESS_BACKGROUND_LOCATION
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(ACCESS_BACKGROUND_LOCATION),
                            101
                        )
                    } else {
                        if (auth.isNotEmpty()) {
                            AppService.startService(this@MainActivity, auth, userId, deviceID)
                        }
                    }
                }
            }
            101 -> {
                // Background location result – start service regardless (best-effort)
                if (auth.isNotEmpty()) {
                    AppService.startService(this@MainActivity, auth, userId, deviceID)
                }
            }
        }
    }


    fun isExternalStorageWritable(): Boolean {
        val state = Environment.getExternalStorageState()
        return if (Environment.MEDIA_MOUNTED == state) {
            true
        } else false
    }


    fun isExternalStorageReadable(): Boolean {
        val state = Environment.getExternalStorageState()
        return if (Environment.MEDIA_MOUNTED == state || Environment.MEDIA_MOUNTED_READ_ONLY == state) {
            true
        } else false
    }

    override fun onFlutterActivityCreated() {
    }

    override fun onFlutterActivityDestroyed() {
        if (permissionStatus != "true") {
            AppService.stopService(this)
        }
    }


    /**
     * One-shot current location fetch using FusedLocationProviderClient.
     * Replaces the deprecated NETWORK_PROVIDER LocationManager approach.
     * Works correctly on Android 14+ (API 34) and Android 17 (API 37).
     */
    @SuppressLint("MissingPermission")
    fun getLocation(result: MethodChannel.Result) {
        // Cancel any pending request
        locationCancellationSource?.cancel()
        locationCancellationSource = CancellationTokenSource()

        val request = CurrentLocationRequest.Builder()
            .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
            .setMaxUpdateAgeMillis(5_000L) // accept cached location up to 5 s old
            .build()

        fusedLocationClient
            .getCurrentLocation(request, locationCancellationSource!!.token)
            .addOnSuccessListener { location: Location? ->
                if (location != null) {
                    result.success(
                        "${location.latitude}///${location.longitude}///${location.bearing}///noUpdateApiAndPath"
                    )
                } else {
                    // Fallback: return zeros so Flutter can handle gracefully
                    result.success("0.0///0.0///0.0///noUpdateApiAndPath")
                }
            }
            .addOnFailureListener { e ->
                result.error("LOCATION_ERROR", e.message, null)
            }
    }

    fun EnableLocationService(result: MethodChannel.Result) {
        locationResult1 = result

        // Use LocationRequest.Builder (replaces deprecated LocationRequest.create())
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            10_000L
        ).build()

        val builder = LocationSettingsRequest.Builder()
            .addLocationRequest(locationRequest)
            .setAlwaysShow(true)

        val task = LocationServices.getSettingsClient(this)
            .checkLocationSettings(builder.build())

        task.addOnSuccessListener {
            result.success(true)
            locationResult1 = null
        }

        task.addOnFailureListener { e ->
            if (e is ResolvableApiException) {
                try {
                    e.startResolutionForResult(this, 999)
                } catch (sendEx: IntentSender.SendIntentException) {
                    result.success(false)
                    locationResult1 = null
                }
            } else {
                result.success(false)
                locationResult1 = null
            }
        }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == 999 && locationResult1 != null) {
            val userAccepted = (resultCode == Activity.RESULT_OK)
            locationResult1?.success(userAccepted)
            locationResult1 = null
        }
    }


    private fun CheckLocationService(): Boolean {
        val manager: LocationManager = this.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return manager != null && LocationManagerCompat.isLocationEnabled(manager)

    }

}


interface TimerChange {
    fun timerChange()
}

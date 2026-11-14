package com.radicalstart.wooberly

import android.annotation.SuppressLint
import android.app.Activity
import android.app.NotificationManager
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.IntentSender
import android.location.Criteria
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.Build
import android.provider.ContactsContract
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.*
import com.google.android.gms.tasks.CancellationToken
import com.google.android.gms.maps.MapsInitializer
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.net.Uri
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat
import android.Manifest

class MainActivity : FlutterFragmentActivity() {
    private var userId: String = ""
    var trimMemoryEvents: EventChannel.EventSink? = null
    var locationlistener: LocationListener? = null
    private lateinit var context: Context
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPermissionType: String? = null

    // ── Contact Picker (Android 17 / API 37 compliant) ──────────────────────
    // Uses ACTION_PICK on Phone.CONTENT_URI so the OS grants a temporary URI
    // permission for just the selected row — no READ_CONTACTS required.
    companion object {
        private const val CONTACT_PICKER_REQUEST        = 7201  // multi-pick (Android 17 / API 37+)
        private const val SINGLE_CONTACT_PICKER_REQUEST = 7202  // single-pick (Android < API 37 fallback)
        private const val CONTACT_CHANNEL = "contact_picker"
        private const val PERMISSION_REQUEST_CODE       = 7203
        private const val CHANNEL                       = "getLocation"
    }
    private var contactPickerResult: MethodChannel.Result? = null
    private var singleContactPickerResult: MethodChannel.Result? = null
    /** Hard cap sent from Flutter; enforced natively via EXTRA_LIMIT and in onActivityResult. */
    private var contactPickerMaxCount: Int = 5
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    override fun onDestroy() {
        channelMethodClearAllNotifications()
        super.onDestroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        context = this
        val trimMemoryChannel = EventChannel(
            flutterEngine.dartExecutor,
            "updateFlutterPage"
        )
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        trimMemoryChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any, events: EventChannel.EventSink) {
                if (arguments == "listen")
                    trimMemoryEvents = events
                Log.e("TAG", "configureFlutterEngine: "+trimMemoryEvents )
            }

            override fun onCancel(listener: Any?) {
                trimMemoryEvents = null
            }
        })
        MethodChannel(flutterEngine.dartExecutor, "getLocation").setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocation" -> getLocation(result)

                "setMapKey" -> {
                    val mapKey = call.argument<String>("key")
                    mapKey?.let { setMapKey(it) }
                }

                "CheckLocationService" -> result.success(CheckLocationService())

                "EnableLocationService" -> EnableLocationService(result)

                "openLocationSettings" -> {
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

                "closeApp" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                        this.finishAffinity()
                    }
                }

                "appversion" -> {
                    val packageManager = applicationContext!!.packageManager
                    val info = packageManager.getPackageInfo(applicationContext!!.packageName, 0)
                    result.success(info.versionName)
                }

                "securityKey" -> result.success(baseContext.getString(R.string.api_security_key))

                "clearNotify" -> channelMethodClearAllNotifications()

                else -> result.notImplemented()
            }
        }

        // ── Contact Picker channel (multi-select, Android 17 / API 37 compliant) ──
        // EXTRA_ALLOW_MULTIPLE=true shows the checkbox UI in the system phone picker.
        // The OS grants a temporary URI permission for every selected row,
        // so no READ_CONTACTS permission is required.
        // ── Contact Picker channel (multi-select, Android 17 / API 37 compliant) ──
        // EXTRA_ALLOW_MULTIPLE=true shows the checkbox UI in the system phone picker.
        // EXTRA_LIMIT caps the number of checkboxes the user can tick (Android 7+);
        // once the cap is reached the picker closes automatically on supported ROMs.
        // The OS grants a temporary URI permission for every selected row,
        // so no READ_CONTACTS permission is required.
        MethodChannel(flutterEngine.dartExecutor, CONTACT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSdkVersion" -> result.success(Build.VERSION.SDK_INT)
                "triggerLocationButton" -> {
                    pendingResult = result
                    setupLocationButton()
                }
                "pickContacts" -> {
                    if (contactPickerResult != null || singleContactPickerResult != null) {
                        result.error("ALREADY_ACTIVE", "A contact picker is already open", null)
                        return@setMethodCallHandler
                    }
                    val maxCount = (call.argument<Int>("maxCount") ?: 5).coerceAtLeast(1)
                    contactPickerResult = result
                    contactPickerMaxCount = maxCount
                    val extraLimit = "android.provider.extra.LIMIT"

                    val intent = Intent(
                        Intent.ACTION_PICK,
                        ContactsContract.CommonDataKinds.Phone.CONTENT_URI
                    ).apply {
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                        putExtra(extraLimit, maxCount)
                    }
                    startActivityForResult(intent, CONTACT_PICKER_REQUEST)
                }
                "pickSingleContact" -> {
                    if (contactPickerResult != null || singleContactPickerResult != null) {
                        result.error("ALREADY_ACTIVE", "A contact picker is already open", null)
                        return@setMethodCallHandler
                    }
                    singleContactPickerResult = result
                    val intent = Intent(
                        Intent.ACTION_PICK,
                        ContactsContract.CommonDataKinds.Phone.CONTENT_URI
                    )
                    startActivityForResult(intent, SINGLE_CONTACT_PICKER_REQUEST)
                }
                else -> result.notImplemented()
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

        // ── Zero-Tap Sign-In / Restore Credentials API Channel ──
        MethodChannel(flutterEngine.dartExecutor, "credentials_restore").setMethodCallHandler { call, result ->
            when (call.method) {
                "setRestoreCredential" -> {
                    val token = call.argument<String>("token")
                    if (token != null) {
                        saveRestoreCredential(token)
                        result.success(true)
                    } else {
                        result.error("INVALID_TOKEN", "Token was null", null)
                    }
                }
                "getRestoreCredential" -> {
                    val token = getRestoreCredential()
                    result.success(token)
                }
                "clearRestoreCredential" -> {
                    clearRestoreCredential()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

    }

    private fun saveRestoreCredential(token: String) {
        try {
            val prefs = getSharedPreferences("restore_credentials_pref", Context.MODE_PRIVATE)
            prefs.edit().putString("restored_auth_token", token).apply()
        } catch (e: Exception) {
            Log.e("RestoreCredentials", "Failed to save restore credential", e)
        }
    }

    private fun getRestoreCredential(): String? {
        return try {
            val prefs = getSharedPreferences("restore_credentials_pref", Context.MODE_PRIVATE)
            prefs.getString("restored_auth_token", null)
        } catch (e: Exception) {
            Log.e("RestoreCredentials", "Failed to get restore credential", e)
            null
        }
    }

    private fun clearRestoreCredential() {
        try {
            val prefs = getSharedPreferences("restore_credentials_pref", Context.MODE_PRIVATE)
            prefs.edit().remove("restored_auth_token").apply()
        } catch (e: Exception) {
            Log.e("RestoreCredentials", "Failed to clear restore credential", e)
        }
    }

    private fun setupLocationButton() {
        val locationRequest = CurrentLocationRequest.Builder()
            .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
            .setDurationMillis(10000)
            .setMaxUpdateAgeMillis(0)
            .build()

        fusedLocationClient.getCurrentLocation(locationRequest, null as CancellationToken?)
            .addOnSuccessListener { location: Location? ->
                if (location != null) {
                    pendingResult?.success(
                        mapOf(
                            "lat"      to location.latitude,
                            "lng"      to location.longitude,
                            "accuracy" to location.accuracy,
                        )
                    )
                } else {
                    pendingResult?.error(
                        "LOCATION_UNAVAILABLE",
                        "Location was null — GPS may be off",
                        null
                    )
                }
                pendingResult = null
            }
            .addOnFailureListener { e ->
                pendingResult?.error(
                    "LOCATION_FAILED",
                    e.message,
                    null
                )
                pendingResult = null
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
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

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

    private fun setMapKey(mapKey: String) {
        try {
            val applicationInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            applicationInfo.metaData.putString("com.google.android.geo.API_KEY", mapKey)
        } catch (e: PackageManager.NameNotFoundException) {
            e.printStackTrace()
        }
    }


    @SuppressLint("MissingPermission")
    fun getLocation(result: MethodChannel.Result) {
        val locationManager: LocationManager =
            getSystemService(Context.LOCATION_SERVICE) as LocationManager


        var provider: String = ""
        var accur: Double = 30.0
        var isHandlerRunning : Boolean  = false
        var locationupdate = true
        val criteria = Criteria()
        criteria.accuracy = Criteria.ACCURACY_FINE
        criteria.horizontalAccuracy = Criteria.ACCURACY_HIGH
        criteria.verticalAccuracy = Criteria.ACCURACY_HIGH
        criteria.powerRequirement = Criteria.POWER_HIGH
        criteria.isSpeedRequired = false
        criteria.isAltitudeRequired = false
        criteria.isCostAllowed = true
        criteria.isBearingRequired = false
        provider = locationManager.getBestProvider(criteria, true)!!

        val handler = Handler(Looper.getMainLooper())
        val myRunnable = Runnable {
            if(locationupdate) {
                accur = accur + 20
                isHandlerRunning = false
            }
        }

        if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)){

            val lastLocation = locationManager.getLastKnownLocation(provider)
            if(lastLocation !=null &&  (System.currentTimeMillis() - lastLocation!!.time) < 3000){
                if (locationupdate && lastLocation!!.accuracy <= accur ) {//
                    Toast.makeText(applicationContext, "Accuracy of knownlocation ${lastLocation?.latitude}, ${lastLocation?.longitude}: ${lastLocation.accuracy}", Toast.LENGTH_LONG).show();

                    result.success("${lastLocation?.latitude}///${lastLocation?.longitude}///${lastLocation?.bearing}///${"noUpdateApiAndPath"}")
                    if(locationlistener !=null)
                        locationManager.removeUpdates(locationlistener!!)
                    handler.removeCallbacksAndMessages(null)
                    locationlistener = null
                    locationupdate = false
                }
            }


        }
        locationManager.requestLocationUpdates(
            provider, 200,5f, object : LocationListener { //NETWORK_PROVIDER
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {
                }
                override fun onProviderDisabled(provider: String) {}
                override fun onLocationChanged(p0: Location) {
                    locationlistener = this
                    Toast.makeText(applicationContext, "Accuracy of ${p0?.latitude}, ${p0?.longitude}: ${p0.accuracy}", Toast.LENGTH_LONG).show();


                    if( p0.accuracy > accur && !isHandlerRunning){
                        handler.postDelayed(myRunnable, 2000)
                        isHandlerRunning = true
                    }

                    if (locationupdate && p0.accuracy <= accur ) {//
                        result.success("${p0?.latitude}///${p0?.longitude}///${p0?.bearing}///${"noUpdateApiAndPath"}")
                        locationManager.removeUpdates(this)
                        handler.removeCallbacksAndMessages(null)
                        locationlistener = null
                        locationupdate = false
                    }
                }
            })

    }

    private fun EnableLocationService(result: MethodChannel.Result) {
        val activity: Activity? = this as Activity?
        activity?.let {
            val locationRequest = LocationRequest.create()
            locationRequest.priority = LocationRequest.PRIORITY_HIGH_ACCURACY

            val builder = LocationSettingsRequest.Builder()
                .addLocationRequest(locationRequest)

            val task = LocationServices.getSettingsClient(it)
                .checkLocationSettings(builder.build())

            task.addOnSuccessListener { response ->
                val states = response.locationSettingsStates
                if (states!!.isLocationPresent) {
                    result.success(true)

                }
            }
            task.addOnFailureListener { e ->
                if (e is ResolvableApiException) {
                    try {
                        e.startResolutionForResult(it, 999)
                        result.success(false)
                    } catch (sendEx: IntentSender.SendIntentException) {
                        result.success(false)
                    }
                }
            }
        }
    }

    private fun channelMethodClearAllNotifications() {
        try {
            val notificationManager : NotificationManager = context.getSystemService(
                NOTIFICATION_SERVICE
            ) as NotificationManager
            notificationManager.cancelAll()
        } catch (e: Exception) {
        }
    }

    private fun CheckLocationService(): Boolean {
        val locationManager: LocationManager =
            getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            return locationManager.isLocationEnabled()
        }

        val gps_enabled: Boolean = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val network_enabled: Boolean =
            locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)

        return gps_enabled || network_enabled
    }



    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            CONTACT_PICKER_REQUEST -> handleMultiContactResult(resultCode, data)
            SINGLE_CONTACT_PICKER_REQUEST -> handleSingleContactResult(resultCode, data)
        }
    }

    private fun handleMultiContactResult(resultCode: Int, data: Intent?) {
        val pending = contactPickerResult ?: return

        if (resultCode != Activity.RESULT_OK || data == null) {
            contactPickerResult = null
            pending.success(emptyList<Map<String, String>>())
            return
        }

        val limit = contactPickerMaxCount.coerceAtLeast(1)

        // Count selections BEFORE clearing state
        val allUris = mutableListOf<android.net.Uri>()
        val clip = data.clipData
        if (clip != null && clip.itemCount > 0) {
            for (i in 0 until clip.itemCount) {
                clip.getItemAt(i).uri?.let { allUris.add(it) }
            }
        } else {
            data.data?.let { allUris.add(it) }
        }

        // On Android 15+, LIMIT extra is ignored — enforce here
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM && allUris.size > limit) {
            // Re-launch picker with a toast explaining the limit
            android.widget.Toast.makeText(
                this,
                "Please select at most $limit contacts",
                android.widget.Toast.LENGTH_LONG
            ).show()

            // Re-launch the picker — keep contactPickerResult and contactPickerMaxCount intact
            val intent = Intent(
                Intent.ACTION_PICK,
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI
            ).apply {
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
            startActivityForResult(intent, CONTACT_PICKER_REQUEST)
            return  // Don't clear contactPickerResult — still waiting
        }

        // Clear state now that we're committing to this result
        contactPickerResult = null
        contactPickerMaxCount = 5

        try {
            val projection = arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER
            )
            val contacts = mutableListOf<Map<String, String>>()
            val limitedUris = allUris.distinct().take(limit)

            for (uri in limitedUris) {
                contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val name = cursor.getString(
                            cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                        ) ?: ""
                        val phone = cursor.getString(
                            cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)
                        ) ?: ""
                        if (phone.isNotBlank()) {
                            contacts.add(mapOf("name" to name, "phone" to phone))
                        }
                    }
                }
            }
            pending.success(contacts)
        } catch (e: Exception) {
            pending.error("READ_FAILED", e.message, null)
        }
    }

    private fun handleSingleContactResult(resultCode: Int, data: Intent?) {
        val pending = singleContactPickerResult ?: return
        singleContactPickerResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            pending.success(null)
            return
        }

        try {
            pending.success(readSingleContact(data.data))
        } catch (e: Exception) {
            pending.error("READ_FAILED", e.message, null)
        }
    }

    private fun readSingleContact(uri: android.net.Uri?): Map<String, String>? {
        if (uri == null) return null

        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )

        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val name = cursor.getString(
                    cursor.getColumnIndexOrThrow(
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME
                    )
                ) ?: ""
                val phone = cursor.getString(
                    cursor.getColumnIndexOrThrow(
                        ContactsContract.CommonDataKinds.Phone.NUMBER
                    )
                ) ?: ""

                if (phone.isNotBlank()) {
                    return mapOf("name" to name, "phone" to phone)
                }
            }
        }

        return null
    }

    override fun onTrimMemory(level: Int) {
        if (level >= ComponentCallbacks2.TRIM_MEMORY_COMPLETE && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {


            if (this::trimMemoryEvents!=null )
                trimMemoryEvents?.success(level)

        }
        super.onTrimMemory(level)

    }



}

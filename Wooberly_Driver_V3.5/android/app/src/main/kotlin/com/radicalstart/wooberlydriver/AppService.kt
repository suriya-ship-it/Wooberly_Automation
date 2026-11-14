package com.radicalstart.wooberlydriver

import android.annotation.SuppressLint
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
import android.graphics.Color
import android.location.Location
import android.os.*
import android.preference.PreferenceManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.github.nkzawa.socketio.client.IO
import com.github.nkzawa.socketio.client.Socket
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationAvailability
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.gson.Gson
import com.radicalstart.wooberlydriver.viewmodel.MainViewmodel
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.net.URISyntaxException
import java.util.*
import android.location.LocationManager


class AppService : Service(), TimerChange {

    private lateinit var notificationManager: NotificationManager
    var mainNotificationText =
        "Great! You are online and will receive a trip request. Drive more! Earn more!"
    lateinit var socket: Socket
    var bestLocation: Location? = null
    val list: MutableList<String> = ArrayList()

    // FusedLocationProviderClient replaces deprecated LocationManager
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private var locationFetchPeriod: Long = 20_000L // default 20s

    companion object {
        @SuppressLint("StaticFieldLeak")
        var instance: AppService? = null

        var declineHandler = Handler(Looper.getMainLooper())
        fun getHandler(): Handler {
            return declineHandler
        }

        var timer = Timer()
        fun getTimerValue(): Timer {
            return timer
        }

        var authTokenId = ""
        var userTokenId = ""
        var deviceTokenId = ""
        lateinit var timerChange: TimerChange
        lateinit var events: EventChannel.EventSink
        fun setEvent(events: EventChannel.EventSink) {
            this.events = events
        }

        fun startService(
            context: Context,
            authToken: String,
            userIdToken: String,
            deviceId: String
        ): Intent? {
            if (authToken.isNotEmpty()) {
                val hasLocationPermission = ContextCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_FINE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_COARSE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED

                // When the activity is running in the foreground the OS allows
                // startForegroundService() without ACCESS_BACKGROUND_LOCATION.
                // Only enforce the background-location check when we are truly
                // in the background (e.g. boot receiver, push notification).
                val hasBackgroundLocationPermission = LifecycleDetector.isActivityRunning ||
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        ContextCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }

                val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
                val isLocationEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    locationManager.isLocationEnabled
                } else {
                    locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) || locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
                }

                android.util.Log.d("AppService", "startService guard: hasLocation=$hasLocationPermission hasBgLocation=$hasBackgroundLocationPermission isLocationEnabled=$isLocationEnabled activityRunning=${LifecycleDetector.isActivityRunning}")

                if (hasLocationPermission && hasBackgroundLocationPermission && isLocationEnabled) {
                    val intent =
                        Intent(context, AppService::class.java).putExtra("authToken", authToken)
                            .putExtra("userId", userIdToken).putExtra("deviceId", deviceId)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            ContextCompat.startForegroundService(context, intent)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    } else {
                        try {
                            context.startService(intent)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    return intent
                } else {
                    android.util.Log.w("AppService", "startService blocked: hasLocation=$hasLocationPermission hasBgLocation=$hasBackgroundLocationPermission isLocationEnabled=$isLocationEnabled")
                }
            }
            return null
        }

        fun stopLocationUpdates() {
            try {
                instance?.stopLocationUpdates()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun stopService(context: Context) {
            try {
                timer.cancel()
                instance?.stopLocationUpdates()
            } catch (e: Exception) {
                e.printStackTrace()
            }
            timer = Timer()
            declineHandler.removeCallbacksAndMessages(null)
            val intent = Intent(context, AppService::class.java)
            context.stopService(intent)
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
    }


    override fun onCreate() {
        super.onCreate()
        instance = this
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        android.util.Log.e("TAG", "appserviceonCreate: " )

        // ① Register the notification channel – required on API 26+.
        //    Without this the channel "driverappmsgs" is unknown to the system
        //    and every posted notification is silently dropped.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                "driverappmsgs",
                "Driver Location Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Keeps the driver online and tracks location in the background"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Initialise FusedLocationProviderClient
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)

        val notificationBuilder = NotificationCompat.Builder(this, "driverappmsgs")
            .setContentText(mainNotificationText)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(mainNotificationText)
            )
            .setColor(Color.BLACK)
            .build()

        // ② Always call startForeground() here.
        //    The companion startService() already guards against missing permissions
        //    before delivering the Intent, so re-checking here only causes the
        //    service to kill itself on cold start when hardware state hasn't settled.
        //    Use a fixed ID (1) so repeated restarts update the existing notification
        //    in place instead of leaking orphaned entries in the status bar.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                startForeground((System.currentTimeMillis() % 10000).toInt(), notificationBuilder, FOREGROUND_SERVICE_TYPE_LOCATION)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        } else {
            try {
                startForeground((System.currentTimeMillis() % 10000).toInt(), notificationBuilder)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }


    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this
        try {
            timerChange = this
            authTokenId = intent?.getStringExtra("authToken")!!
            userTokenId = intent.getStringExtra("userId")!!
            deviceTokenId = intent.getStringExtra("deviceId")!!
            android.util.Log.e("TAG", "onStartCommand: "+userTokenId )
            android.util.Log.e("TAG", "onStartCommand: authTokenId "+authTokenId )
            android.util.Log.e("TAG", "onStartCommand: deviceTokenId "+deviceTokenId )
            try {
                val opts = IO.Options()
                socket = IO.socket(socketUrl, opts)
            } catch (e: URISyntaxException) {
                e.printStackTrace()
            }
            startService()
            android.util.Log.e("TAG", "onStartCommand: "+userTokenId )

            if (socket != null) {
                socket.connect()
                socket.off("cancelTripRequest-${userTokenId}")
                socket.on("cancelTripRequest-${userTokenId}") { _ ->
                    if (!LifecycleDetector.isActivityRunning) {
                        getHandler().removeCallbacksAndMessages(null)
                    }
                }

                socket.off("tripRequest-${userTokenId}")
                socket.on("tripRequest-${userTokenId}") { args ->
                    if (!LifecycleDetector.isActivityRunning) {
                        try {
                            val jsonObject = JSONObject(args[0].toString())
                            val content = jsonObject.getJSONObject("data").getJSONObject("data")
                            val list = listOf<String>(
                                "{\"requestStatus\" : \"decline\",\"data\" : { \"bookingId\" : ${
                                    content.getString("bookingId")
                                },\"auth\" : \"${authTokenId}\",\"userId\" : \"${userTokenId}\",\"riderId\" : \"${
                                    content.getString("riderId")
                                }\" } }"
                            )

                            val gson = Gson().toJson(list[0])
                            val s = gson.replace("\\", "")

                            emitE(socket, s.substring(1, s.length - 1))
                            android.util.Log.e("TAG", "canceltrip: "+s )
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                }
                socket.off("riderCancel-${userTokenId}")
                socket.on("riderCancel-${userTokenId}") { _ ->
                    if (!LifecycleDetector.isActivityRunning) {
                        try {
                            val prefs: SharedPreferences =
                                PreferenceManager.getDefaultSharedPreferences(this)
                            val editor = prefs.edit()
                            editor.putString("riderid", "")
                            editor.putString("bookingId", "")
                            editor.apply()
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                }

                socket.off("loginCheck-${userTokenId}")
                socket.on("loginCheck-${userTokenId}") { args ->
                    try {
                        val jsonObject = JSONObject(args[0].toString())
                        val content = jsonObject.getJSONObject("data").getJSONObject("data")

                        if (content.getString("deviceId") != deviceTokenId) {
                            try {
                                timer.cancel()
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                            timer = Timer()
                            declineHandler.removeCallbacksAndMessages(null)
                            stopSelf()
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("TAG", "onStartCommand: "+e )
            try {
                timer.cancel()
            } catch (e: Exception) {
                e.printStackTrace()
            }
            timer = Timer()
            declineHandler.removeCallbacksAndMessages(null)
            stopSelf()
            e.printStackTrace()
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    fun startService() {
        startFusedLocationUpdates()
    }

    /**
     * Starts background location updates using FusedLocationProviderClient.
     *
     * This replaces the old LocationManager + Timer approach.
     * - Uses [Priority.PRIORITY_HIGH_ACCURACY] for GPS-grade accuracy.
     * - interval / minUpdateInterval derived from the user-configured
     *   [locationFetchTime] preference (seconds).
     * - Works correctly on Android 14+ (API 34) and Android 17 (API 37)
     *   where [LocationManager.GPS_PROVIDER] listener registration is
     *   increasingly restricted in background contexts.
     */
    @SuppressLint("MissingPermission")
    private fun startFusedLocationUpdates() {
        // Stop any previous updates/timer first
        stopLocationUpdates()

        val prefs: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
        val fetchSeconds = prefs.getInt("locationFetchTime", 20).toLong()
        locationFetchPeriod = fetchSeconds * 1000L
        Log.w("AppService", "locationFetchPeriod: "+locationFetchPeriod)

        // Build a LocationRequest using the modern Builder API (required for API 31+)
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            locationFetchPeriod
        )
            .setMinUpdateIntervalMillis(locationFetchPeriod)
            .setWaitForAccurateLocation(false) // don't block for perfect accuracy
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                val loc = result.lastLocation ?: return
                bestLocation = loc
                val livelocation = "${loc.latitude}&&&${loc.longitude}"
                if (livelocation !in list) list.add(livelocation)
                dispatchLocation(loc)
            }

            override fun onLocationAvailability(availability: LocationAvailability) {
                // If location is unavailable (e.g. GPS off) log it but don't crash
                if (!availability.isLocationAvailable) {
                    Log.w("AppService", "Location not currently available")
                }
            }
        }

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
    }

    private fun dispatchLocation(loc: Location) {
        // Keep socket alive
        try {
            if (!socket.connected()) socket.connect()
        } catch (e: Exception) {
            Log.d("socket", "Socket reconnect error: $e")
        }

        if (LifecycleDetector.isActivityRunning) {
            val uiHandler = Handler(Looper.getMainLooper())
            uiHandler.post {
                try {
                    events.success(
                        "${loc.latitude}///${loc.longitude}///${loc.bearing}///noUpdateApiAndPath///$list"
                    )
                    list.clear()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        } else {
            val prefs: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
            MainViewmodel().upload(
                loc.latitude,
                loc.longitude,
                prefs.getString("riderid", "")!!,
                deviceTokenId,
                prefs.getString("bookingId", "")!!
            )
        }
    }

    fun stopLocationUpdates() {
        try {
            if (::fusedLocationClient.isInitialized && ::locationCallback.isInitialized) {
                fusedLocationClient.removeLocationUpdates(locationCallback)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        try {
            timer.cancel()
        } catch (_: Exception) {}
        timer = Timer()
    }

    fun emitE(socket: Socket, arg: String) {
        val prefs: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
        getHandler().postDelayed({
            if (!LifecycleDetector.isActivityRunning) {
                if (socket.connected()) {
                    socket.emit("tripDecline", arg)
                }
            }
        }, prefs.getInt("requestTime", 20000).toLong())
        socket.off("cancelTripRequest-${userTokenId}")
        socket.on("cancelTripRequest-${userTokenId}") { _ ->
            getHandler().removeCallbacksAndMessages(null)
        }
    }

    override fun onDestroy() {
        stopLocationUpdates()
        declineHandler.removeCallbacksAndMessages(null)
        try {
            if (::socket.isInitialized && socket.connected()) {
                socket.disconnect()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        } else {
            @Suppress("DEPRECATION")
            try {
                stopForeground(true)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        if (instance == this) {
            instance = null
        }
        super.onDestroy()
    }

    override fun timerChange() {
        // Re-start location updates with fresh prefs (e.g. after interval change)
        startFusedLocationUpdates()
    }
}

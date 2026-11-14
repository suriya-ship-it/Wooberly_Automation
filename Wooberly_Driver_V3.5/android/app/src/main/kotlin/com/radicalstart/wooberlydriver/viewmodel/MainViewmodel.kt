package com.radicalstart.wooberlydriver.viewmodel

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.apollographql.apollo.api.Optional
import com.apollographql.apollo.network.okHttpClient
import com.apollographql.apollo.ApolloClient
import com.apollographql.apollo.network.okHttpClient
import com.github.nkzawa.socketio.client.IO
import com.github.nkzawa.socketio.client.Socket
import com.google.gson.Gson
import com.radicalstart.wooberlydriver.*

import com.radicalstart.wooberlydriver.api.Authorize
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import org.json.JSONObject
import java.net.URISyntaxException
import java.lang.Math.*

class MainViewmodel :ViewModel(){


    var rotationbearing:Double?=null
    var socket: Socket? = null


    fun upload(lat:Double, lan:Double,riderid: String,deviceid: String,bookingid: String  ) {
        viewModelScope.launch {
            try {
                val intercept= Authorize()
                intercept.auth = auth
                val api= ApolloClient.Builder().serverUrl(url).okHttpClient(OkHttpClient.Builder().addInterceptor(intercept).build()).build()
                bearingBetween(latitude  ,longitude, lat,lan)
                Log.d("response", "location update deviceid------ "+ rotationbearing+"latitude: "+latitude+"longitude: "+longitude )

                val response = api.query(SendDriverLocationQuery(
                    lat,
                    lan,
                    Optional.presentIfNotNull(riderid)
                    ,Optional.presentIfNotNull(deviceid)
                    ,Optional.presentIfNotNull(rotationbearing)
                    ,Optional.presentIfNotNull(if (bookingid.isEmpty()) null else bookingid.toInt())
                )).execute()
                Log.d("response", "location update success -----"+response.data.toString())
                latitude = lat.toString()
                longitude = lan.toString()
                val responseStatus = response.data!!
                Log.d("loc", "location update success -----"+responseStatus.toString())

                if(responseStatus.sendDriverLocation !=null && responseStatus.sendDriverLocation.status != 200) {
                    try {
                        val opts = IO.Options()
                        socket = IO.socket(socketUrl, opts)
                    } catch (e: URISyntaxException) {
                        e.printStackTrace()
                    }
                    socket?.off("tripRequest-${AppService.userTokenId}")
                }

            }catch (e :Exception){
                e.printStackTrace()
            }
        }
    }

    fun bearingBetween(startLat: String?, startLong: String?,
                       endLatitude: Double, endLongitude: Double) {
        var startLatitude : Double
        if(startLat == null)
            startLatitude  = endLatitude
        else
            startLatitude = startLat.toDouble()

        var startLongitude : Double
        if(startLong == null)
            startLongitude  = endLatitude
        else
            startLongitude = startLong.toDouble()


        val dLon: Double = endLongitude - startLongitude

        val y = sin(dLon) * cos(endLatitude)
        val x = cos(startLatitude) * sin(endLatitude) - (sin(startLatitude)
                * cos(endLatitude) * cos(dLon))

        var brng = atan2(y, x)

        brng = toDegrees(brng)
        brng = (brng + 360) % 360
        rotationbearing = 360 - brng // count degrees counter-clockwise - remove to make clockwise



    }


}
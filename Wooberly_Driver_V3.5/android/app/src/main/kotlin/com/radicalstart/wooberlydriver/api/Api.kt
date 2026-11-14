package com.radicalstart.wooberlydriver.api

import com.apollographql.apollo.ApolloClient
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Response

class Authorize : Interceptor {

    var auth = ""
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request().newBuilder().addHeader("auth", auth).build()
        return chain.proceed(request)
    }

}
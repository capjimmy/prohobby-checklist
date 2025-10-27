package com.prohobby.checklist.data.api

import android.util.Log
import com.prohobby.checklist.utils.PreferenceManager
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object RetrofitClient {
    private const val BASE_URL = "https://prohobby-checklist-production.up.railway.app/" // Railway 서버

    private var preferenceManager: PreferenceManager? = null

    fun init(prefManager: PreferenceManager) {
        preferenceManager = prefManager
        Log.d("RetrofitClient", "초기화 완료, BASE_URL: $BASE_URL")
    }

    private val authInterceptor = Interceptor { chain ->
        val token = preferenceManager?.getToken()
        val request = chain.request().newBuilder()
        if (!token.isNullOrEmpty()) {
            Log.d("RetrofitClient", "토큰 추가: Bearer $token")
            request.addHeader("Authorization", "Bearer $token")
        } else {
            Log.d("RetrofitClient", "토큰 없음, Authorization 헤더 생략")
        }
        val finalRequest = request.build()
        Log.d("RetrofitClient", "요청 URL: ${finalRequest.url}")
        Log.d("RetrofitClient", "요청 Method: ${finalRequest.method}")
        val response = chain.proceed(finalRequest)
        Log.d("RetrofitClient", "응답 코드: ${response.code}")
        response
    }

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(authInterceptor)
        .addInterceptor(loggingInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    val apiService: ApiService = retrofit.create(ApiService::class.java)
}

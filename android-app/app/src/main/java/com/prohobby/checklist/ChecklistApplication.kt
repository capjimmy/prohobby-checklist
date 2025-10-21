package com.prohobby.checklist

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.prohobby.checklist.data.api.RetrofitClient
import com.prohobby.checklist.utils.PreferenceManager

class ChecklistApplication : Application() {

    lateinit var preferenceManager: PreferenceManager

    companion object {
        const val CHANNEL_ID = "checklist_notifications"
        const val CHANNEL_NAME = "작업 알림"
    }

    override fun onCreate() {
        super.onCreate()

        preferenceManager = PreferenceManager(this)
        RetrofitClient.init(preferenceManager)

        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "작업 관련 알림을 받습니다"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}

package com.prohobby.checklist.utils

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.prohobby.checklist.data.model.User

class PreferenceManager(context: Context) {
    private val sharedPreferences: SharedPreferences =
        context.getSharedPreferences("checklist_prefs", Context.MODE_PRIVATE)
    private val gson = Gson()

    companion object {
        private const val KEY_TOKEN = "token"
        private const val KEY_USER = "user"
        private const val KEY_SERVER_URL = "server_url"
    }

    fun saveToken(token: String) {
        sharedPreferences.edit().putString(KEY_TOKEN, token).apply()
    }

    fun getToken(): String? {
        return sharedPreferences.getString(KEY_TOKEN, null)
    }

    fun saveUser(user: User) {
        val userJson = gson.toJson(user)
        sharedPreferences.edit().putString(KEY_USER, userJson).apply()
    }

    fun getUser(): User? {
        val userJson = sharedPreferences.getString(KEY_USER, null)
        return if (userJson != null) {
            gson.fromJson(userJson, User::class.java)
        } else null
    }

    fun saveServerUrl(url: String) {
        sharedPreferences.edit().putString(KEY_SERVER_URL, url).apply()
    }

    fun getServerUrl(): String {
        return sharedPreferences.getString(KEY_SERVER_URL, "http://10.0.2.2:5000") ?: "http://10.0.2.2:5000"
    }

    fun clearAll() {
        sharedPreferences.edit().clear().apply()
    }
}

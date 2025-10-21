package com.prohobby.checklist.data.repository

import com.prohobby.checklist.data.api.RetrofitClient
import com.prohobby.checklist.data.model.LoginRequest
import com.prohobby.checklist.data.model.LoginResponse
import com.prohobby.checklist.data.model.RegisterRequest
import com.prohobby.checklist.data.model.RegisterResponse
import com.prohobby.checklist.utils.PreferenceManager
import retrofit2.Response

class AuthRepository(private val preferenceManager: PreferenceManager) {

    suspend fun login(phone: String, password: String): Response<LoginResponse> {
        val response = RetrofitClient.apiService.login(LoginRequest(phone, password))
        if (response.isSuccessful) {
            response.body()?.let {
                preferenceManager.saveToken(it.token)
                preferenceManager.saveUser(it.user)
            }
        }
        return response
    }

    suspend fun register(
        name: String,
        phone: String,
        birthdate: String,
        password: String
    ): Response<RegisterResponse> {
        return RetrofitClient.apiService.register(
            RegisterRequest(name, phone, birthdate, password)
        )
    }

    fun logout() {
        preferenceManager.clearAll()
    }

    fun isLoggedIn(): Boolean {
        return !preferenceManager.getToken().isNullOrEmpty()
    }
}

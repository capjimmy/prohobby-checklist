package com.prohobby.checklist.data.repository

import android.util.Log
import com.prohobby.checklist.data.api.RetrofitClient
import com.prohobby.checklist.data.model.LoginRequest
import com.prohobby.checklist.data.model.LoginResponse
import com.prohobby.checklist.data.model.RegisterRequest
import com.prohobby.checklist.data.model.RegisterResponse
import com.prohobby.checklist.utils.PreferenceManager
import retrofit2.Response

class AuthRepository(private val preferenceManager: PreferenceManager) {

    suspend fun login(phone: String, password: String): Response<LoginResponse> {
        Log.d("AuthRepository", "=== 로그인 API 호출 시작 ===")
        Log.d("AuthRepository", "요청: phone=$phone")
        val request = LoginRequest(phone, password)
        Log.d("AuthRepository", "Request 객체 생성 완료")

        val response = RetrofitClient.apiService.login(request)
        Log.d("AuthRepository", "응답 받음: code=${response.code()}, success=${response.isSuccessful}")

        if (response.isSuccessful) {
            response.body()?.let {
                Log.d("AuthRepository", "로그인 성공, 토큰 저장 중...")
                preferenceManager.saveToken(it.token)
                preferenceManager.saveUser(it.user)
                Log.d("AuthRepository", "토큰 저장 완료")
            }
        } else {
            Log.e("AuthRepository", "로그인 실패: ${response.errorBody()?.string()}")
        }
        return response
    }

    suspend fun register(
        name: String,
        phone: String,
        birthdate: String,
        password: String
    ): Response<RegisterResponse> {
        Log.d("AuthRepository", "=== 회원가입 API 호출 시작 ===")
        Log.d("AuthRepository", "요청 데이터: name=$name, phone=$phone, birthdate=$birthdate")

        val request = RegisterRequest(name, phone, birthdate, password)
        Log.d("AuthRepository", "Request 객체: $request")

        val response = RetrofitClient.apiService.register(request)
        Log.d("AuthRepository", "응답 받음: code=${response.code()}, success=${response.isSuccessful}")

        if (!response.isSuccessful) {
            val errorBody = response.errorBody()?.string()
            Log.e("AuthRepository", "회원가입 실패 응답: $errorBody")
        } else {
            Log.d("AuthRepository", "회원가입 성공!")
        }

        return response
    }

    fun logout() {
        preferenceManager.clearAll()
    }

    fun isLoggedIn(): Boolean {
        return !preferenceManager.getToken().isNullOrEmpty()
    }
}

package com.prohobby.checklist.ui.auth

import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.prohobby.checklist.data.repository.AuthRepository
import kotlinx.coroutines.launch

class RegisterViewModel(private val authRepository: AuthRepository) : ViewModel() {

    private val _registerResult = MutableLiveData<Result<String>>()
    val registerResult: LiveData<Result<String>> = _registerResult

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    fun register(name: String, phone: String, birthdate: String, password: String, confirmPassword: String) {
        Log.d("RegisterViewModel", "=== 회원가입 시작 ===")
        Log.d("RegisterViewModel", "입력값: name=$name, phone=$phone, birthdate=$birthdate")

        if (name.isBlank() || phone.isBlank() || birthdate.isBlank() || password.isBlank()) {
            Log.e("RegisterViewModel", "입력값 검증 실패: 필수 필드 누락")
            _registerResult.value = Result.failure(Exception("모든 필드를 입력해주세요"))
            return
        }

        if (password != confirmPassword) {
            Log.e("RegisterViewModel", "입력값 검증 실패: 비밀번호 불일치")
            _registerResult.value = Result.failure(Exception("비밀번호가 일치하지 않습니다"))
            return
        }

        if (password.length < 4) {
            Log.e("RegisterViewModel", "입력값 검증 실패: 비밀번호 길이")
            _registerResult.value = Result.failure(Exception("비밀번호는 최소 4자 이상이어야 합니다"))
            return
        }

        viewModelScope.launch {
            try {
                _isLoading.value = true
                Log.d("RegisterViewModel", "서버 요청 시작...")
                val response = authRepository.register(name, phone, birthdate, password)
                Log.d("RegisterViewModel", "서버 응답 받음: code=${response.code()}, isSuccessful=${response.isSuccessful}")

                if (response.isSuccessful) {
                    Log.d("RegisterViewModel", "회원가입 성공!")
                    _registerResult.value = Result.success("회원가입 성공")
                } else {
                    val errorBody = response.errorBody()?.string()
                    Log.e("RegisterViewModel", "회원가입 실패: code=${response.code()}, message=${response.message()}, errorBody=$errorBody")
                    val errorMsg = when (response.code()) {
                        400 -> "이미 등록된 전화번호입니다"
                        else -> "회원가입 실패: ${response.message()}"
                    }
                    _registerResult.value = Result.failure(Exception(errorMsg))
                }
            } catch (e: Exception) {
                Log.e("RegisterViewModel", "네트워크 예외 발생", e)
                Log.e("RegisterViewModel", "예외 메시지: ${e.message}")
                Log.e("RegisterViewModel", "예외 타입: ${e.javaClass.name}")
                _registerResult.value = Result.failure(Exception("네트워크 오류: ${e.message}"))
            } finally {
                _isLoading.value = false
                Log.d("RegisterViewModel", "=== 회원가입 종료 ===")
            }
        }
    }
}

package com.prohobby.checklist.ui.auth

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
        if (name.isBlank() || phone.isBlank() || birthdate.isBlank() || password.isBlank()) {
            _registerResult.value = Result.failure(Exception("모든 필드를 입력해주세요"))
            return
        }

        if (password != confirmPassword) {
            _registerResult.value = Result.failure(Exception("비밀번호가 일치하지 않습니다"))
            return
        }

        if (password.length < 4) {
            _registerResult.value = Result.failure(Exception("비밀번호는 최소 4자 이상이어야 합니다"))
            return
        }

        viewModelScope.launch {
            try {
                _isLoading.value = true
                val response = authRepository.register(name, phone, birthdate, password)
                if (response.isSuccessful) {
                    _registerResult.value = Result.success("회원가입 성공")
                } else {
                    val errorMsg = when (response.code()) {
                        400 -> "이미 등록된 전화번호입니다"
                        else -> "회원가입 실패: ${response.message()}"
                    }
                    _registerResult.value = Result.failure(Exception(errorMsg))
                }
            } catch (e: Exception) {
                _registerResult.value = Result.failure(Exception("네트워크 오류: ${e.message}"))
            } finally {
                _isLoading.value = false
            }
        }
    }
}

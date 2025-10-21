package com.prohobby.checklist.ui.auth

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.prohobby.checklist.data.repository.AuthRepository
import kotlinx.coroutines.launch

class LoginViewModel(private val authRepository: AuthRepository) : ViewModel() {

    private val _loginResult = MutableLiveData<Result<String>>()
    val loginResult: LiveData<Result<String>> = _loginResult

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    fun login(phone: String, password: String) {
        if (phone.isBlank() || password.isBlank()) {
            _loginResult.value = Result.failure(Exception("전화번호와 비밀번호를 입력해주세요"))
            return
        }

        viewModelScope.launch {
            try {
                _isLoading.value = true
                val response = authRepository.login(phone, password)
                if (response.isSuccessful) {
                    _loginResult.value = Result.success("로그인 성공")
                } else {
                    val errorMsg = when (response.code()) {
                        401 -> "전화번호 또는 비밀번호가 잘못되었습니다"
                        else -> "로그인 실패: ${response.message()}"
                    }
                    _loginResult.value = Result.failure(Exception(errorMsg))
                }
            } catch (e: Exception) {
                _loginResult.value = Result.failure(Exception("네트워크 오류: ${e.message}"))
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun isLoggedIn(): Boolean {
        return authRepository.isLoggedIn()
    }
}

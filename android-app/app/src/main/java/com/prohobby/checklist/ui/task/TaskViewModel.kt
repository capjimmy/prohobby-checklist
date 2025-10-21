package com.prohobby.checklist.ui.task

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.prohobby.checklist.data.model.Task
import com.prohobby.checklist.data.model.User
import com.prohobby.checklist.data.repository.TaskRepository
import kotlinx.coroutines.launch

class TaskViewModel(private val taskRepository: TaskRepository) : ViewModel() {

    private val _tasks = MutableLiveData<List<Task>>()
    val tasks: LiveData<List<Task>> = _tasks

    private val _users = MutableLiveData<List<User>>()
    val users: LiveData<List<User>> = _users

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String>()
    val error: LiveData<String> = _error

    private val _actionResult = MutableLiveData<String>()
    val actionResult: LiveData<String> = _actionResult

    fun loadTasks(status: String? = null) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                val response = taskRepository.getTasks(status)
                if (response.isSuccessful) {
                    _tasks.value = response.body() ?: emptyList()
                } else {
                    _error.value = "작업 목록을 불러올 수 없습니다"
                }
            } catch (e: Exception) {
                _error.value = "네트워크 오류: ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadUsers() {
        viewModelScope.launch {
            try {
                val response = taskRepository.getUsers()
                if (response.isSuccessful) {
                    _users.value = response.body() ?: emptyList()
                }
            } catch (e: Exception) {
                _error.value = "사용자 목록을 불러올 수 없습니다"
            }
        }
    }

    fun createTask(
        title: String,
        description: String?,
        priority: String,
        deadlineDate: String,
        workerIds: List<Int>
    ) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                val response = taskRepository.createTask(title, description, priority, deadlineDate, workerIds)
                if (response.isSuccessful) {
                    _actionResult.value = "작업이 생성되었습니다"
                    loadTasks()
                } else {
                    _error.value = "작업 생성 실패"
                }
            } catch (e: Exception) {
                _error.value = "네트워크 오류: ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun completeTask(taskId: Int) {
        viewModelScope.launch {
            try {
                val response = taskRepository.completeTask(taskId)
                if (response.isSuccessful) {
                    _actionResult.value = "작업이 완료되었습니다"
                    loadTasks()
                } else {
                    _error.value = "작업 완료 처리 실패"
                }
            } catch (e: Exception) {
                _error.value = "네트워크 오류: ${e.message}"
            }
        }
    }

    fun deleteTask(taskId: Int) {
        viewModelScope.launch {
            try {
                val response = taskRepository.deleteTask(taskId)
                if (response.isSuccessful) {
                    _actionResult.value = "작업이 삭제되었습니다"
                    loadTasks()
                } else {
                    _error.value = "작업 삭제 실패"
                }
            } catch (e: Exception) {
                _error.value = "네트워크 오류: ${e.message}"
            }
        }
    }

    fun nudgeTask(taskId: Int) {
        viewModelScope.launch {
            try {
                val response = taskRepository.nudgeTask(taskId)
                if (response.isSuccessful) {
                    _actionResult.value = "독촉 알림을 보냈습니다"
                } else {
                    _error.value = "독촉 알림 전송 실패"
                }
            } catch (e: Exception) {
                _error.value = "네트워크 오류: ${e.message}"
            }
        }
    }
}

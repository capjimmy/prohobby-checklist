package com.prohobby.checklist.data.repository

import com.prohobby.checklist.data.api.RetrofitClient
import com.prohobby.checklist.data.model.*
import retrofit2.Response

class TaskRepository {

    suspend fun getTasks(status: String? = null): Response<List<Task>> {
        return RetrofitClient.apiService.getTasks(status)
    }

    suspend fun getTask(id: Int): Response<Task> {
        return RetrofitClient.apiService.getTask(id)
    }

    suspend fun createTask(
        title: String,
        description: String?,
        priority: String,
        deadlineDate: String,
        workerIds: List<Int>
    ): Response<TaskResponse> {
        return RetrofitClient.apiService.createTask(
            CreateTaskRequest(title, description, priority, deadlineDate, workerIds)
        )
    }

    suspend fun updateTask(
        id: Int,
        title: String,
        description: String?,
        priority: String,
        deadlineDate: String,
        status: String,
        workerIds: List<Int>
    ): Response<TaskResponse> {
        return RetrofitClient.apiService.updateTask(
            id,
            UpdateTaskRequest(title, description, priority, deadlineDate, status, workerIds)
        )
    }

    suspend fun completeTask(id: Int): Response<TaskResponse> {
        return RetrofitClient.apiService.completeTask(id)
    }

    suspend fun deleteTask(id: Int): Response<TaskResponse> {
        return RetrofitClient.apiService.deleteTask(id)
    }

    suspend fun nudgeTask(id: Int): Response<TaskResponse> {
        return RetrofitClient.apiService.nudgeTask(id)
    }

    suspend fun getUsers(): Response<List<User>> {
        return RetrofitClient.apiService.getUsers()
    }

    suspend fun getNotifications(): Response<List<Notification>> {
        return RetrofitClient.apiService.getNotifications()
    }

    suspend fun markNotificationRead(id: Int): Response<TaskResponse> {
        return RetrofitClient.apiService.markNotificationRead(id)
    }
}

package com.prohobby.checklist.data.api

import com.prohobby.checklist.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    // 인증
    @POST("api/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("api/register")
    suspend fun register(@Body request: RegisterRequest): Response<RegisterResponse>

    // 사용자
    @GET("api/users")
    suspend fun getUsers(): Response<List<User>>

    @GET("api/users/{id}")
    suspend fun getUser(@Path("id") id: Int): Response<User>

    // 작업
    @GET("api/tasks")
    suspend fun getTasks(@Query("status") status: String? = null): Response<List<Task>>

    @GET("api/tasks/{id}")
    suspend fun getTask(@Path("id") id: Int): Response<Task>

    @POST("api/tasks")
    suspend fun createTask(@Body request: CreateTaskRequest): Response<TaskResponse>

    @PUT("api/tasks/{id}")
    suspend fun updateTask(@Path("id") id: Int, @Body request: UpdateTaskRequest): Response<TaskResponse>

    @PUT("api/tasks/{id}/complete")
    suspend fun completeTask(@Path("id") id: Int): Response<TaskResponse>

    @DELETE("api/tasks/{id}")
    suspend fun deleteTask(@Path("id") id: Int): Response<TaskResponse>

    // 알림
    @GET("api/notifications")
    suspend fun getNotifications(): Response<List<Notification>>

    @PUT("api/notifications/{id}/read")
    suspend fun markNotificationRead(@Path("id") id: Int): Response<TaskResponse>

    // 독촉
    @POST("api/tasks/{id}/nudge")
    suspend fun nudgeTask(@Path("id") id: Int): Response<TaskResponse>
}

package com.prohobby.checklist.data.api

import com.prohobby.checklist.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    @POST("api/register")
    suspend fun register(@Body request: RegisterRequest): Response<Map<String, Any>>

    @POST("api/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @GET("api/users")
    suspend fun getUsers(@Header("Authorization") token: String): Response<List<User>>

    @GET("api/tasks")
    suspend fun getTasks(@Header("Authorization") token: String): Response<List<Task>>

    @POST("api/tasks")
    suspend fun createTask(
        @Header("Authorization") token: String,
        @Body request: CreateTaskRequest
    ): Response<Task>

    @PUT("api/tasks/{id}")
    suspend fun updateTask(
        @Header("Authorization") token: String,
        @Path("id") taskId: Int,
        @Body task: Task
    ): Response<Task>

    @DELETE("api/tasks/{id}")
    suspend fun deleteTask(
        @Header("Authorization") token: String,
        @Path("id") taskId: Int
    ): Response<Map<String, String>>

    @POST("api/tasks/{id}/nudge")
    suspend fun nudgeTask(
        @Header("Authorization") token: String,
        @Path("id") taskId: Int
    ): Response<Map<String, String>>
}

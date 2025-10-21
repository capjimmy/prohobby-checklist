package com.prohobby.checklist.data.model

import com.google.gson.annotations.SerializedName

data class User(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("name") val name: String,
    @SerializedName("phone") val phone: String,
    @SerializedName("birthdate") val birthdate: String,
    @SerializedName("password") val password: String? = null,
    @SerializedName("is_admin") val isAdmin: Int = 0
)

data class LoginRequest(
    val phone: String,
    val password: String
)

data class LoginResponse(
    val token: String,
    val user: User
)

data class RegisterRequest(
    val name: String,
    val phone: String,
    val birthdate: String,
    val password: String
)

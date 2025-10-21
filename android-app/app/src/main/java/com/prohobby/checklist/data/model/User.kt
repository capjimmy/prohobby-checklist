package com.prohobby.checklist.data.model

import com.google.gson.annotations.SerializedName

data class User(
    val id: Int,
    val name: String,
    val phone: String,
    val birthdate: String,
    @SerializedName("is_admin")
    val isAdmin: Int = 0
)

data class LoginRequest(
    val phone: String,
    val password: String
)

data class RegisterRequest(
    val name: String,
    val phone: String,
    val birthdate: String,
    val password: String
)

data class LoginResponse(
    val token: String,
    val user: User
)

data class RegisterResponse(
    val message: String,
    val userId: Int
)

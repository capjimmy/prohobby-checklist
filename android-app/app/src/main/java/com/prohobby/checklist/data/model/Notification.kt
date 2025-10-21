package com.prohobby.checklist.data.model

import com.google.gson.annotations.SerializedName

data class Notification(
    val id: Int,
    @SerializedName("user_id")
    val userId: Int,
    @SerializedName("task_id")
    val taskId: Int,
    val type: String, // task_assigned, task_completed, nudge, deadline
    val message: String,
    @SerializedName("is_read")
    val isRead: Int,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("task_title")
    val taskTitle: String?
)

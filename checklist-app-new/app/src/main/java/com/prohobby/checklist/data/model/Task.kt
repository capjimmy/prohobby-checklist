package com.prohobby.checklist.data.model

import com.google.gson.annotations.SerializedName

data class Task(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String?,
    @SerializedName("priority") val priority: String, // "high", "medium", "low"
    @SerializedName("deadline") val deadline: String?,
    @SerializedName("status") val status: String = "pending", // "pending", "in_progress", "completed"
    @SerializedName("created_by") val createdBy: Int,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("workers") val workers: List<User>? = null
)

data class TaskWorker(
    @SerializedName("task_id") val taskId: Int,
    @SerializedName("user_id") val userId: Int
)

data class CreateTaskRequest(
    val title: String,
    val description: String?,
    val priority: String,
    val deadline: String?,
    val workerIds: List<Int>
)

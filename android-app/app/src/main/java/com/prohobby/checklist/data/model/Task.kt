package com.prohobby.checklist.data.model

import com.google.gson.annotations.SerializedName

data class Task(
    val id: Int,
    val title: String,
    val description: String?,
    val priority: String, // high, medium, low
    val status: String, // in_progress, completed
    @SerializedName("creator_id")
    val creatorId: Int,
    @SerializedName("completer_id")
    val completerId: Int?,
    @SerializedName("created_date")
    val createdDate: String,
    @SerializedName("deadline_date")
    val deadlineDate: String,
    @SerializedName("completed_date")
    val completedDate: String?,
    @SerializedName("creator_name")
    val creatorName: String?,
    @SerializedName("completer_name")
    val completerName: String?,
    val workers: List<User>
)

data class CreateTaskRequest(
    val title: String,
    val description: String?,
    val priority: String,
    @SerializedName("deadline_date")
    val deadlineDate: String,
    @SerializedName("worker_ids")
    val workerIds: List<Int>
)

data class UpdateTaskRequest(
    val title: String,
    val description: String?,
    val priority: String,
    @SerializedName("deadline_date")
    val deadlineDate: String,
    val status: String,
    @SerializedName("worker_ids")
    val workerIds: List<Int>
)

data class TaskResponse(
    val message: String,
    val taskId: Int? = null
)

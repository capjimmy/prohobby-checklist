package com.prohobby.checklist.worker

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.prohobby.checklist.ChecklistApplication
import com.prohobby.checklist.R
import com.prohobby.checklist.data.repository.TaskRepository
import com.prohobby.checklist.ui.task.TaskDetailActivity
import java.text.SimpleDateFormat
import java.util.*

class DeadlineCheckWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private val taskRepository = TaskRepository()

    override suspend fun doWork(): Result {
        return try {
            checkDeadlines()
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    private suspend fun checkDeadlines() {
        val response = taskRepository.getTasks("in_progress")
        if (!response.isSuccessful) return

        val tasks = response.body() ?: return
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

        tasks.forEach { task ->
            try {
                val deadline = dateFormat.parse(task.deadlineDate)
                if (deadline != null) {
                    val deadlineCalendar = Calendar.getInstance().apply {
                        time = deadline
                        set(Calendar.HOUR_OF_DAY, 0)
                        set(Calendar.MINUTE, 0)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                    }

                    val daysDiff = ((deadlineCalendar.timeInMillis - today.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()

                    // D-5, D-3, D-1에 알림
                    if (daysDiff in listOf(5, 3, 1)) {
                        sendNotification(task.id, task.title, "D-$daysDiff: ${task.title}")
                    } else if (daysDiff == 0) {
                        sendNotification(task.id, task.title, "오늘 마감: ${task.title}")
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun sendNotification(taskId: Int, title: String, message: String) {
        val intent = Intent(applicationContext, TaskDetailActivity::class.java).apply {
            putExtra("TASK_ID", taskId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            taskId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(applicationContext, ChecklistApplication.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(taskId, notification)
    }
}

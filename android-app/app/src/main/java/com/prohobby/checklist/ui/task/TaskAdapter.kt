package com.prohobby.checklist.ui.task

import android.graphics.Color
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.prohobby.checklist.R
import com.prohobby.checklist.data.model.Task
import com.prohobby.checklist.databinding.ItemTaskBinding
import java.text.SimpleDateFormat
import java.util.*

class TaskAdapter(
    private val onTaskClick: (Task) -> Unit
) : ListAdapter<Task, TaskAdapter.TaskViewHolder>(TaskDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TaskViewHolder {
        val binding = ItemTaskBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return TaskViewHolder(binding, onTaskClick)
    }

    override fun onBindViewHolder(holder: TaskViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    class TaskViewHolder(
        private val binding: ItemTaskBinding,
        private val onTaskClick: (Task) -> Unit
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(task: Task) {
            binding.apply {
                tvTitle.text = task.title
                tvDescription.text = task.description ?: "상세 내용 없음"
                tvDeadline.text = "마감: ${formatDate(task.deadlineDate)}"
                tvWorkers.text = "작업자: ${task.workers.joinToString(", ") { it.name }}"

                // 우선순위 배지
                val (priorityText, priorityColor) = when (task.priority) {
                    "high" -> "높음" to Color.parseColor("#F44336")
                    "medium" -> "보통" to Color.parseColor("#FF9800")
                    "low" -> "낮음" to Color.parseColor("#4CAF50")
                    else -> "보통" to Color.parseColor("#FF9800")
                }
                tvPriority.text = priorityText
                tvPriority.setTextColor(priorityColor)

                // 상태 배지
                val statusText = when (task.status) {
                    "completed" -> "완료"
                    "in_progress" -> "진행중"
                    else -> task.status
                }
                tvStatus.text = statusText

                // D-day 계산
                val dDay = calculateDDay(task.deadlineDate)
                tvDday.text = when {
                    task.status == "completed" -> "완료"
                    dDay < 0 -> "D+${-dDay} (지연)"
                    dDay == 0 -> "D-Day"
                    else -> "D-$dDay"
                }
                tvDday.setTextColor(
                    when {
                        task.status == "completed" -> Color.parseColor("#4CAF50")
                        dDay < 0 -> Color.parseColor("#F44336")
                        dDay <= 3 -> Color.parseColor("#FF9800")
                        else -> Color.parseColor("#757575")
                    }
                )

                root.setOnClickListener { onTaskClick(task) }
            }
        }

        private fun formatDate(dateString: String): String {
            return try {
                val inputFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val outputFormat = SimpleDateFormat("M월 d일", Locale.getDefault())
                val date = inputFormat.parse(dateString)
                outputFormat.format(date ?: Date())
            } catch (e: Exception) {
                dateString
            }
        }

        private fun calculateDDay(deadlineString: String): Int {
            return try {
                val format = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val deadline = format.parse(deadlineString)
                val today = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }.time

                val diff = (deadline!!.time - today.time) / (1000 * 60 * 60 * 24)
                diff.toInt()
            } catch (e: Exception) {
                0
            }
        }
    }

    class TaskDiffCallback : DiffUtil.ItemCallback<Task>() {
        override fun areItemsTheSame(oldItem: Task, newItem: Task): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: Task, newItem: Task): Boolean {
            return oldItem == newItem
        }
    }
}

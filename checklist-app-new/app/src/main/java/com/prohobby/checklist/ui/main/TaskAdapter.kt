package com.prohobby.checklist.ui.main

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.prohobby.checklist.R
import com.prohobby.checklist.data.model.Task

class TaskAdapter(
    private val onCallClick: (Task) -> Unit,
    private val onNudgeClick: (Task) -> Unit,
    private val onDeleteClick: (Task) -> Unit
) : RecyclerView.Adapter<TaskAdapter.TaskViewHolder>() {

    private var tasks: List<Task> = emptyList()

    fun submitList(newTasks: List<Task>) {
        tasks = newTasks
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TaskViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_task, parent, false)
        return TaskViewHolder(view)
    }

    override fun onBindViewHolder(holder: TaskViewHolder, position: Int) {
        holder.bind(tasks[position])
    }

    override fun getItemCount() = tasks.size

    inner class TaskViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val titleTextView: TextView = itemView.findViewById(R.id.taskTitleTextView)
        private val descriptionTextView: TextView = itemView.findViewById(R.id.taskDescriptionTextView)
        private val priorityTextView: TextView = itemView.findViewById(R.id.taskPriorityTextView)
        private val deadlineTextView: TextView = itemView.findViewById(R.id.taskDeadlineTextView)
        private val callButton: Button = itemView.findViewById(R.id.callButton)
        private val nudgeButton: Button = itemView.findViewById(R.id.nudgeButton)
        private val deleteButton: Button = itemView.findViewById(R.id.deleteButton)

        fun bind(task: Task) {
            titleTextView.text = task.title
            descriptionTextView.text = task.description ?: ""
            priorityTextView.text = "우선순위: ${task.priority}"
            deadlineTextView.text = "마감일: ${task.deadline ?: "없음"}"

            callButton.setOnClickListener { onCallClick(task) }
            nudgeButton.setOnClickListener { onNudgeClick(task) }
            deleteButton.setOnClickListener { onDeleteClick(task) }
        }
    }
}

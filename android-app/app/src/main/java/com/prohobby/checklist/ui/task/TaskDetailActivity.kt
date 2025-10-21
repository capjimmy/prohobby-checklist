package com.prohobby.checklist.ui.task

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.prohobby.checklist.R
import com.prohobby.checklist.data.model.Task
import com.prohobby.checklist.data.model.User
import com.prohobby.checklist.data.repository.TaskRepository
import com.prohobby.checklist.databinding.ActivityTaskDetailBinding
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class TaskDetailActivity : AppCompatActivity() {

    private lateinit var binding: ActivityTaskDetailBinding
    private val taskRepository = TaskRepository()
    private var currentTask: Task? = null
    private val CALL_PERMISSION_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTaskDetailBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)

        val taskId = intent.getIntExtra("TASK_ID", -1)
        if (taskId != -1) {
            loadTaskDetail(taskId)
        } else {
            finish()
        }

        setupClickListeners()
    }

    private fun loadTaskDetail(taskId: Int) {
        lifecycleScope.launch {
            try {
                val response = taskRepository.getTask(taskId)
                if (response.isSuccessful) {
                    response.body()?.let { task ->
                        currentTask = task
                        displayTaskDetail(task)
                    }
                } else {
                    Toast.makeText(this@TaskDetailActivity, "작업을 불러올 수 없습니다", Toast.LENGTH_SHORT).show()
                    finish()
                }
            } catch (e: Exception) {
                Toast.makeText(this@TaskDetailActivity, "네트워크 오류: ${e.message}", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun displayTaskDetail(task: Task) {
        binding.apply {
            tvTitle.text = task.title
            tvDescription.text = task.description ?: "상세 내용 없음"
            tvPriority.text = "우선순위: ${getPriorityText(task.priority)}"
            tvStatus.text = "상태: ${getStatusText(task.status)}"
            tvCreator.text = "등록자: ${task.creatorName}"
            tvCreatedDate.text = "등록일: ${formatDate(task.createdDate)}"
            tvDeadline.text = "마감일: ${formatDate(task.deadlineDate)}"

            if (task.completedDate != null) {
                tvCompletedDate.text = "완료일: ${formatDate(task.completedDate)}"
                tvCompleter.text = "완료자: ${task.completerName}"
            }

            // 작업자 목록
            val workersText = task.workers.joinToString("\n") { worker ->
                "${worker.name} (${worker.phone})"
            }
            tvWorkers.text = "작업자:\n$workersText"

            // 작업자 버튼 설정
            if (task.workers.isNotEmpty()) {
                btnCallWorker.setOnClickListener { showWorkerActionDialog(task.workers) }
            }

            // 완료 버튼
            btnComplete.isEnabled = task.status != "completed"
            btnComplete.text = if (task.status == "completed") "완료됨" else "완료 처리"
        }
    }

    private fun setupClickListeners() {
        binding.btnComplete.setOnClickListener {
            currentTask?.let { task ->
                if (task.status != "completed") {
                    completeTask(task.id)
                }
            }
        }
    }

    private fun showWorkerActionDialog(workers: List<User>) {
        val workerNames = workers.map { "${it.name} (${it.phone})" }.toTypedArray()

        MaterialAlertDialogBuilder(this)
            .setTitle("작업자 선택")
            .setItems(workerNames) { _, which ->
                val selectedWorker = workers[which]
                showActionMenu(selectedWorker)
            }
            .show()
    }

    private fun showActionMenu(worker: User) {
        val actions = arrayOf("전화하기", "독촉하기")

        MaterialAlertDialogBuilder(this)
            .setTitle(worker.name)
            .setItems(actions) { _, which ->
                when (which) {
                    0 -> makePhoneCall(worker.phone)
                    1 -> nudgeWorker()
                }
            }
            .show()
    }

    private fun makePhoneCall(phoneNumber: String) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                CALL_PERMISSION_CODE
            )
        } else {
            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$phoneNumber"))
            startActivity(intent)
        }
    }

    private fun nudgeWorker() {
        currentTask?.let { task ->
            lifecycleScope.launch {
                try {
                    val response = taskRepository.nudgeTask(task.id)
                    if (response.isSuccessful) {
                        Toast.makeText(this@TaskDetailActivity, "독촉 알림을 보냈습니다", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(this@TaskDetailActivity, "독촉 알림 전송 실패", Toast.LENGTH_SHORT).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this@TaskDetailActivity, "네트워크 오류", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun completeTask(taskId: Int) {
        lifecycleScope.launch {
            try {
                val response = taskRepository.completeTask(taskId)
                if (response.isSuccessful) {
                    Toast.makeText(this@TaskDetailActivity, "작업이 완료되었습니다", Toast.LENGTH_SHORT).show()
                    loadTaskDetail(taskId)
                } else {
                    Toast.makeText(this@TaskDetailActivity, "작업 완료 처리 실패", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@TaskDetailActivity, "네트워크 오류", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun deleteTask() {
        currentTask?.let { task ->
            MaterialAlertDialogBuilder(this)
                .setTitle("작업 삭제")
                .setMessage("정말 이 작업을 삭제하시겠습니까?")
                .setPositiveButton("삭제") { _, _ ->
                    lifecycleScope.launch {
                        try {
                            val response = taskRepository.deleteTask(task.id)
                            if (response.isSuccessful) {
                                Toast.makeText(this@TaskDetailActivity, "작업이 삭제되었습니다", Toast.LENGTH_SHORT).show()
                                finish()
                            } else {
                                Toast.makeText(this@TaskDetailActivity, "작업 삭제 실패", Toast.LENGTH_SHORT).show()
                            }
                        } catch (e: Exception) {
                            Toast.makeText(this@TaskDetailActivity, "네트워크 오류", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
                .setNegativeButton("취소", null)
                .show()
        }
    }

    private fun getPriorityText(priority: String): String {
        return when (priority) {
            "high" -> "높음"
            "medium" -> "보통"
            "low" -> "낮음"
            else -> priority
        }
    }

    private fun getStatusText(status: String): String {
        return when (status) {
            "in_progress" -> "진행중"
            "completed" -> "완료"
            else -> status
        }
    }

    private fun formatDate(dateString: String): String {
        return try {
            val inputFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val outputFormat = SimpleDateFormat("yyyy년 M월 d일", Locale.getDefault())
            val date = inputFormat.parse(dateString)
            outputFormat.format(date ?: Date())
        } catch (e: Exception) {
            dateString
        }
    }

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.task_detail_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                finish()
                true
            }
            R.id.action_delete -> {
                deleteTask()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CALL_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "전화 권한이 허용되었습니다", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "전화 권한이 거부되었습니다", Toast.LENGTH_SHORT).show()
            }
        }
    }
}

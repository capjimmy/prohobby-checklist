package com.prohobby.checklist.ui.task

import android.app.DatePickerDialog
import android.os.Bundle
import android.view.MenuItem
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.prohobby.checklist.data.model.User
import com.prohobby.checklist.data.repository.TaskRepository
import com.prohobby.checklist.databinding.ActivityCreateTaskBinding
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class CreateTaskActivity : AppCompatActivity() {

    private lateinit var binding: ActivityCreateTaskBinding
    private val taskRepository = TaskRepository()
    private var selectedWorkers = mutableListOf<User>()
    private var allUsers = listOf<User>()
    private var selectedDeadline = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCreateTaskBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.title = "작업 등록"

        loadUsers()
        setupClickListeners()
    }

    private fun loadUsers() {
        lifecycleScope.launch {
            try {
                val response = taskRepository.getUsers()
                if (response.isSuccessful) {
                    allUsers = response.body() ?: emptyList()
                } else {
                    Toast.makeText(this@CreateTaskActivity, "사용자 목록 불러오기 실패", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@CreateTaskActivity, "네트워크 오류", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun setupClickListeners() {
        // 우선순위 선택
        val priorities = arrayOf("높음", "보통", "낮음")
        val priorityAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, priorities)
        priorityAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.spinnerPriority.adapter = priorityAdapter
        binding.spinnerPriority.setSelection(1) // 기본값: 보통

        // 마감일 선택
        binding.btnSelectDeadline.setOnClickListener {
            showDatePicker()
        }

        // 작업자 선택
        binding.btnSelectWorkers.setOnClickListener {
            showWorkerSelectionDialog()
        }

        // 작업 생성
        binding.btnCreate.setOnClickListener {
            createTask()
        }
    }

    private fun showDatePicker() {
        val calendar = Calendar.getInstance()
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        val day = calendar.get(Calendar.DAY_OF_MONTH)

        DatePickerDialog(this, { _, selectedYear, selectedMonth, selectedDay ->
            calendar.set(selectedYear, selectedMonth, selectedDay)
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            selectedDeadline = dateFormat.format(calendar.time)

            val displayFormat = SimpleDateFormat("yyyy년 M월 d일", Locale.getDefault())
            binding.tvDeadline.text = "마감일: ${displayFormat.format(calendar.time)}"
        }, year, month, day).show()
    }

    private fun showWorkerSelectionDialog() {
        if (allUsers.isEmpty()) {
            Toast.makeText(this, "사용자 목록이 없습니다", Toast.LENGTH_SHORT).show()
            return
        }

        val userNames = allUsers.map { it.name }.toTypedArray()
        val checkedItems = BooleanArray(allUsers.size) { index ->
            selectedWorkers.any { it.id == allUsers[index].id }
        }

        androidx.appcompat.app.AlertDialog.Builder(this)
            .setTitle("작업자 선택")
            .setMultiChoiceItems(userNames, checkedItems) { _, which, isChecked ->
                if (isChecked) {
                    if (!selectedWorkers.contains(allUsers[which])) {
                        selectedWorkers.add(allUsers[which])
                    }
                } else {
                    selectedWorkers.remove(allUsers[which])
                }
            }
            .setPositiveButton("확인") { _, _ ->
                updateWorkerDisplay()
            }
            .setNegativeButton("취소", null)
            .show()
    }

    private fun updateWorkerDisplay() {
        if (selectedWorkers.isEmpty()) {
            binding.tvWorkers.text = "작업자를 선택해주세요"
        } else {
            binding.tvWorkers.text = "선택된 작업자: ${selectedWorkers.joinToString(", ") { it.name }}"
        }
    }

    private fun createTask() {
        val title = binding.etTitle.text.toString()
        val description = binding.etDescription.text.toString()
        val priorityIndex = binding.spinnerPriority.selectedItemPosition
        val priority = when (priorityIndex) {
            0 -> "high"
            1 -> "medium"
            2 -> "low"
            else -> "medium"
        }

        // 유효성 검사
        if (title.isBlank()) {
            Toast.makeText(this, "작업 이름을 입력해주세요", Toast.LENGTH_SHORT).show()
            return
        }

        if (selectedDeadline.isEmpty()) {
            Toast.makeText(this, "마감일을 선택해주세요", Toast.LENGTH_SHORT).show()
            return
        }

        if (selectedWorkers.isEmpty()) {
            Toast.makeText(this, "작업자를 선택해주세요", Toast.LENGTH_SHORT).show()
            return
        }

        // 작업 생성
        binding.progressBar.visibility = View.VISIBLE
        binding.btnCreate.isEnabled = false

        lifecycleScope.launch {
            try {
                val workerIds = selectedWorkers.map { it.id }
                val response = taskRepository.createTask(
                    title,
                    description.ifBlank { null },
                    priority,
                    selectedDeadline,
                    workerIds
                )

                if (response.isSuccessful) {
                    Toast.makeText(this@CreateTaskActivity, "작업이 등록되었습니다", Toast.LENGTH_SHORT).show()
                    finish()
                } else {
                    Toast.makeText(this@CreateTaskActivity, "작업 등록 실패", Toast.LENGTH_SHORT).show()
                    binding.btnCreate.isEnabled = true
                }
            } catch (e: Exception) {
                Toast.makeText(this@CreateTaskActivity, "네트워크 오류: ${e.message}", Toast.LENGTH_SHORT).show()
                binding.btnCreate.isEnabled = true
            } finally {
                binding.progressBar.visibility = View.GONE
            }
        }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                finish()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
}

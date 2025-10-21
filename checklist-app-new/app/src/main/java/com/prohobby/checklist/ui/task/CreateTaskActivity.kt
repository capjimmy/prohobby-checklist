package com.prohobby.checklist.ui.task

import android.content.Context
import android.os.Bundle
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.prohobby.checklist.R
import com.prohobby.checklist.data.api.RetrofitClient
import com.prohobby.checklist.data.model.CreateTaskRequest
import com.prohobby.checklist.data.model.User
import kotlinx.coroutines.launch

class CreateTaskActivity : AppCompatActivity() {

    private lateinit var titleEditText: EditText
    private lateinit var descriptionEditText: EditText
    private lateinit var prioritySpinner: Spinner
    private lateinit var deadlineEditText: EditText
    private lateinit var workersSpinner: Spinner
    private lateinit var createButton: Button
    private var token: String = ""
    private var users: List<User> = emptyList()
    private var selectedUserId: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_create_task)

        val prefs = getSharedPreferences("auth", Context.MODE_PRIVATE)
        token = prefs.getString("token", "") ?: ""

        titleEditText = findViewById(R.id.titleEditText)
        descriptionEditText = findViewById(R.id.descriptionEditText)
        prioritySpinner = findViewById(R.id.prioritySpinner)
        deadlineEditText = findViewById(R.id.deadlineEditText)
        workersSpinner = findViewById(R.id.workersSpinner)
        createButton = findViewById(R.id.createButton)

        // Setup priority spinner
        val priorities = arrayOf("high", "medium", "low")
        prioritySpinner.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, priorities)

        // Load users
        loadUsers()

        createButton.setOnClickListener {
            createTask()
        }
    }

    private fun loadUsers() {
        lifecycleScope.launch {
            try {
                val response = RetrofitClient.apiService.getUsers("Bearer $token")
                if (response.isSuccessful && response.body() != null) {
                    users = response.body()!!
                    val userNames = users.map { it.name }
                    workersSpinner.adapter = ArrayAdapter(
                        this@CreateTaskActivity,
                        android.R.layout.simple_spinner_item,
                        userNames
                    )
                }
            } catch (e: Exception) {
                Toast.makeText(this@CreateTaskActivity, "사용자 로드 실패: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun createTask() {
        val title = titleEditText.text.toString()
        val description = descriptionEditText.text.toString()
        val priority = prioritySpinner.selectedItem.toString()
        val deadline = deadlineEditText.text.toString().ifBlank { null }

        if (title.isBlank()) {
            Toast.makeText(this, "제목을 입력하세요", Toast.LENGTH_SHORT).show()
            return
        }

        val selectedPosition = workersSpinner.selectedItemPosition
        val workerIds = if (selectedPosition >= 0 && users.isNotEmpty()) {
            listOf(users[selectedPosition].id)
        } else {
            emptyList()
        }

        lifecycleScope.launch {
            try {
                val request = CreateTaskRequest(title, description, priority, deadline, workerIds)
                val response = RetrofitClient.apiService.createTask("Bearer $token", request)
                if (response.isSuccessful) {
                    Toast.makeText(this@CreateTaskActivity, "작업 생성 완료", Toast.LENGTH_SHORT).show()
                    finish()
                } else {
                    Toast.makeText(this@CreateTaskActivity, "작업 생성 실패", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@CreateTaskActivity, "오류: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }
}

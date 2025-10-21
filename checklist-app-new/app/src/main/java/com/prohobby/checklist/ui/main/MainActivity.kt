package com.prohobby.checklist.ui.main

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.prohobby.checklist.R
import com.prohobby.checklist.data.api.RetrofitClient
import com.prohobby.checklist.data.model.Task
import com.prohobby.checklist.ui.auth.LoginActivity
import com.prohobby.checklist.ui.task.CreateTaskActivity
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var createTaskButton: Button
    private lateinit var logoutButton: Button
    private lateinit var welcomeTextView: TextView
    private lateinit var taskAdapter: TaskAdapter
    private var token: String = ""

    companion object {
        private const val CALL_PERMISSION_REQUEST_CODE = 100
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val prefs = getSharedPreferences("auth", Context.MODE_PRIVATE)
        token = prefs.getString("token", "") ?: ""
        val userName = prefs.getString("userName", "사용자")

        welcomeTextView = findViewById(R.id.welcomeTextView)
        recyclerView = findViewById(R.id.tasksRecyclerView)
        createTaskButton = findViewById(R.id.createTaskButton)
        logoutButton = findViewById(R.id.logoutButton)

        welcomeTextView.text = "안녕하세요, $userName 님!"

        taskAdapter = TaskAdapter(
            onCallClick = { task -> callWorker(task) },
            onNudgeClick = { task -> nudgeTask(task) },
            onDeleteClick = { task -> deleteTask(task) }
        )

        recyclerView.layoutManager = LinearLayoutManager(this)
        recyclerView.adapter = taskAdapter

        createTaskButton.setOnClickListener {
            startActivity(Intent(this, CreateTaskActivity::class.java))
        }

        logoutButton.setOnClickListener {
            prefs.edit().clear().apply()
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
        }

        loadTasks()
    }

    override fun onResume() {
        super.onResume()
        loadTasks()
    }

    private fun loadTasks() {
        lifecycleScope.launch {
            try {
                val response = RetrofitClient.apiService.getTasks("Bearer $token")
                if (response.isSuccessful && response.body() != null) {
                    taskAdapter.submitList(response.body()!!)
                } else {
                    Toast.makeText(this@MainActivity, "작업 로드 실패", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@MainActivity, "오류: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun callWorker(task: Task) {
        if (task.workers.isNullOrEmpty()) {
            Toast.makeText(this, "작업자가 없습니다", Toast.LENGTH_SHORT).show()
            return
        }

        val phone = task.workers[0].phone

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE),
                CALL_PERMISSION_REQUEST_CODE)
        } else {
            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$phone"))
            startActivity(intent)
        }
    }

    private fun nudgeTask(task: Task) {
        lifecycleScope.launch {
            try {
                val response = RetrofitClient.apiService.nudgeTask("Bearer $token", task.id)
                if (response.isSuccessful) {
                    Toast.makeText(this@MainActivity, "넛지 전송 완료", Toast.LENGTH_SHORT).show()
                } else {
                    Toast.makeText(this@MainActivity, "넛지 전송 실패", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@MainActivity, "오류: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun deleteTask(task: Task) {
        lifecycleScope.launch {
            try {
                val response = RetrofitClient.apiService.deleteTask("Bearer $token", task.id)
                if (response.isSuccessful) {
                    Toast.makeText(this@MainActivity, "작업 삭제 완료", Toast.LENGTH_SHORT).show()
                    loadTasks()
                } else {
                    Toast.makeText(this@MainActivity, "작업 삭제 실패", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@MainActivity, "오류: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }
}

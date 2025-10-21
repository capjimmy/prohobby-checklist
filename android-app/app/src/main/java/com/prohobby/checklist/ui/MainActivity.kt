package com.prohobby.checklist.ui

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.android.material.chip.Chip
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.prohobby.checklist.ChecklistApplication
import com.prohobby.checklist.R
import com.prohobby.checklist.data.repository.AuthRepository
import com.prohobby.checklist.data.repository.TaskRepository
import com.prohobby.checklist.databinding.ActivityMainBinding
import com.prohobby.checklist.ui.auth.LoginActivity
import com.prohobby.checklist.ui.task.CreateTaskActivity
import com.prohobby.checklist.ui.task.TaskAdapter
import com.prohobby.checklist.ui.task.TaskViewModel

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var viewModel: TaskViewModel
    private lateinit var adapter: TaskAdapter
    private var currentFilter = "all"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setSupportActionBar(binding.toolbar)

        val taskRepository = TaskRepository()
        viewModel = TaskViewModel(taskRepository)

        setupRecyclerView()
        setupObservers()
        setupClickListeners()

        viewModel.loadTasks()
    }

    private fun setupRecyclerView() {
        adapter = TaskAdapter(
            onTaskClick = { task ->
                // 상세 화면으로 이동
                val intent = Intent(this, com.prohobby.checklist.ui.task.TaskDetailActivity::class.java)
                intent.putExtra("TASK_ID", task.id)
                startActivity(intent)
            }
        )

        binding.recyclerView.apply {
            layoutManager = LinearLayoutManager(this@MainActivity)
            adapter = this@MainActivity.adapter
        }
    }

    private fun setupObservers() {
        viewModel.tasks.observe(this) { tasks ->
            adapter.submitList(tasks)
            binding.tvEmpty.visibility = if (tasks.isEmpty()) View.VISIBLE else View.GONE
        }

        viewModel.isLoading.observe(this) { isLoading ->
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        }

        viewModel.error.observe(this) { error ->
            Toast.makeText(this, error, Toast.LENGTH_SHORT).show()
        }

        viewModel.actionResult.observe(this) { message ->
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        }
    }

    private fun setupClickListeners() {
        binding.fabAdd.setOnClickListener {
            startActivity(Intent(this, CreateTaskActivity::class.java))
        }

        binding.chipAll.setOnClickListener {
            currentFilter = "all"
            viewModel.loadTasks()
            updateChipSelection(binding.chipAll)
        }

        binding.chipInProgress.setOnClickListener {
            currentFilter = "in_progress"
            viewModel.loadTasks("in_progress")
            updateChipSelection(binding.chipInProgress)
        }

        binding.chipCompleted.setOnClickListener {
            currentFilter = "completed"
            viewModel.loadTasks("completed")
            updateChipSelection(binding.chipCompleted)
        }
    }

    private fun updateChipSelection(selectedChip: Chip) {
        binding.chipAll.isChecked = selectedChip == binding.chipAll
        binding.chipInProgress.isChecked = selectedChip == binding.chipInProgress
        binding.chipCompleted.isChecked = selectedChip == binding.chipCompleted
    }

    override fun onResume() {
        super.onResume()
        viewModel.loadTasks(if (currentFilter == "all") null else currentFilter)
    }

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.main_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_refresh -> {
                viewModel.loadTasks(if (currentFilter == "all") null else currentFilter)
                true
            }
            R.id.action_logout -> {
                showLogoutDialog()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun showLogoutDialog() {
        MaterialAlertDialogBuilder(this)
            .setTitle("로그아웃")
            .setMessage("로그아웃 하시겠습니까?")
            .setPositiveButton("확인") { _, _ ->
                logout()
            }
            .setNegativeButton("취소", null)
            .show()
    }

    private fun logout() {
        val preferenceManager = (application as ChecklistApplication).preferenceManager
        val authRepository = AuthRepository(preferenceManager)
        authRepository.logout()

        startActivity(Intent(this, LoginActivity::class.java))
        finish()
    }
}

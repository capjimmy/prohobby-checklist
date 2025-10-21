package com.prohobby.checklist.ui.auth

import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.prohobby.checklist.ChecklistApplication
import com.prohobby.checklist.data.repository.AuthRepository
import com.prohobby.checklist.databinding.ActivityRegisterBinding

class RegisterActivity : AppCompatActivity() {

    private lateinit var binding: ActivityRegisterBinding
    private lateinit var viewModel: RegisterViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityRegisterBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val preferenceManager = (application as ChecklistApplication).preferenceManager
        val authRepository = AuthRepository(preferenceManager)
        viewModel = RegisterViewModel(authRepository)

        setupObservers()
        setupClickListeners()
    }

    private fun setupObservers() {
        viewModel.registerResult.observe(this) { result ->
            result.onSuccess {
                Toast.makeText(this, it, Toast.LENGTH_SHORT).show()
                finish()
            }
            result.onFailure {
                Toast.makeText(this, it.message, Toast.LENGTH_SHORT).show()
            }
        }

        viewModel.isLoading.observe(this) { isLoading ->
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
            binding.btnRegister.isEnabled = !isLoading
        }
    }

    private fun setupClickListeners() {
        binding.btnRegister.setOnClickListener {
            val name = binding.etName.text.toString()
            val phone = binding.etPhone.text.toString()
            val birthdate = binding.etBirthdate.text.toString()
            val password = binding.etPassword.text.toString()
            val confirmPassword = binding.etConfirmPassword.text.toString()

            viewModel.register(name, phone, birthdate, password, confirmPassword)
        }

        binding.btnBack.setOnClickListener {
            finish()
        }
    }
}

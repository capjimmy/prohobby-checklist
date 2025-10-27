import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  final StorageService _storageService;

  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._firebaseService, this._storageService);

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize - check if already logged in
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Firebase Auth state를 확인
      final userId = _firebaseService.getCurrentUserId();
      if (userId != null) {
        // Firestore에서 사용자 정보 가져오기
        _user = await _firebaseService.getUser(userId);
        if (_user != null) {
          await _storageService.saveUser(_user!);
        }
      }
    } catch (e) {
      _error = '초기화 실패: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _firebaseService.login(
        phone: phone,
        password: password,
      );
      await _storageService.saveUser(_user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '로그인 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String phone,
    required String birthdate,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.register(
        name: name,
        phone: phone,
        birthdate: birthdate,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '회원가입 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _firebaseService.logout();
    await _storageService.clear();
    _user = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

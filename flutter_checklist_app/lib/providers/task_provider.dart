import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseService _firebaseService;

  List<Task> _tasks = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  TaskProvider(this._firebaseService);

  List<Task> get tasks => _tasks;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get filtered tasks (비밀 작업 필터링 포함)
  List<Task> getTasksByStatus(String status) {
    final currentUserId = _firebaseService.getCurrentUserId();
    return _tasks.where((task) {
      // 상태 필터
      if (task.status != status) return false;

      // 비밀 작업인 경우: 작업자 또는 등록자만 볼 수 있음
      if (task.isPrivate) {
        return task.creatorId == currentUserId ||
               task.workerIds.contains(currentUserId);
      }

      // 일반 작업은 모두 표시
      return true;
    }).toList();
  }

  // Fetch all tasks
  Future<void> fetchTasks({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _firebaseService.getTasks(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '작업 목록 조회 실패: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all users
  Future<void> fetchUsers() async {
    try {
      _users = await _firebaseService.getUsers();
      notifyListeners();
    } catch (e) {
      _error = '사용자 목록 조회 실패: $e';
      notifyListeners();
    }
  }

  // Create task
  Future<bool> createTask({
    required String title,
    String? description,
    required String priority,
    required String deadlineDate,
    required List<String> workerIds,
    bool isPrivate = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.createTask(
        title: title,
        description: description ?? '',
        priority: priority,
        deadlineDate: deadlineDate,
        workerIds: workerIds,
        isPrivate: isPrivate,
      );

      // Refresh tasks
      await fetchTasks();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '작업 생성 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update task
  Future<bool> updateTask({
    required String id,
    required String title,
    String? description,
    required String priority,
    required String deadlineDate,
    required List<String> workerIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.updateTask(
        taskId: id,
        title: title,
        description: description,
        priority: priority,
        deadlineDate: deadlineDate,
        workerIds: workerIds,
      );

      // Refresh tasks
      await fetchTasks();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '작업 수정 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Complete task
  Future<bool> completeTask(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.updateTaskStatus(id, 'completed');

      // Refresh tasks
      await fetchTasks();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '작업 완료 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Uncomplete task (완료 취소)
  Future<bool> uncompleteTask(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.uncompleteTask(id);

      // Refresh tasks
      await fetchTasks();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '완료 취소 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Nudge worker (독촉하기)
  Future<bool> nudgeWorker(String taskId, String workerId) async {
    try {
      await _firebaseService.nudgeWorker(taskId, workerId);
      return true;
    } catch (e) {
      _error = '독촉 실패: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.deleteTask(id);

      // Remove from local list
      _tasks.removeWhere((task) => task.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '작업 삭제 실패: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

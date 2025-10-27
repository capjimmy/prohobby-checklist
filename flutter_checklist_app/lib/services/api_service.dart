import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/task.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl;

  ApiService({this.baseUrl = 'http://localhost:5000'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Set token for authenticated requests
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ==================== Auth APIs ====================

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/api/login', data: request.toJson());
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post('/api/register', data: request.toJson());
      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== User APIs ====================

  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('/api/users');
      return (response.data as List).map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getUserById(int id) async {
    try {
      final response = await _dio.get('/api/users/$id');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Task APIs ====================

  Future<List<Task>> getTasks({String? status}) async {
    try {
      print('🌐 API: Fetching tasks with status: $status');
      final response = await _dio.get(
        '/api/tasks',
        queryParameters: status != null ? {'status': status} : null,
      );
      print('✅ API: Response received, parsing ${(response.data as List).length} tasks');

      final tasks = <Task>[];
      for (var i = 0; i < (response.data as List).length; i++) {
        try {
          final json = (response.data as List)[i];
          print('   Parsing task $i: ${json['title']}');
          final task = Task.fromJson(json);
          tasks.add(task);
          print('   ✅ Task $i parsed successfully');
        } catch (e, stackTrace) {
          print('   ❌ Error parsing task $i: $e');
          print('   Stack: $stackTrace');
          print('   JSON: ${(response.data as List)[i]}');
        }
      }

      print('✅ API: Successfully parsed ${tasks.length} tasks');
      return tasks;
    } on DioException catch (e) {
      print('❌ API: DioException: ${_handleError(e)}');
      throw _handleError(e);
    } catch (e, stackTrace) {
      print('❌ API: Unexpected error: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  Future<Task> getTaskById(int id) async {
    try {
      final response = await _dio.get('/api/tasks/$id');
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TaskResponse> createTask(CreateTaskRequest request) async {
    try {
      final response = await _dio.post('/api/tasks', data: request.toJson());
      return TaskResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TaskResponse> updateTask(int id, UpdateTaskRequest request) async {
    try {
      final response = await _dio.put('/api/tasks/$id', data: request.toJson());
      return TaskResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<TaskResponse> completeTask(int id) async {
    try {
      final response = await _dio.put('/api/tasks/$id/complete');
      return TaskResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete('/api/tasks/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> nudgeTask(int id) async {
    try {
      await _dio.post('/api/tasks/$id/nudge');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Error Handling ====================

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error'];
      }
      return '서버 오류: ${error.response!.statusCode}';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return '연결 시간 초과';
    }

    if (error.type == DioExceptionType.connectionError) {
      return '서버에 연결할 수 없습니다';
    }

    return '알 수 없는 오류가 발생했습니다';
  }
}

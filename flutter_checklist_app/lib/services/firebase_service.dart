import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart' as models;
import '../models/task.dart';
import '../models/comment.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // ==================== Authentication ====================

  // 회원가입
  Future<models.User> register({
    required String name,
    required String phone,
    required String birthdate,
    required String password,
  }) async {
    try {
      // Firebase Auth는 이메일 기반이므로, 전화번호를 이메일 형식으로 변환
      final email = '$phone@prohobby.app';

      // Firebase Authentication으로 사용자 생성
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에 사용자 정보 저장
      final user = models.User(
        id: credential.user!.uid,
        name: name,
        phone: phone,
        birthdate: birthdate,
        isAdmin: false,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toFirestore());

      return user;
    } catch (e) {
      throw Exception('회원가입 실패: $e');
    }
  }

  // 로그인
  Future<models.User> login({
    required String phone,
    required String password,
  }) async {
    try {
      // 전화번호를 이메일 형식으로 변환
      final email = '$phone@prohobby.app';

      // Firebase Authentication으로 로그인
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에서 사용자 정보 가져오기
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }

      return models.User.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('로그인 실패: $e');
    }
  }

  // 로그아웃
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 현재 사용자
  models.User? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    // Note: Firestore에서 가져와야 완전한 정보를 얻을 수 있음
    return null;
  }

  // 현재 사용자 ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // ==================== Users ====================

  // 모든 사용자 조회
  Future<List<models.User>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => models.User.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('사용자 목록 조회 실패: $e');
    }
  }

  // 특정 사용자 조회
  Future<models.User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return models.User.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('사용자 조회 실패: $e');
    }
  }

  // ==================== Tasks ====================

  // 작업 생성
  Future<Task> createTask({
    required String title,
    required String description,
    required String priority,
    required String deadlineDate,
    required List<String> workerIds,
    bool isPrivate = false,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('로그인이 필요합니다');

      // 사용자 정보 가져오기
      final user = await getUser(userId);
      if (user == null) throw Exception('사용자 정보를 찾을 수 없습니다');

      final now = DateTime.now();
      final task = Task(
        title: title,
        description: description,
        priority: priority,
        status: 'in_progress',
        creatorId: userId,
        creatorName: user.name,
        deadlineDate: deadlineDate,
        createdDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        workerIds: workerIds,
        isPrivate: isPrivate,
      );

      final docRef = await _firestore
          .collection('tasks')
          .add(task.toFirestore());

      // ID를 포함한 새 Task 객체 생성
      return Task(
        id: docRef.id,
        title: task.title,
        description: task.description,
        priority: task.priority,
        status: task.status,
        creatorId: task.creatorId,
        creatorName: task.creatorName,
        deadlineDate: task.deadlineDate,
        createdDate: task.createdDate,
        workerIds: task.workerIds,
        isPrivate: task.isPrivate,
      );
    } catch (e) {
      throw Exception('작업 생성 실패: $e');
    }
  }

  // 작업 목록 조회
  Future<List<Task>> getTasks({String? status}) async {
    try {
      Query query = _firestore.collection('tasks');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      final tasks = snapshot.docs
          .map((doc) => Task.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // created_date 기준으로 정렬 (최신순)
      tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));

      return tasks;
    } catch (e) {
      throw Exception('작업 목록 조회 실패: $e');
    }
  }

  // 특정 작업 조회
  Future<Task?> getTask(String taskId) async {
    try {
      final doc = await _firestore.collection('tasks').doc(taskId).get();
      if (!doc.exists) return null;
      return Task.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('작업 조회 실패: $e');
    }
  }

  // 작업 상태 업데이트 (완료/진행중)
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('로그인이 필요합니다');

      final updateData = <String, dynamic>{
        'status': status,
      };

      if (status == 'completed') {
        // 완료 처리
        final user = await getUser(userId);
        final now = DateTime.now();
        updateData['completer_id'] = userId;
        if (user?.name != null) {
          updateData['completer_name'] = user!.name;
        }
        updateData['completed_date'] = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      } else if (status == 'in_progress') {
        // 완료 취소 - 완료 관련 필드 제거
        updateData['completer_id'] = null;
        updateData['completer_name'] = null;
        updateData['completed_date'] = null;
      }

      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update(updateData);
    } catch (e) {
      throw Exception('작업 상태 업데이트 실패: $e');
    }
  }

  // 작업 완료 취소
  Future<void> uncompleteTask(String taskId) async {
    await updateTaskStatus(taskId, 'in_progress');
  }

  // 담당자 독촉하기 (Firestore에 독촉 기록 저장)
  Future<void> nudgeWorker(String taskId, String workerId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('로그인이 필요합니다');

      final user = await getUser(userId);
      final worker = await getUser(workerId);
      final task = await getTask(taskId);
      final now = DateTime.now();

      // 독촉 기록을 Firestore에 저장
      await _firestore.collection('nudges').add({
        'task_id': taskId,
        'task_title': task?.title ?? '',
        'from_user_id': userId,
        'from_user_name': user?.name ?? '',
        'to_user_id': workerId,
        'to_user_name': worker?.name ?? '',
        'to_user_phone': worker?.phone ?? '',
        'created_at': now.toIso8601String(),
      });
    } catch (e) {
      throw Exception('독촉 실패: $e');
    }
  }

  // 담당자에게 커스텀 메시지로 독촉하기
  Future<void> nudgeWorkerWithMessage(
    String taskId,
    String workerId,
    String customMessage,
  ) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('로그인이 필요합니다');

      final user = await getUser(userId);
      final worker = await getUser(workerId);
      final task = await getTask(taskId);
      final now = DateTime.now();

      // 커스텀 메시지와 함께 독촉 기록을 Firestore에 저장
      await _firestore.collection('nudges').add({
        'task_id': taskId,
        'task_title': task?.title ?? '',
        'from_user_id': userId,
        'from_user_name': user?.name ?? '',
        'to_user_id': workerId,
        'to_user_name': worker?.name ?? '',
        'to_user_phone': worker?.phone ?? '',
        'custom_message': customMessage,
        'created_at': now.toIso8601String(),
      });
    } catch (e) {
      throw Exception('메시지 전송 실패: $e');
    }
  }

  // 작업 삭제
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('작업 삭제 실패: $e');
    }
  }

  // 작업 수정
  Future<void> updateTask({
    required String taskId,
    required String title,
    String? description,
    required String priority,
    required String deadlineDate,
    required List<String> workerIds,
  }) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'title': title,
        'description': description,
        'priority': priority,
        'deadline_date': deadlineDate,
        'worker_ids': workerIds,
      });
    } catch (e) {
      throw Exception('작업 수정 실패: $e');
    }
  }

  // ==================== Comments ====================

  // 댓글 생성
  Future<Comment> createComment({
    required String taskId,
    required String content,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('로그인이 필요합니다');

      final user = await getUser(userId);
      if (user == null) throw Exception('사용자 정보를 찾을 수 없습니다');

      // 작업 정보 가져오기
      final task = await getTask(taskId);
      if (task == null) throw Exception('작업을 찾을 수 없습니다');

      final now = DateTime.now();
      final comment = Comment(
        taskId: taskId,
        userId: userId,
        userName: user.name,
        content: content,
        createdAt: now.toIso8601String(),
      );

      final docRef = await _firestore.collection('comments').add(comment.toFirestore());

      // 알림 대상자 수집 (작업 등록자 + 담당자들, 단 본인 제외)
      final Set<String> notificationTargets = {};

      // 작업 등록자 추가
      if (task.creatorId != userId) {
        notificationTargets.add(task.creatorId);
      }

      // 담당자들 추가 (본인 제외)
      for (final workerId in task.workerIds) {
        if (workerId != userId) {
          notificationTargets.add(workerId);
        }
      }

      // 각 대상자에게 알림 데이터 생성
      for (final targetUserId in notificationTargets) {
        final targetUser = await getUser(targetUserId);
        await _firestore.collection('comment_notifications').add({
          'comment_id': docRef.id,
          'task_id': taskId,
          'task_title': task.title,
          'from_user_id': userId,
          'from_user_name': user.name,
          'to_user_id': targetUserId,
          'to_user_name': targetUser?.name ?? '',
          'to_user_phone': targetUser?.phone ?? '',
          'comment_content': content,
          'created_at': now.toIso8601String(),
        });
      }

      return Comment(
        id: docRef.id,
        taskId: comment.taskId,
        userId: comment.userId,
        userName: comment.userName,
        content: comment.content,
        createdAt: comment.createdAt,
      );
    } catch (e) {
      throw Exception('댓글 생성 실패: $e');
    }
  }

  // 특정 작업의 댓글 목록 조회
  Future<List<Comment>> getComments(String taskId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('task_id', isEqualTo: taskId)
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('댓글 조회 실패: $e');
    }
  }

  // 댓글 수정
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('comments').doc(commentId).update({
        'content': content,
        'updated_at': now.toIso8601String(),
      });
    } catch (e) {
      throw Exception('댓글 수정 실패: $e');
    }
  }

  // 댓글 삭제
  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
    } catch (e) {
      throw Exception('댓글 삭제 실패: $e');
    }
  }
}

// Task의 copyWith 메서드를 위한 확장
extension TaskExtension on Task {
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? creatorId,
    String? completerId,
    String? createdDate,
    String? deadlineDate,
    String? completedDate,
    String? creatorName,
    String? completerName,
    List<String>? workerIds,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      completerId: completerId ?? this.completerId,
      createdDate: createdDate ?? this.createdDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      completedDate: completedDate ?? this.completedDate,
      creatorName: creatorName ?? this.creatorName,
      completerName: completerName ?? this.completerName,
      workerIds: workerIds ?? this.workerIds,
    );
  }
}

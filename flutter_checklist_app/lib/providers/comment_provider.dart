import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/firebase_service.dart';

class CommentProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;

  CommentProvider(this._firebaseService);

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 댓글 목록 불러오기
  Future<void> fetchComments(String taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _comments = await _firebaseService.getComments(taskId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 댓글 작성
  Future<bool> createComment({
    required String taskId,
    required String content,
  }) async {
    _error = null;

    try {
      final newComment = await _firebaseService.createComment(
        taskId: taskId,
        content: content,
      );

      _comments.add(newComment);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 댓글 수정
  Future<bool> updateComment({
    required String commentId,
    required String content,
  }) async {
    _error = null;

    try {
      await _firebaseService.updateComment(
        commentId: commentId,
        content: content,
      );

      // 로컬 상태 업데이트
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final now = DateTime.now();
        _comments[index] = Comment(
          id: _comments[index].id,
          taskId: _comments[index].taskId,
          userId: _comments[index].userId,
          userName: _comments[index].userName,
          content: content,
          createdAt: _comments[index].createdAt,
          updatedAt: now.toIso8601String(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 댓글 삭제
  Future<bool> deleteComment(String commentId) async {
    _error = null;

    try {
      await _firebaseService.deleteComment(commentId);

      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 댓글 목록 초기화
  void clearComments() {
    _comments = [];
    _error = null;
    notifyListeners();
  }
}

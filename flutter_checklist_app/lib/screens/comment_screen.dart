import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/comment_provider.dart';
import '../services/firebase_service.dart';

class CommentScreen extends StatefulWidget {
  final Task task;

  const CommentScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final commentProvider = Provider.of<CommentProvider>(context, listen: false);
      if (widget.task.id != null) {
        commentProvider.fetchComments(widget.task.id!);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || widget.task.id == null) return;

    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    final success = await commentProvider.createComment(
      taskId: widget.task.id!,
      content: content,
    );

    if (success) {
      _commentController.clear();
      // 스크롤을 아래로 이동
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(commentProvider.error ?? '댓글 작성 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editComment(String commentId, String currentContent) async {
    final controller = TextEditingController(text: currentContent);

    final newContent = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('댓글 수정'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '댓글 내용',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('수정'),
            ),
          ],
        );
      },
    );

    if (newContent == null || newContent.isEmpty || newContent == currentContent) {
      return;
    }

    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    final success = await commentProvider.updateComment(
      commentId: commentId,
      content: newContent,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commentProvider.error ?? '댓글 수정 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('댓글 삭제'),
          content: const Text('이 댓글을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    final success = await commentProvider.deleteComment(commentId);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commentProvider.error ?? '댓글 삭제 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final currentUserId = firebaseService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('댓글'),
      ),
      body: Column(
        children: [
          // 작업 정보
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.task.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 댓글 목록
          Expanded(
            child: Consumer<CommentProvider>(
              builder: (context, commentProvider, child) {
                if (commentProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (commentProvider.comments.isEmpty) {
                  return const Center(
                    child: Text('첫 댓글을 작성해보세요!'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: commentProvider.comments.length,
                  itemBuilder: (context, index) {
                    final comment = commentProvider.comments[index];
                    final isMyComment = comment.userId == currentUserId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  child: Text(
                                    comment.userName[0],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(comment.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMyComment)
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit' && comment.id != null) {
                                        _editComment(comment.id!, comment.content);
                                      } else if (value == 'delete' && comment.id != null) {
                                        _deleteComment(comment.id!);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('수정'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('삭제', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment.content,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (comment.updatedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '(수정됨)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 댓글 입력
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      return '';
    }
  }
}

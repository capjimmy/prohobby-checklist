import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  final String? id;
  @JsonKey(name: 'task_id')
  final String taskId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'user_name')
  final String userName;
  final String content;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Comment({
    this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  factory Comment.fromFirestore(String id, Map<String, dynamic> data) {
    return Comment(
      id: id,
      taskId: data['task_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['created_at'] ?? '',
      updatedAt: data['updated_at'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'task_id': taskId,
      'user_id': userId,
      'user_name': userName,
      'content': content,
      'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

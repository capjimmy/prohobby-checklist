// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  id: json['id'] as String?,
  taskId: json['task_id'] as String,
  userId: json['user_id'] as String,
  userName: json['user_name'] as String,
  content: json['content'] as String,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'id': instance.id,
  'task_id': instance.taskId,
  'user_id': instance.userId,
  'user_name': instance.userName,
  'content': instance.content,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

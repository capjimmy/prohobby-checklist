// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: json['id'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  priority: json['priority'] as String,
  status: json['status'] as String,
  creatorId: json['creator_id'] as String,
  completerId: json['completer_id'] as String?,
  createdDate: json['created_date'] as String,
  deadlineDate: json['deadline_date'] as String,
  completedDate: json['completed_date'] as String?,
  creatorName: json['creator_name'] as String?,
  completerName: json['completer_name'] as String?,
  workerIds: (json['worker_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isPrivate: json['is_private'] as bool? ?? false,
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'priority': instance.priority,
  'status': instance.status,
  'creator_id': instance.creatorId,
  'completer_id': instance.completerId,
  'created_date': instance.createdDate,
  'deadline_date': instance.deadlineDate,
  'completed_date': instance.completedDate,
  'creator_name': instance.creatorName,
  'completer_name': instance.completerName,
  'worker_ids': instance.workerIds,
  'is_private': instance.isPrivate,
};

CreateTaskRequest _$CreateTaskRequestFromJson(Map<String, dynamic> json) =>
    CreateTaskRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String,
      deadlineDate: json['deadline_date'] as String,
      workerIds: (json['worker_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateTaskRequestToJson(CreateTaskRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'deadline_date': instance.deadlineDate,
      'worker_ids': instance.workerIds,
    };

UpdateTaskRequest _$UpdateTaskRequestFromJson(Map<String, dynamic> json) =>
    UpdateTaskRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String,
      deadlineDate: json['deadline_date'] as String,
      status: json['status'] as String,
      workerIds: (json['worker_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UpdateTaskRequestToJson(UpdateTaskRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'deadline_date': instance.deadlineDate,
      'status': instance.status,
      'worker_ids': instance.workerIds,
    };

TaskResponse _$TaskResponseFromJson(Map<String, dynamic> json) => TaskResponse(
  message: json['message'] as String,
  taskId: (json['taskId'] as num?)?.toInt(),
);

Map<String, dynamic> _$TaskResponseToJson(TaskResponse instance) =>
    <String, dynamic>{'message': instance.message, 'taskId': instance.taskId};

import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String? id; // Firestore document ID
  final String title;
  final String? description;
  final String priority; // high, medium, low
  final String status; // in_progress, completed
  @JsonKey(name: 'creator_id')
  final String creatorId;
  @JsonKey(name: 'completer_id')
  final String? completerId;
  @JsonKey(name: 'created_date')
  final String createdDate;
  @JsonKey(name: 'deadline_date')
  final String deadlineDate;
  @JsonKey(name: 'completed_date')
  final String? completedDate;
  @JsonKey(name: 'creator_name')
  final String? creatorName;
  @JsonKey(name: 'completer_name')
  final String? completerName;
  @JsonKey(name: 'worker_ids')
  final List<String> workerIds;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.creatorId,
    this.completerId,
    required this.createdDate,
    required this.deadlineDate,
    this.completedDate,
    this.creatorName,
    this.completerName,
    required this.workerIds,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  // Firestore에서 읽을 때 사용
  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'],
      priority: data['priority'] ?? 'low',
      status: data['status'] ?? 'in_progress',
      creatorId: data['creator_id'] ?? '',
      completerId: data['completer_id'],
      createdDate: data['created_date'] ?? '',
      deadlineDate: data['deadline_date'] ?? '',
      completedDate: data['completed_date'],
      creatorName: data['creator_name'],
      completerName: data['completer_name'],
      workerIds: List<String>.from(data['worker_ids'] ?? []),
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'creator_id': creatorId,
      'completer_id': completerId,
      'created_date': createdDate,
      'deadline_date': deadlineDate,
      'completed_date': completedDate,
      'creator_name': creatorName,
      'completer_name': completerName,
      'worker_ids': workerIds,
    };
  }
}

@JsonSerializable()
class CreateTaskRequest {
  final String title;
  final String? description;
  final String priority;
  @JsonKey(name: 'deadline_date')
  final String deadlineDate;
  @JsonKey(name: 'worker_ids')
  final List<String> workerIds;

  CreateTaskRequest({
    required this.title,
    this.description,
    required this.priority,
    required this.deadlineDate,
    required this.workerIds,
  });

  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTaskRequestToJson(this);
}

@JsonSerializable()
class UpdateTaskRequest {
  final String title;
  final String? description;
  final String priority;
  @JsonKey(name: 'deadline_date')
  final String deadlineDate;
  final String status;
  @JsonKey(name: 'worker_ids')
  final List<String> workerIds;

  UpdateTaskRequest({
    required this.title,
    this.description,
    required this.priority,
    required this.deadlineDate,
    required this.status,
    required this.workerIds,
  });

  factory UpdateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTaskRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateTaskRequestToJson(this);
}

@JsonSerializable()
class TaskResponse {
  final String message;
  final int? taskId;

  TaskResponse({
    required this.message,
    this.taskId,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) =>
      _$TaskResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TaskResponseToJson(this);
}

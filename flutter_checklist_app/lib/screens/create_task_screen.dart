import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/user.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();

  String _priority = 'medium';
  final List<String> _selectedWorkerIds = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectWorkers() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final users = taskProvider.users;

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 목록을 불러오는 중입니다')),
      );
      return;
    }

    final List<String>? selected = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return _WorkerSelectionDialog(
          users: users,
          initialSelected: _selectedWorkerIds,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedWorkerIds.clear();
        _selectedWorkerIds.addAll(selected);
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadlineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마감일을 선택해주세요')),
      );
      return;
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.createTask(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      deadlineDate: _deadlineController.text,
      workerIds: _selectedWorkerIds,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작업이 생성되었습니다')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? '작업 생성 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final selectedWorkers = taskProvider.users
        .where((user) => _selectedWorkerIds.contains(user.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 작업 만들기'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '작업 제목 *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Priority selector
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: '우선순위 *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('높음')),
                  DropdownMenuItem(value: 'medium', child: Text('중간')),
                  DropdownMenuItem(value: 'low', child: Text('낮음')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Deadline field
              TextFormField(
                controller: _deadlineController,
                decoration: const InputDecoration(
                  labelText: '마감일 *',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              // Workers selector
              Card(
                child: ListTile(
                  title: const Text('작업자 선택'),
                  subtitle: selectedWorkers.isEmpty
                      ? const Text('작업자를 선택해주세요')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedWorkers
                              .map((worker) => Chip(
                                    label: Text(worker.name),
                                    avatar: CircleAvatar(
                                      child: Text(worker.name[0]),
                                    ),
                                  ))
                              .toList(),
                        ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectWorkers,
                ),
              ),
              const SizedBox(height: 24),

              // Create button
              ElevatedButton(
                onPressed: taskProvider.isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: taskProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('작업 생성', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerSelectionDialog extends StatefulWidget {
  final List<User> users;
  final List<String> initialSelected;

  const _WorkerSelectionDialog({
    required this.users,
    required this.initialSelected,
  });

  @override
  State<_WorkerSelectionDialog> createState() => _WorkerSelectionDialogState();
}

class _WorkerSelectionDialogState extends State<_WorkerSelectionDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('작업자 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.users.length,
          itemBuilder: (context, index) {
            final user = widget.users[index];
            final isSelected = _selected.contains(user.id);

            return CheckboxListTile(
              title: Text(user.name),
              subtitle: Text(user.phone),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true && user.id != null) {
                    _selected.add(user.id!);
                  } else if (user.id != null) {
                    _selected.remove(user.id!);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

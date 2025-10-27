import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../providers/task_provider.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _deadlineController;

  late String _priority;
  late final List<String> _selectedWorkerIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _deadlineController = TextEditingController(text: widget.task.deadlineDate);
    _priority = widget.task.priority;
    _selectedWorkerIds = List<String>.from(widget.task.workerIds);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _selectWorkers() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.fetchUsers();

    final users = taskProvider.users;
    if (users.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자가 없습니다')),
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

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadlineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마감일을 선택해주세요')),
      );
      return;
    }

    if (widget.task.id == null) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.updateTask(
      id: widget.task.id!,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      priority: _priority,
      deadlineDate: _deadlineController.text,
      workerIds: _selectedWorkerIds,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작업이 수정되었습니다')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? '작업 수정 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(widget.task.deadlineDate) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
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
        title: const Text('작업 수정'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: '우선순위',
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
            TextFormField(
              controller: _deadlineController,
              decoration: const InputDecoration(
                labelText: '마감일',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '마감일을 선택해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectWorkers,
              icon: const Icon(Icons.person_add),
              label: Text('담당자 선택 (${_selectedWorkerIds.length}명)'),
            ),
            if (selectedWorkers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedWorkers.map((worker) {
                  return Chip(
                    label: Text(worker.name),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedWorkerIds.remove(worker.id);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: taskProvider.isLoading ? null : _handleUpdate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: taskProvider.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('수정하기', style: TextStyle(fontSize: 16)),
            ),
          ],
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
    _selected = List<String>.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('담당자 선택'),
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

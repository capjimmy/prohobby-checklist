import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'create_task_screen.dart';
import 'edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch initial data
    Future.microtask(() {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.fetchTasks();
      taskProvider.fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _refreshTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            const Text('협업 체크리스트'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '진행중'),
            Tab(text: '완료'),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final inProgressTasks = taskProvider.getTasksByStatus('in_progress');
          final completedTasks = taskProvider.getTasksByStatus('completed');

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(inProgressTasks, 'in_progress'),
              _buildTaskList(completedTasks, 'completed'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
          );
          if (result == true) {
            _refreshTasks();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('새 작업'),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String status) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'in_progress' ? Icons.inbox : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              status == 'in_progress' ? '진행중인 작업이 없습니다' : '완료된 작업이 없습니다',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return TaskCard(
            task: tasks[index],
            onRefresh: _refreshTasks,
          );
        },
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onRefresh;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onRefresh,
  }) : super(key: key);

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText() {
    switch (task.priority) {
      case 'high':
        return '높음';
      case 'medium':
        return '중간';
      case 'low':
        return '낮음';
      default:
        return task.priority;
    }
  }

  Future<void> _handleComplete(BuildContext context) async {
    if (task.id == null) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.completeTask(task.id!);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작업을 완료했습니다')),
      );
      onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? '작업 완료 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleUncomplete(BuildContext context) async {
    if (task.id == null) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.uncompleteTask(task.id!);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('완료를 취소했습니다')),
      );
      onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? '완료 취소 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
    );
    if (result == true) {
      onRefresh();
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    // 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('작업 삭제'),
          content: const Text('정말로 이 작업을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || task.id == null) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.deleteTask(task.id!);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작업을 삭제했습니다')),
      );
      onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? '작업 삭제 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showWorkerList(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final users = taskProvider.users;
    final workers = users.where((u) => task.workerIds.contains(u.id)).toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('담당자 목록'),
          content: workers.isEmpty
              ? const Text('담당자가 없습니다')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(worker.name[0]),
                        ),
                        title: Text(worker.name),
                        subtitle: Text(worker.phone),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 전화하기 버튼
                            ElevatedButton.icon(
                              onPressed: () async {
                                final phoneNumber = worker.phone.replaceAll(RegExp(r'[^0-9]'), '');
                                final uri = Uri(scheme: 'tel', path: phoneNumber);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('전화를 걸 수 없습니다'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('전화하기!'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 독촉하기 버튼
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (task.id == null || worker.id == null) return;
                                final success = await taskProvider.nudgeWorker(
                                  task.id!,
                                  worker.id!,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? '${worker.name}님에게 독촉했습니다!'
                                            : '독촉 실패',
                                      ),
                                      backgroundColor:
                                          success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.notifications_active, size: 18),
                              label: const Text('독촉하기!'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDescriptionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task.title),
          content: SingleChildScrollView(
            child: Text(task.description ?? '설명이 없습니다'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isCreator = currentUserId == task.creatorId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Priority
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getPriorityColor()),
                  ),
                  child: Text(
                    _getPriorityText(),
                    style: TextStyle(
                      color: _getPriorityColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Description (최대 2줄, 클릭시 팝업)
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => _showDescriptionDialog(context),
                  child: Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Info
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.creatorName ?? '알 수 없음',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.deadlineDate,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            // Workers (담당자 - 클릭시 팝업)
            if (task.workerIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => _showWorkerList(context),
                  child: Chip(
                    label: Text('담당자 ${task.workerIds.length}명'),
                    avatar: const Icon(Icons.person, size: 18),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ),

            // Date information (작업 생성일 & 완료일)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '생성: ${task.createdDate}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (task.completedDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      '완료: ${task.completedDate}',
                      style: TextStyle(fontSize: 12, color: Colors.green[600]),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 삭제 버튼 (작성자만)
                if (isCreator)
                  TextButton.icon(
                    onPressed: () => _handleDelete(context),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('삭제'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // 오른쪽 액션 버튼들
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 진행중인 작업: 완료 버튼 + (작성자면) 수정 버튼
                    if (task.status == 'in_progress') ...[
                      if (isCreator)
                        OutlinedButton.icon(
                          onPressed: () => _handleEdit(context),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('수정'),
                        ),
                      if (isCreator) const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handleComplete(context),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('완료'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                    // 완료된 작업: 완료취소 버튼
                    if (task.status == 'completed')
                      OutlinedButton.icon(
                        onPressed: () => _handleUncomplete(context),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('완료 취소'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

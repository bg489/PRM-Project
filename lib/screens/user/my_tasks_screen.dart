import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_users.dart';
import '../../services/app_data_service.dart';
import '../task/task_detail_screen.dart';
import 'user_approval_requests_screen.dart';

class MyTasksScreen extends StatefulWidget {
  final MockUser user;

  const MyTasksScreen({
    super.key,
    required this.user,
  });

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  List<MockTask> myTasks = const [];
  String selectedStatus = 'all';
  String selectedPriority = 'all';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMyTasks();
  }

  Future<void> loadMyTasks() async {
    try {
      final fetchedTasks = await AppDataService.fetchTasks(
        assigneeId: widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        myTasks = fetchedTasks;
        isLoading = false;
      });
    } catch (_) {
      final assignedTasks = mockTasks.where((task) {
        return task.assigneeName == widget.user.fullName ||
            task.assigneeAvatar == widget.user.avatarText;
      }).toList();
      if (!mounted) return;
      setState(() {
        myTasks = assignedTasks.isNotEmpty
            ? assignedTasks
            : mockTasks.where((task) => task.status != 'Đã xong').take(5).toList();
        isLoading = false;
      });
    }
  }

  List<MockTask> get filteredTasks {
    return myTasks.where((task) {
      final statusOk = selectedStatus == 'all' || task.status == selectedStatus;
      final priorityOk =
          selectedPriority == 'all' || task.priority == selectedPriority;
      return statusOk && priorityOk;
    }).toList();
  }

  int get completedTasks {
    return myTasks.where((task) => task.status == 'Đã xong').length;
  }

  Future<void> updateTaskStatus(MockTask task, String newStatus) async {
    final previousTasks = List<MockTask>.from(myTasks);
    setState(() {
      myTasks = myTasks.map((item) {
        return item.id == task.id ? item.copyWith(status: newStatus) : item;
      }).toList();
    });

    try {
      final updatedTask = await AppDataService.updateTaskStatus(
        taskId: task.id,
        status: newStatus,
      );
      if (!mounted) return;
      setState(() {
        myTasks = myTasks.map((item) {
          return item.id == updatedTask.id ? updatedTask : item;
        }).toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        myTasks = previousTasks;
      });
      showMessage('Không thể cập nhật trạng thái: $error');
    }
  }

  void openTaskDetail(MockTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          task: task,
          currentUser: widget.user,
        ),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final visibleTasks = filteredTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('Task của ${widget.user.fullName}'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserApprovalRequestsScreen(user: widget.user),
                ),
              );
            },
            icon: const Icon(Icons.fact_check_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadMyTasks,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StatsCard(
              totalTasks: myTasks.length,
              completedTasks: completedTasks,
              highPriorityTasks:
                  myTasks.where((task) => task.priority == 'High').length,
            ),
            const SizedBox(height: 16),
            _FilterCard(
              selectedStatus: selectedStatus,
              selectedPriority: selectedPriority,
              onStatusChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
              onPriorityChanged: (value) {
                setState(() {
                  selectedPriority = value;
                });
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Task của tôi',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${visibleTasks.length} task',
                  style: const TextStyle(
                    color: Color(0xFF6D28D9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visibleTasks.isEmpty)
              const _EmptyState()
            else
              ...visibleTasks.map((task) {
                return _TaskTile(
                  task: task,
                  onTap: () => openTaskDetail(task),
                  onStatusChanged: (status) => updateTaskStatus(task, status),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int highPriorityTasks;

  const _StatsCard({
    required this.totalTasks,
    required this.completedTasks,
    required this.highPriorityTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _StatItem(label: 'Tổng', value: totalTasks),
          _StatItem(label: 'Đã xong', value: completedTasks),
          _StatItem(label: 'Ưu tiên cao', value: highPriorityTasks),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final String selectedStatus;
  final String selectedPriority;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;

  const _FilterCard({
    required this.selectedStatus,
    required this.selectedPriority,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: _inputDecoration('Trạng thái'),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả')),
              ...kanbanColumns.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }),
            ],
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedPriority,
            decoration: _inputDecoration('Priority'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
              DropdownMenuItem(value: 'High', child: Text('Cao')),
              DropdownMenuItem(value: 'Medium', child: Text('Trung bình')),
              DropdownMenuItem(value: 'Low', child: Text('Thấp')),
            ],
            onChanged: (value) {
              if (value != null) onPriorityChanged(value);
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final MockTask task;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusChanged;

  const _TaskTile({
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        task.checklistTotal == 0 ? 0.0 : task.checklistDone / task.checklistTotal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  task.priority,
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: task.status,
              decoration: const InputDecoration(labelText: 'Trạng thái'),
              items: kanbanColumns.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                if (value != null) onStatusChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          'Không có task nào phù hợp bộ lọc',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ],
  );
}

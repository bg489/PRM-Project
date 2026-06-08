import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_users.dart';
import '../task/task_detail_screen.dart';

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
  late List<MockTask> myTasks;

  String selectedStatus = 'Tất cả';
  String selectedPriority = 'all';

  @override
  void initState() {
    super.initState();

    final assignedTasks = mockTasks.where((task) {
      return task.assigneeName == widget.user.fullName ||
          task.assigneeAvatar == widget.user.avatarText;
    }).toList();

    // Nếu user hiện tại chưa có task trùng tên/avatar trong mock data,
    // mình cho hiện task mẫu để demo màn "Task của tôi".
    myTasks = assignedTasks.isNotEmpty
        ? assignedTasks
        : mockTasks
        .where((task) => task.status != 'Đã xong')
        .take(5)
        .toList();
  }

  List<MockTask> get filteredTasks {
    return myTasks.where((task) {
      final matchStatus =
          selectedStatus == 'Tất cả' || task.status == selectedStatus;

      final matchPriority =
          selectedPriority == 'all' || task.priority == selectedPriority;

      return matchStatus && matchPriority;
    }).toList();
  }

  int get totalTasks => myTasks.length;

  int get completedTasks {
    return myTasks.where((task) => task.status == 'Đã xong').length;
  }

  int get pendingTasks {
    return myTasks.where((task) => task.status != 'Đã xong').length;
  }

  int get highPriorityTasks {
    return myTasks.where((task) => task.priority == 'High').length;
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

  void updateTaskStatus(MockTask task, String newStatus) {
    setState(() {
      myTasks = myTasks.map((item) {
        if (item.id == task.id) {
          return item.copyWith(status: newStatus);
        }
        return item;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chuyển "${task.title}" sang "$newStatus"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = filteredTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              user: widget.user,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverviewPanel(
                      totalTasks: totalTasks,
                      completedTasks: completedTasks,
                      pendingTasks: pendingTasks,
                      highPriorityTasks: highPriorityTasks,
                    ),

                    const SizedBox(height: 18),

                    _FilterPanel(
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

                    const SizedBox(height: 20),

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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${visibleTasks.length} task',
                            style: const TextStyle(
                              color: Color(0xFF6D28D9),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Danh sách công việc được giao cho bạn trong các project.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (visibleTasks.isEmpty)
                      const _EmptyTaskList()
                    else
                      ...visibleTasks.map((task) {
                        return _MyTaskCard(
                          task: task,
                          onTap: () => openTaskDetail(task),
                          onStatusChanged: (status) {
                            updateTaskStatus(task, status);
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MockUser user;
  final VoidCallback onBack;

  const _Header({
    required this.user,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Công việc cá nhân',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              user.avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int highPriorityTasks;

  const _OverviewPanel({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.highPriorityTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.assignment_ind_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tổng quan task của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Tổng',
                  value: '$totalTasks',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Đã xong',
                  value: '$completedTasks',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Đang chờ',
                  value: '$pendingTasks',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Ưu tiên cao',
                  value: '$highPriorityTasks',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewMiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final String selectedStatus;
  final String selectedPriority;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;

  const _FilterPanel({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: Color(0xFF7C3AED),
              ),
              SizedBox(width: 8),
              Text(
                'Bộ lọc task',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: _inputDecoration(
              hintText: 'Lọc theo trạng thái',
              icon: Icons.view_kanban_outlined,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Tất cả',
                child: Text('Tất cả trạng thái'),
              ),
              DropdownMenuItem(
                value: 'Cần làm',
                child: Text('Cần làm'),
              ),
              DropdownMenuItem(
                value: 'Đang làm',
                child: Text('Đang làm'),
              ),
              DropdownMenuItem(
                value: 'Kiểm tra',
                child: Text('Kiểm tra'),
              ),
              DropdownMenuItem(
                value: 'Đã xong',
                child: Text('Đã xong'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onStatusChanged(value);
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedPriority,
            decoration: _inputDecoration(
              hintText: 'Lọc theo ưu tiên',
              icon: Icons.flag_outlined,
            ),
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả priority'),
              ),
              DropdownMenuItem(
                value: 'High',
                child: Text('Cao'),
              ),
              DropdownMenuItem(
                value: 'Medium',
                child: Text('Trung bình'),
              ),
              DropdownMenuItem(
                value: 'Low',
                child: Text('Thấp'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onPriorityChanged(value);
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _MyTaskCard extends StatelessWidget {
  final MockTask task;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusChanged;

  const _MyTaskCard({
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final priorityConfig = _priorityConfig(task.priority);

    final checklistProgress =
    task.checklistTotal == 0 ? 0.0 : task.checklistDone / task.checklistTotal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PriorityBadge(
                  label: priorityConfig.label,
                  color: priorityConfig.color,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    task.status,
                    style: const TextStyle(
                      color: Color(0xFF6D28D9),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              task.title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                _SmallInfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Hạn: ${task.dueDate}',
                ),
                const SizedBox(width: 8),
                _SmallInfoChip(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${task.commentCount} bình luận',
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  '${task.checklistDone}/${task.checklistTotal}',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: checklistProgress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: task.status,
              decoration: InputDecoration(
                labelText: 'Cập nhật trạng thái',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: kanbanColumns.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                onStatusChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  _PriorityConfig _priorityConfig(String priority) {
    switch (priority) {
      case 'High':
        return _PriorityConfig('Cao', const Color(0xFFEF4444));
      case 'Medium':
        return _PriorityConfig('Trung bình', const Color(0xFFF59E0B));
      default:
        return _PriorityConfig('Thấp', const Color(0xFF22C55E));
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTaskList extends StatelessWidget {
  const _EmptyTaskList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 46,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Không có task nào phù hợp bộ lọc',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityConfig {
  final String label;
  final Color color;

  _PriorityConfig(this.label, this.color);
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ],
  );
}
import 'package:flutter/material.dart';

import '../../data/mock_notifications.dart';
import '../../data/mock_users.dart';
import '../../services/app_data_service.dart';
import '../task/task_detail_screen.dart';

class UserNotificationsScreen extends StatefulWidget {
  final MockUser user;

  const UserNotificationsScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  List<MockUserNotification> notifications = const [];
  String selectedFilter = 'all';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final fetchedNotifications = await AppDataService.fetchNotifications(
        userId: widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        notifications = fetchedNotifications;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        notifications = mockUserNotifications
            .where((notification) => notification.targetUserId == widget.user.id)
            .toList();
        isLoading = false;
      });
    }
  }

  List<MockUserNotification> get filteredNotifications {
    return notifications.where((notification) {
      if (selectedFilter == 'all') return true;
      if (selectedFilter == 'unread') return !notification.isRead;
      return notification.type == selectedFilter;
    }).toList();
  }

  int get unreadCount {
    return notifications.where((notification) => !notification.isRead).length;
  }

  Future<void> markAsRead(MockUserNotification notification) async {
    setState(() {
      notifications = notifications.map((item) {
        return item.id == notification.id ? item.copyWith(isRead: true) : item;
      }).toList();
    });

    try {
      await AppDataService.markNotificationRead(notification.id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final unreadNotifications =
        notifications.where((notification) => !notification.isRead).toList();
    setState(() {
      notifications = notifications.map((item) {
        return item.copyWith(isRead: true);
      }).toList();
    });
    for (final notification in unreadNotifications) {
      try {
        await AppDataService.markNotificationRead(notification.id);
      } catch (_) {}
    }
  }

  Future<void> deleteNotification(MockUserNotification notification) async {
    setState(() {
      notifications = notifications
          .where((item) => item.id != notification.id)
          .toList();
    });

    try {
      await AppDataService.deleteNotification(notification.id);
    } catch (error) {
      showMessage('Không thể xóa thông báo: $error');
    }
  }

  Future<void> openNotification(MockUserNotification notification) async {
    await markAsRead(notification);

    if (notification.taskId == null) {
      showMessage('Thông báo này không liên kết với task cụ thể');
      return;
    }

    try {
      final detail = await AppDataService.fetchTaskDetail(notification.taskId!);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            task: detail.task,
            currentUser: widget.user,
          ),
        ),
      );
    } catch (error) {
      showMessage('Không thể mở task liên quan: $error');
    }
  }

  void showNotificationDetail(MockUserNotification notification) {
    markAsRead(notification);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(notification.message),
              const SizedBox(height: 14),
              Text(
                notification.createdAt,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              if (notification.taskId != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      openNotification(notification);
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Mở task liên quan'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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

    final visibleNotifications = filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text('Thông báo ($unreadCount chưa đọc)'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: unreadCount == 0 ? null : markAllAsRead,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _FilterChips(
              selectedFilter: selectedFilter,
              onChanged: (value) {
                setState(() {
                  selectedFilter = value;
                });
              },
            ),
            const SizedBox(height: 18),
            if (visibleNotifications.isEmpty)
              const _EmptyState()
            else
              ...visibleNotifications.map((notification) {
                final config = _notificationConfig(notification.type);
                return _NotificationTile(
                  notification: notification,
                  icon: config.icon,
                  color: config.color,
                  label: config.label,
                  onTap: () => showNotificationDetail(notification),
                  onOpenTask: notification.taskId == null
                      ? null
                      : () => openNotification(notification),
                  onDelete: () => deleteNotification(notification),
                );
              }),
          ],
        ),
      ),
    );
  }

  _NotificationConfig _notificationConfig(String type) {
    switch (type) {
      case 'TASK_ASSIGNED':
        return _NotificationConfig(
          label: 'Giao task',
          color: const Color(0xFF2563EB),
          icon: Icons.assignment_ind_rounded,
        );
      case 'COMMENT_ADDED':
        return _NotificationConfig(
          label: 'Bình luận',
          color: const Color(0xFF7C3AED),
          icon: Icons.chat_bubble_outline_rounded,
        );
      case 'DEADLINE_REMINDER':
        return _NotificationConfig(
          label: 'Deadline',
          color: const Color(0xFFF59E0B),
          icon: Icons.event_busy_rounded,
        );
      case 'APPROVAL_APPROVED':
        return _NotificationConfig(
          label: 'Đã duyệt',
          color: const Color(0xFF22C55E),
          icon: Icons.check_circle_rounded,
        );
      case 'APPROVAL_REJECTED':
        return _NotificationConfig(
          label: 'Từ chối',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
        );
      default:
        return _NotificationConfig(
          label: 'Hệ thống',
          color: const Color(0xFF6B7280),
          icon: Icons.notifications_none_rounded,
        );
    }
  }
}

class _FilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _FilterChips({
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterOption('all', 'Tất cả'),
      _FilterOption('unread', 'Chưa đọc'),
      _FilterOption('TASK_ASSIGNED', 'Giao task'),
      _FilterOption('COMMENT_ADDED', 'Bình luận'),
      _FilterOption('DEADLINE_REMINDER', 'Deadline'),
      _FilterOption('APPROVAL_APPROVED', 'Đã duyệt'),
      _FilterOption('APPROVAL_REJECTED', 'Từ chối'),
      _FilterOption('SYSTEM', 'Hệ thống'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selectedFilter == filter.value,
              label: Text(filter.label),
              onSelected: (_) => onChanged(filter.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final MockUserNotification notification;
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onOpenTask;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    required this.onOpenTask,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  notification.createdAt,
                  style: const TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              notification.title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onOpenTask != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenTask,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Mở task'),
                    ),
                  ),
                if (onOpenTask != null) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa'),
                  ),
                ),
              ],
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Không có thông báo nào phù hợp'),
      ),
    );
  }
}

class _FilterOption {
  final String value;
  final String label;

  _FilterOption(this.value, this.label);
}

class _NotificationConfig {
  final String label;
  final Color color;
  final IconData icon;

  _NotificationConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}

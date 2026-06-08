import 'package:flutter/material.dart';

import '../../data/mock_notifications.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_users.dart';
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
  late List<MockUserNotification> notifications;

  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();

    notifications = mockUserNotifications
        .where((notification) => notification.targetUserId == widget.user.id)
        .toList();
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

  int get taskNotificationCount {
    return notifications.where((notification) {
      return notification.type == 'TASK_ASSIGNED' ||
          notification.type == 'COMMENT_ADDED' ||
          notification.type == 'DEADLINE_REMINDER';
    }).length;
  }

  int get approvalNotificationCount {
    return notifications.where((notification) {
      return notification.type == 'APPROVAL_APPROVED' ||
          notification.type == 'APPROVAL_REJECTED';
    }).length;
  }

  void markAsRead(MockUserNotification notification) {
    setState(() {
      notifications = notifications.map((item) {
        if (item.id == notification.id) {
          return item.copyWith(isRead: true);
        }

        return item;
      }).toList();
    });
  }

  void markAllAsRead() {
    setState(() {
      notifications = notifications.map((item) {
        return item.copyWith(isRead: true);
      }).toList();
    });

    showMessage('Đã đánh dấu tất cả là đã đọc');
  }

  void deleteNotification(MockUserNotification notification) {
    setState(() {
      notifications.removeWhere((item) => item.id == notification.id);
    });

    showMessage('Đã xóa thông báo mock');
  }

  void openNotification(MockUserNotification notification) {
    markAsRead(notification);

    if (notification.taskId == null) {
      showMessage('Thông báo này không liên kết với task cụ thể');
      return;
    }

    try {
      final task = mockTasks.firstWhere(
            (task) => task.id == notification.taskId,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            task: task,
            currentUser: widget.user,
          ),
        ),
      );
    } catch (_) {
      showMessage('Không tìm thấy task liên quan trong mock data');
    }
  }

  void showNotificationDetail(MockUserNotification notification) {
    final config = _getNotificationConfig(notification.type);

    markAsRead(notification);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.38,
          maxChildSize: 0.86,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: config.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        config.icon,
                        color: config.color,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      notification.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _TypeBadge(
                      label: config.label,
                      color: config.color,
                    ),

                    const SizedBox(height: 20),

                    _DetailBlock(
                      icon: Icons.message_outlined,
                      title: 'Nội dung',
                      content: notification.message,
                    ),

                    const SizedBox(height: 12),

                    _DetailBlock(
                      icon: Icons.access_time_rounded,
                      title: 'Thời gian',
                      content: notification.createdAt,
                    ),

                    const SizedBox(height: 12),

                    _DetailBlock(
                      icon: Icons.info_outline_rounded,
                      title: 'Trạng thái',
                      content:
                      notification.isRead ? 'Đã đọc' : 'Chưa đọc',
                    ),

                    if (notification.taskId != null) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            openNotification(notification);
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Mở task liên quan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
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

  _NotificationConfig _getNotificationConfig(String type) {
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
          label: 'Bị từ chối',
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

  @override
  Widget build(BuildContext context) {
    final visibleNotifications = filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              user: widget.user,
              unreadCount: unreadCount,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverviewPanel(
                      total: notifications.length,
                      unread: unreadCount,
                      taskCount: taskNotificationCount,
                      approvalCount: approvalNotificationCount,
                    ),

                    const SizedBox(height: 18),

                    _FilterChips(
                      selectedFilter: selectedFilter,
                      onChanged: (value) {
                        setState(() {
                          selectedFilter = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Thông báo của tôi',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: unreadCount == 0 ? null : markAllAsRead,
                          icon: const Icon(Icons.done_all_rounded),
                          label: const Text('Đọc hết'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Theo dõi task được giao, bình luận, deadline và trạng thái duyệt requirement.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (visibleNotifications.isEmpty)
                      const _EmptyNotificationList()
                    else
                      ...visibleNotifications.map((notification) {
                        final config =
                        _getNotificationConfig(notification.type);

                        return _NotificationCard(
                          notification: notification,
                          config: config,
                          onTap: () => showNotificationDetail(notification),
                          onOpenTask: () => openNotification(notification),
                          onDelete: () => deleteNotification(notification),
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
  final int unreadCount;
  final VoidCallback onBack;

  const _Header({
    required this.user,
    required this.unreadCount,
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
                  'Trung tâm thông báo',
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final int total;
  final int unread;
  final int taskCount;
  final int approvalCount;

  const _OverviewPanel({
    required this.total,
    required this.unread,
    required this.taskCount,
    required this.approvalCount,
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
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tổng quan thông báo',
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
                  value: '$total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Chưa đọc',
                  value: '$unread',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Task',
                  value: '$taskCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Duyệt',
                  value: '$approvalCount',
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
          final isSelected = selectedFilter == filter.value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(filter.label),
              selectedColor: const Color(0xFFEDE9FE),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFF6D28D9)
                    : const Color(0xFF374151),
                fontWeight: FontWeight.w800,
              ),
              onSelected: (_) => onChanged(filter.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final MockUserNotification notification;
  final _NotificationConfig config;
  final VoidCallback onTap;
  final VoidCallback onOpenTask;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.config,
    required this.onTap,
    required this.onOpenTask,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : const Color(0xFFFDE68A),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: config.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        config.icon,
                        color: config.color,
                      ),
                    ),
                    if (!notification.isRead)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TypeBadge(
                            label: config.label,
                            color: config.color,
                          ),
                          const Spacer(),
                          Text(
                            notification.createdAt,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        notification.title,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                if (notification.taskId != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenTask,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Mở task'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(
                          color: Color(0xFFBFDBFE),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                if (notification.taskId != null) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(
                        color: Color(0xFFFECACA),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
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

class _DetailBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _DetailBlock({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationList extends StatelessWidget {
  const _EmptyNotificationList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 46,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Không có thông báo nào phù hợp',
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
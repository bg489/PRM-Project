import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';
import '../../data/mock_users.dart';
import '../../utils/app_navigation.dart';

class ProductivityAnalyticsScreen extends StatelessWidget {
  final MockUser user;
  final MockProject project;
  final List<MockTask> tasks;

  const ProductivityAnalyticsScreen({
    super.key,
    required this.user,
    required this.project,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _AnalyticsStats.fromTasks(tasks);
    final memberStats = _buildMemberStats(tasks);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: _AnalyticsBottomNavBar(
        user: user,
        project: project,
        tasks: tasks,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _AnalyticsHeader(
              projectName: project.name,
              projectCode: project.code,
              completionRate: stats.completionRate,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Báo cáo hiệu suất',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Theo dõi tình trạng công việc và năng suất đội nhóm',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.45,
                      children: [
                        _SummaryCard(
                          title: 'Tổng task',
                          value: '${stats.total}',
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        _SummaryCard(
                          title: 'Đã xong',
                          value: '${stats.done}',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                        _SummaryCard(
                          title: 'Trễ hạn',
                          value: '${stats.late}',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        _SummaryCard(
                          title: 'Đang làm',
                          value: '${stats.inProgress}',
                          icon: Icons.timelapse_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Tỷ lệ trạng thái công việc',
                      icon: Icons.pie_chart_rounded,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 210,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Center(
                                    child: CustomPaint(
                                      size: const Size(170, 170),
                                      painter: _PieChartPainter(
                                        done: stats.done,
                                        inProgress: stats.inProgress,
                                        late: stats.late,
                                        todo: stats.todo,
                                      ),
                                      child: SizedBox(
                                        width: 170,
                                        height: 170,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${stats.completionRate}%',
                                                style: const TextStyle(
                                                  color: Color(0xFF111827),
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const Text(
                                                'Hoàn thành',
                                                style: TextStyle(
                                                  color: Color(0xFF6B7280),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _LegendRow(
                                        label: 'Đã xong',
                                        value: stats.done,
                                        color: const Color(0xFF22C55E),
                                      ),
                                      _LegendRow(
                                        label: 'Đang làm',
                                        value: stats.inProgress,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                      _LegendRow(
                                        label: 'Trễ hạn',
                                        value: stats.late,
                                        color: const Color(0xFFEF4444),
                                      ),
                                      _LegendRow(
                                        label: 'Cần làm',
                                        value: stats.todo,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Task hoàn thành theo tuần',
                      icon: Icons.bar_chart_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Biểu đồ mô phỏng số lượng task hoàn thành theo từng tuần trong tháng 6.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _WeeklyBarChart(
                            values: [4, 7, 5, 9],
                            labels: ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Hiệu suất thành viên',
                      icon: Icons.groups_rounded,
                      child: Column(
                        children: memberStats.map((member) {
                          return _MemberPerformanceCard(member: member);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MemberStat> _buildMemberStats(List<MockTask> tasks) {
    final Map<String, List<MockTask>> grouped = {};

    for (final task in tasks) {
      grouped.putIfAbsent(task.assigneeName, () => []);
      grouped[task.assigneeName]!.add(task);
    }

    return grouped.entries.map((entry) {
      final memberTasks = entry.value;
      final done = memberTasks.where((task) => task.status == 'Đã xong').length;
      final high = memberTasks.where((task) => task.priority == 'High').length;
      final avatar = memberTasks.first.assigneeAvatar;

      return _MemberStat(
        name: entry.key,
        avatar: avatar,
        total: memberTasks.length,
        done: done,
        highPriority: high,
      );
    }).toList();
  }
}

class _AnalyticsHeader extends StatelessWidget {
  final String projectName;
  final String projectCode;
  final int completionRate;
  final VoidCallback onBack;

  const _AnalyticsHeader({
    required this.projectName,
    required this.projectCode,
    required this.completionRate,
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
      child: Column(
        children: [
          Row(
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
                    Text(
                      projectCode,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      projectName,
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tỷ lệ hoàn thành dự án',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completionRate%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Cập nhật\nhôm nay',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white70,
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _LegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final int done;
  final int inProgress;
  final int late;
  final int todo;

  _PieChartPainter({
    required this.done,
    required this.inProgress,
    required this.late,
    required this.todo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = done + inProgress + late + todo;

    if (total == 0) return;

    final rect = Offset.zero & size;
    double startAngle = -math.pi / 2;

    void drawSegment(int value, Color color) {
      if (value <= 0) return;

      final sweepAngle = (value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect.deflate(22),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    drawSegment(done, const Color(0xFF22C55E));
    drawSegment(inProgress, const Color(0xFFF59E0B));
    drawSegment(late, const Color(0xFFEF4444));
    drawSegment(todo, const Color(0xFF64748B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WeeklyBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;

  const _WeeklyBarChart({
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce(math.max);

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final value = values[index];
          final ratio = value / maxValue;
          final height = 130 * ratio;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: height,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF9333EA),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    labels[index],
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MemberPerformanceCard extends StatelessWidget {
  final _MemberStat member;

  const _MemberPerformanceCard({
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final progress = member.total == 0 ? 0.0 : member.done / member.total;
    final percent = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF6366F1),
            child: Text(
              member.avatar,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C3AED),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${member.done}/${member.total} task hoàn thành • ${member.highPriority} task ưu tiên cao',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsStats {
  final int total;
  final int done;
  final int inProgress;
  final int late;
  final int todo;
  final int completionRate;

  _AnalyticsStats({
    required this.total,
    required this.done,
    required this.inProgress,
    required this.late,
    required this.todo,
    required this.completionRate,
  });

  factory _AnalyticsStats.fromTasks(List<MockTask> tasks) {
    final total = tasks.length;
    final done = tasks.where((task) => task.status == 'Đã xong').length;
    final inProgress = tasks.where((task) {
      return task.status == 'Đang làm' || task.status == 'Kiểm tra';
    }).length;

    final late = tasks.where((task) {
      final date = _parseTaskDate(task.dueDate);
      final today = DateTime(2026, 6, 17);

      return date.isBefore(today) && task.status != 'Đã xong';
    }).length;

    final todo = tasks.where((task) => task.status == 'Cần làm').length;
    final completionRate = total == 0 ? 0 : ((done / total) * 100).round();

    return _AnalyticsStats(
      total: total,
      done: done,
      inProgress: inProgress,
      late: late,
      todo: todo,
      completionRate: completionRate,
    );
  }

  static DateTime _parseTaskDate(String dueDate) {
    final parts = dueDate.split('/');
    final day = int.tryParse(parts[0]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;

    return DateTime(2026, month, day);
  }
}

class _MemberStat {
  final String name;
  final String avatar;
  final int total;
  final int done;
  final int highPriority;

  _MemberStat({
    required this.name,
    required this.avatar,
    required this.total,
    required this.done,
    required this.highPriority,
  });
}

class _AnalyticsBottomNavBar extends StatelessWidget {
  final MockUser user;
  final MockProject project;
  final List<MockTask> tasks;

  const _AnalyticsBottomNavBar({
    required this.user,
    required this.project,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 3,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEDE9FE),
      onDestinationSelected: (index) {
        if (index == 0) {
          AppNavigation.goHome(context);
        }

        if (index == 1) {
          AppNavigation.goBoard(
            context: context,
            user: user,
            project: project,
          );
        }

        if (index == 2) {
          AppNavigation.goCalendar(
            context: context,
            user: user,
            project: project,
            tasks: tasks,
          );
        }

        if (index == 3) {
          return;
        }

        if (index == 4) {
          AppNavigation.goProfile(
            context: context,
            user: user,
            project: project,
            tasks: tasks,
          );
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Trang chủ'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Bảng'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Lịch'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Phân tích'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Cá nhân'),
      ],
    );
  }
}
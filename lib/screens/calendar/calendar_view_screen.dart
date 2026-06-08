import 'package:flutter/material.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';

class CalendarViewScreen extends StatefulWidget {
  final MockProject project;
  final List<MockTask> tasks;

  const CalendarViewScreen({
    super.key,
    required this.project,
    required this.tasks,
  });

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  late DateTime currentMonth;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();

    currentMonth = DateTime(2026, 6, 1);
    selectedDate = DateTime(2026, 6, 10);
  }

  void goToPreviousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
      selectedDate = DateTime(currentMonth.year, currentMonth.month, 1);
    });
  }

  void goToNextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
      selectedDate = DateTime(currentMonth.year, currentMonth.month, 1);
    });
  }

  List<MockTask> getTasksByDate(DateTime date) {
    return widget.tasks.where((task) {
      final taskDate = parseTaskDate(task.dueDate);
      return taskDate.day == date.day &&
          taskDate.month == date.month &&
          taskDate.year == date.year;
    }).toList();
  }

  List<MockTask> getTasksForDay(int day) {
    return widget.tasks.where((task) {
      final taskDate = parseTaskDate(task.dueDate);
      return taskDate.day == day &&
          taskDate.month == currentMonth.month &&
          taskDate.year == currentMonth.year;
    }).toList();
  }

  DateTime parseTaskDate(String dueDate) {
    final parts = dueDate.split('/');
    final day = int.tryParse(parts[0]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;

    return DateTime(2026, month, day);
  }

  int get daysInMonth {
    return DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
  }

  int get firstWeekdayOfMonth {
    return DateTime(currentMonth.year, currentMonth.month, 1).weekday;
  }

  String get monthTitle {
    final monthNames = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];

    return '${monthNames[currentMonth.month - 1]}, ${currentMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = getTasksByDate(selectedDate);
    final totalDueTasks = widget.tasks.length;
    final highTasks = widget.tasks.where((task) => task.priority == 'High').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: const _CalendarBottomNavBar(),
      body: SafeArea(
        child: Column(
          children: [
            _CalendarHeader(
              projectName: widget.project.name,
              projectCode: widget.project.code,
              totalTasks: totalDueTasks,
              highTasks: highTasks,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MonthController(
                      title: monthTitle,
                      onPrevious: goToPreviousMonth,
                      onNext: goToNextMonth,
                    ),

                    const SizedBox(height: 16),

                    _CalendarCard(
                      daysInMonth: daysInMonth,
                      firstWeekdayOfMonth: firstWeekdayOfMonth,
                      currentMonth: currentMonth,
                      selectedDate: selectedDate,
                      getTasksForDay: getTasksForDay,
                      onDateSelected: (date) {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    const _PriorityLegend(),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Việc cần xong ngày ${formatFullDate(selectedDate)}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
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
                            '${selectedTasks.length} task',
                            style: const TextStyle(
                              color: Color(0xFF6D28D9),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    if (selectedTasks.isEmpty)
                      const _EmptySelectedDate()
                    else
                      ...selectedTasks.map(
                            (task) => _CalendarTaskCard(task: task),
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

  String formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _CalendarHeader extends StatelessWidget {
  final String projectName;
  final String projectCode;
  final int totalTasks;
  final int highTasks;
  final VoidCallback onBack;

  const _CalendarHeader({
    required this.projectName,
    required this.projectCode,
    required this.totalTasks,
    required this.highTasks,
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
                      'Lịch biểu công việc',
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
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderStatCard(
                  label: 'Tổng deadline',
                  value: '$totalTasks',
                  icon: Icons.task_alt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderStatCard(
                  label: 'Ưu tiên cao',
                  value: '$highTasks',
                  icon: Icons.flag_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthController extends StatelessWidget {
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthController({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPrevious,
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        _RoundIconButton(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF7C3AED),
          size: 28,
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final int daysInMonth;
  final int firstWeekdayOfMonth;
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<MockTask> Function(int day) getTasksForDay;
  final void Function(DateTime date) onDateSelected;

  const _CalendarCard({
    required this.daysInMonth,
    required this.firstWeekdayOfMonth,
    required this.currentMonth,
    required this.selectedDate,
    required this.getTasksForDay,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final totalCells = daysInMonth + firstWeekdayOfMonth - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              _WeekdayLabel(label: 'T2'),
              _WeekdayLabel(label: 'T3'),
              _WeekdayLabel(label: 'T4'),
              _WeekdayLabel(label: 'T5'),
              _WeekdayLabel(label: 'T6'),
              _WeekdayLabel(label: 'T7'),
              _WeekdayLabel(label: 'CN'),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - firstWeekdayOfMonth + 2;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(
                currentMonth.year,
                currentMonth.month,
                dayNumber,
              );

              final tasks = getTasksForDay(dayNumber);

              final isSelected = selectedDate.day == dayNumber &&
                  selectedDate.month == currentMonth.month &&
                  selectedDate.year == currentMonth.year;

              return _CalendarDayCell(
                day: dayNumber,
                tasks: tasks,
                isSelected: isSelected,
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final List<MockTask> tasks;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.tasks,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highCount = tasks.where((task) => task.priority == 'High').length;
    final mediumCount = tasks.where((task) => task.priority == 'Medium').length;
    final lowCount = tasks.where((task) => task.priority == 'Low').length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF111827),
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (highCount > 0)
                  const _PriorityDot(color: Color(0xFFEF4444)),
                if (mediumCount > 0)
                  const _PriorityDot(color: Color(0xFFF59E0B)),
                if (lowCount > 0)
                  const _PriorityDot(color: Color(0xFF22C55E)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final Color color;

  const _PriorityDot({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PriorityLegend extends StatelessWidget {
  const _PriorityLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _LegendItem(
            label: 'Cao',
            color: Color(0xFFEF4444),
          ),
          _LegendItem(
            label: 'Trung bình',
            color: Color(0xFFF59E0B),
          ),
          _LegendItem(
            label: 'Thấp',
            color: Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PriorityDot(color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _CalendarTaskCard extends StatelessWidget {
  final MockTask task;

  const _CalendarTaskCard({
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig(task.priority);
    final progress =
    task.checklistTotal == 0 ? 0.0 : task.checklistDone / task.checklistTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            width: 7,
            height: 88,
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        task.assigneeAvatar,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.assigneeName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: config.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        config.label,
                        style: TextStyle(
                          color: config.color,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _PriorityConfig _getPriorityConfig(String priority) {
    switch (priority) {
      case 'High':
        return _PriorityConfig(
          label: 'Cao',
          color: const Color(0xFFEF4444),
        );
      case 'Medium':
        return _PriorityConfig(
          label: 'Trung bình',
          color: const Color(0xFFF59E0B),
        );
      default:
        return _PriorityConfig(
          label: 'Thấp',
          color: const Color(0xFF22C55E),
        );
    }
  }
}

class _PriorityConfig {
  final String label;
  final Color color;

  _PriorityConfig({
    required this.label,
    required this.color,
  });
}

class _EmptySelectedDate extends StatelessWidget {
  const _EmptySelectedDate();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 44,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 10),
          Text(
            'Không có task nào đến hạn trong ngày này',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarBottomNavBar extends StatelessWidget {
  const _CalendarBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 2,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEDE9FE),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Bảng',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Lịch',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Phân tích',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
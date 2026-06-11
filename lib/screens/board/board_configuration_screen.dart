import 'package:flutter/material.dart';

import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';
import '../../services/app_data_service.dart';
import '../admin/admin_widgets.dart';

class BoardConfigurationScreen extends StatefulWidget {
  final MockProject project;
  final List<MockTask> tasks;

  const BoardConfigurationScreen({
    super.key,
    required this.project,
    required this.tasks,
  });

  @override
  State<BoardConfigurationScreen> createState() =>
      _BoardConfigurationScreenState();
}

class _BoardConfigurationScreenState extends State<BoardConfigurationScreen> {
  List<_BoardColumnSetting> columns = const [];
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  int get enabledWipCount {
    return columns.where((column) => column.wipEnabled).length;
  }

  int get exceededCount {
    return columns.where((column) {
      return column.wipEnabled && column.currentCount > column.wipLimit;
    }).length;
  }

  @override
  void initState() {
    super.initState();
    loadColumns();
  }

  Future<void> loadColumns() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedLists = await AppDataService.fetchTaskLists(widget.project.id);
      if (!mounted) return;
      setState(() {
        columns = loadedLists.map(_fromTaskList).toList();
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        columns = kanbanColumns.asMap().entries.map((entry) {
          return _BoardColumnSetting(
            id: 'local_${entry.key}',
            name: entry.value,
            position: entry.key + 1,
            wipLimit: _defaultLimitByColumn(entry.value),
            wipEnabled: entry.value == kanbanColumns[1] ||
                entry.value == kanbanColumns[2],
            currentCount: _taskCount(entry.value),
          );
        }).toList();
        errorMessage = 'Chưa kết nối được backend, đang hiển thị cấu hình dự phòng.';
        isLoading = false;
      });
    }
  }

  _BoardColumnSetting _fromTaskList(TaskListConfig list) {
    return _BoardColumnSetting(
      id: list.id,
      name: list.name,
      position: list.position,
      wipLimit: list.wipLimit ?? _defaultLimitByColumn(list.name),
      wipEnabled: list.isWipEnabled,
      currentCount: _taskCount(list.name),
    );
  }

  int _taskCount(String columnName) {
    return widget.tasks.where((task) => task.status == columnName).length;
  }

  int _defaultLimitByColumn(String columnName) {
    if (columnName == kanbanColumns.first) return 10;
    if (columnName == kanbanColumns[1]) return 5;
    if (columnName == kanbanColumns[2]) return 4;
    if (columnName == kanbanColumns.last) return 99;
    return 6;
  }

  Future<void> addColumn() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Thêm cột mới'),
          content: TextField(
            controller: controller,
            decoration: adminInputDecoration(
              label: 'Tên cột',
              icon: Icons.view_column_outlined,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;

    try {
      final savedList = await AppDataService.createTaskList(
        projectId: widget.project.id,
        name: name,
        position: columns.length + 1,
        wipLimit: 5,
        isWipEnabled: true,
      );
      if (!mounted) return;
      setState(() {
        columns.add(_fromTaskList(savedList));
      });
      showAdminMessage(context, 'Đã thêm cột mới');
    } catch (error) {
      if (!mounted) return;
      showAdminMessage(context, 'Không thể thêm cột: $error');
    }
  }

  Future<void> renameColumn(int index) async {
    final controller = TextEditingController(text: columns[index].name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Đổi tên cột'),
          content: TextField(
            controller: controller,
            decoration: adminInputDecoration(
              label: 'Tên cột',
              icon: Icons.edit_rounded,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;

    final oldColumn = columns[index];
    final updatedColumn = oldColumn.copyWith(name: name);

    setState(() {
      columns[index] = updatedColumn;
    });

    try {
      final savedList = await AppDataService.updateTaskList(
        updatedColumn.toTaskListConfig(),
      );
      if (!mounted) return;
      setState(() {
        columns[index] = _fromTaskList(savedList);
      });
      showAdminMessage(context, 'Đã đổi tên cột');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        columns[index] = oldColumn;
      });
      showAdminMessage(context, 'Không thể đổi tên cột: $error');
    }
  }

  Future<void> removeColumn(int index) async {
    final column = columns[index];

    if (column.currentCount > 0) {
      showAdminMessage(context, 'Không thể xóa cột đang có task');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Xóa cột'),
          content: Text('Bạn có chắc muốn xóa cột "${column.name}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await AppDataService.deleteTaskList(column.id);
      if (!mounted) return;
      setState(() {
        columns.removeAt(index);
      });
      await saveConfiguration(showSuccessMessage: false);
      if (!mounted) return;
      showAdminMessage(context, 'Đã xóa cột');
    } catch (error) {
      if (!mounted) return;
      showAdminMessage(context, 'Không thể xóa cột: $error');
    }
  }

  Future<void> saveConfiguration({bool showSuccessMessage = true}) async {
    setState(() {
      isSaving = true;
    });

    try {
      for (var index = 0; index < columns.length; index += 1) {
        final column = columns[index].copyWith(position: index + 1);
        final savedList = await AppDataService.updateTaskList(
          column.toTaskListConfig(),
        );
        columns[index] = _fromTaskList(savedList);
      }

      if (!mounted) return;
      setState(() {
        isSaving = false;
      });

      if (showSuccessMessage) {
        final exceededColumns = columns.where((column) {
          return column.wipEnabled && column.currentCount > column.wipLimit;
        }).length;
        showAdminMessage(
          context,
          exceededColumns > 0
              ? 'Đã lưu, nhưng có cột đang vượt WIP limit'
              : 'Đã lưu cấu hình bảng',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
      });
      showAdminMessage(context, 'Không thể lưu cấu hình: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: 'Cấu hình bảng',
      icon: Icons.tune_rounded,
      floatingActionButton: FloatingActionButton(
        onPressed: addColumn,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: loadColumns,
            child: isLoading
                ? const AdminLoading()
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.project.name,
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.project.code,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (errorMessage != null) ...[
                          AdminErrorBanner(
                            message: errorMessage!,
                            onRetry: loadColumns,
                          ),
                          const SizedBox(height: 16),
                        ],
                        AdminStatGrid(
                          stats: [
                            AdminStat(
                              label: 'Tổng cột',
                              value: '${columns.length}',
                              icon: Icons.view_column_rounded,
                              color: const Color(0xFF7C3AED),
                            ),
                            AdminStat(
                              label: 'WIP bật',
                              value: '$enabledWipCount',
                              icon: Icons.speed_rounded,
                              color: const Color(0xFF2563EB),
                            ),
                            AdminStat(
                              label: 'Vượt giới hạn',
                              value: '$exceededCount',
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEF4444),
                            ),
                            AdminStat(
                              label: 'Task',
                              value: '${widget.tasks.length}',
                              icon: Icons.task_alt_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AdminSectionTitle(
                          title: 'Danh sách cột Kanban',
                          countLabel: '${columns.length} cột',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Kéo giữ biểu tượng bên phải để đổi thứ tự cột. WIP limit được lưu vào MySQL qua backend.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (columns.isEmpty)
                          const AdminEmptyState(
                            icon: Icons.view_column_outlined,
                            message: 'Project này chưa có cột Kanban.',
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: columns.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item = columns.removeAt(oldIndex);
                                columns.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final column = columns[index];
                              return _ColumnSettingCard(
                                key: ValueKey(column.id),
                                column: column,
                                index: index,
                                onToggleWip: (value) {
                                  setState(() {
                                    columns[index] =
                                        columns[index].copyWith(wipEnabled: value);
                                  });
                                },
                                onLimitChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed < 1) return;
                                  setState(() {
                                    columns[index] =
                                        columns[index].copyWith(wipLimit: parsed);
                                  });
                                },
                                onRename: () => renameColumn(index),
                                onRemove: () => removeColumn(index),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : () => saveConfiguration(),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(isSaving ? 'Đang lưu...' : 'Lưu cấu hình'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnSettingCard extends StatelessWidget {
  final _BoardColumnSetting column;
  final int index;
  final ValueChanged<bool> onToggleWip;
  final ValueChanged<String> onLimitChanged;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  const _ColumnSettingCard({
    super.key,
    required this.column,
    required this.index,
    required this.onToggleWip,
    required this.onLimitChanged,
    required this.onRename,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isExceeded = column.wipEnabled && column.currentCount > column.wipLimit;
    final color = _columnColor(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        column.name,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        column.wipEnabled
                            ? 'WIP: ${column.currentCount}/${column.wipLimit}'
                            : 'WIP đang tắt',
                        style: TextStyle(
                          color: isExceeded
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_handle_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '${column.wipLimit}',
                    enabled: column.wipEnabled,
                    keyboardType: TextInputType.number,
                    onChanged: onLimitChanged,
                    decoration: adminInputDecoration(
                      label: 'WIP limit',
                      icon: Icons.speed_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text(
                      'Bật WIP',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Switch(
                      value: column.wipEnabled,
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: onToggleWip,
                    ),
                  ],
                ),
              ],
            ),
            if (isExceeded) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Cột này đang vượt WIP limit. Hãy tăng giới hạn hoặc chuyển bớt task.',
                  style: TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRename,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Đổi tên'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
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

  Color _columnColor(int index) {
    final colors = [
      const Color(0xFF64748B),
      const Color(0xFF2563EB),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
      const Color(0xFF9333EA),
    ];
    return colors[index % colors.length];
  }
}

class _BoardColumnSetting {
  final String id;
  final String name;
  final int position;
  final int wipLimit;
  final bool wipEnabled;
  final int currentCount;

  const _BoardColumnSetting({
    required this.id,
    required this.name,
    required this.position,
    required this.wipLimit,
    required this.wipEnabled,
    required this.currentCount,
  });

  _BoardColumnSetting copyWith({
    String? name,
    int? position,
    int? wipLimit,
    bool? wipEnabled,
    int? currentCount,
  }) {
    return _BoardColumnSetting(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
      wipLimit: wipLimit ?? this.wipLimit,
      wipEnabled: wipEnabled ?? this.wipEnabled,
      currentCount: currentCount ?? this.currentCount,
    );
  }

  TaskListConfig toTaskListConfig() {
    return TaskListConfig(
      id: id,
      projectId: '',
      name: name,
      position: position,
      wipLimit: wipLimit,
      isWipEnabled: wipEnabled,
    );
  }
}

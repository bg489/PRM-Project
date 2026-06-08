import 'package:flutter/material.dart';
import '../../data/mock_tasks.dart';
import '../../data/mock_workspaces.dart';

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
  late List<_BoardColumnSetting> columns;

  @override
  void initState() {
    super.initState();

    columns = kanbanColumns.map((columnName) {
      final currentCount =
          widget.tasks.where((task) => task.status == columnName).length;

      return _BoardColumnSetting(
        name: columnName,
        wipLimit: _defaultLimitByColumn(columnName),
        wipEnabled: columnName == 'Đang làm' || columnName == 'Kiểm tra',
        currentCount: currentCount,
      );
    }).toList();
  }

  int _defaultLimitByColumn(String columnName) {
    switch (columnName) {
      case 'Cần làm':
        return 10;
      case 'Đang làm':
        return 5;
      case 'Kiểm tra':
        return 4;
      case 'Đã xong':
        return 99;
      default:
        return 6;
    }
  }

  void addColumn() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Thêm cột mới'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Review UI',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isEmpty) return;

                setState(() {
                  columns.add(
                    _BoardColumnSetting(
                      name: name,
                      wipLimit: 5,
                      wipEnabled: true,
                      currentCount: 0,
                    ),
                  );
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void renameColumn(int index) {
    final TextEditingController controller = TextEditingController(
      text: columns[index].name,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Đổi tên cột'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Nhập tên cột',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isEmpty) return;

                setState(() {
                  columns[index].name = name;
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void removeColumn(int index) {
    if (columns[index].currentCount > 0) {
      showMessage('Không thể xóa cột đang có task trong mock UI');
      return;
    }

    setState(() {
      columns.removeAt(index);
    });
  }

  void saveConfiguration() {
    final exceededColumns = columns.where((column) {
      return column.wipEnabled && column.currentCount > column.wipLimit;
    }).toList();

    if (exceededColumns.isNotEmpty) {
      showMessage(
        'Có cột đang vượt WIP limit. Vẫn lưu mock để demo cảnh báo.',
      );
    } else {
      showMessage('Đã lưu cấu hình bảng thành công');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int get enabledWipCount {
    return columns.where((column) => column.wipEnabled).length;
  }

  int get exceededCount {
    return columns.where((column) {
      return column.wipEnabled && column.currentCount > column.wipLimit;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _BoardConfigHeader(
              projectName: widget.project.name,
              projectCode: widget.project.code,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverviewPanel(
                      totalColumns: columns.length,
                      enabledWipCount: enabledWipCount,
                      exceededCount: exceededCount,
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Danh sách cột Kanban',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: addColumn,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFF9333EA),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Thêm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Kéo giữ biểu tượng bên phải để thay đổi thứ tự cột.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: columns.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

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
                              column.wipEnabled = value;
                            });
                          },
                          onLimitChanged: (value) {
                            final parsed = int.tryParse(value);

                            if (parsed == null || parsed < 1) return;

                            setState(() {
                              column.wipLimit = parsed;
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
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: saveConfiguration,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Lưu cấu hình'),
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
    );
  }
}

class _BoardConfigHeader extends StatelessWidget {
  final String projectName;
  final String projectCode;
  final VoidCallback onBack;

  const _BoardConfigHeader({
    required this.projectName,
    required this.projectCode,
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
                Text(
                  projectCode,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Cấu hình bảng',
                  style: TextStyle(
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
              Icons.tune_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final int totalColumns;
  final int enabledWipCount;
  final int exceededCount;

  const _OverviewPanel({
    required this.totalColumns,
    required this.enabledWipCount,
    required this.exceededCount,
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
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quản lý giới hạn WIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Thiết lập số lượng công việc tối đa trong từng cột để tránh quá tải cho team.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Tổng cột',
                  value: '$totalColumns',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'WIP bật',
                  value: '$enabledWipCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMiniStat(
                  label: 'Vượt giới hạn',
                  value: '$exceededCount',
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
        horizontal: 10,
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
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
    final fractionText = '${column.currentCount}/${column.wipLimit}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isExceeded ? const Color(0xFFEF4444) : Colors.transparent,
          width: 1.4,
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
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _columnColor(index).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: _columnColor(index),
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
                          ? 'Đang dùng WIP: $fractionText'
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
                child: _LimitInput(
                  initialValue: '${column.wipLimit}',
                  enabled: column.wipEnabled,
                  onChanged: onLimitChanged,
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
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cột này đang vượt WIP limit. Khi áp dụng thật, hệ thống sẽ chặn kéo thêm task vào cột.',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
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
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemove,
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

class _LimitInput extends StatelessWidget {
  final String initialValue;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _LimitInput({
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'WIP limit',
        hintText: 'Nhập giới hạn',
        prefixIcon: const Icon(Icons.speed_rounded),
        filled: true,
        fillColor: enabled ? const Color(0xFFF3F4F6) : const Color(0xFFE5E7EB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _BoardColumnSetting {
  final String id;
  String name;
  int wipLimit;
  bool wipEnabled;
  int currentCount;

  _BoardColumnSetting({
    required this.name,
    required this.wipLimit,
    required this.wipEnabled,
    required this.currentCount,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString() + name;
}
import 'package:flutter/material.dart';

import '../../utils/search_utils.dart';

class AdminScreenScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? floatingActionButton;

  const AdminScreenScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          children: [
            _AdminHeader(
              title: title,
              icon: icon,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: adminCardDecoration(),
      child: child,
    );
  }
}

class AdminStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AdminStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class AdminStatGrid extends StatelessWidget {
  final List<AdminStat> stats;

  const AdminStatGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: stats.map((stat) => _AdminStatCard(stat: stat)).toList(),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  final String title;
  final String? countLabel;

  const AdminSectionTitle({super.key, required this.title, this.countLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (countLabel != null) AdminPill(label: countLabel!),
      ],
    );
  }
}

class AdminPill extends StatelessWidget {
  final String label;
  final Color color;

  const AdminPill({
    super.key,
    required this.label,
    this.color = const Color(0xFF7C3AED),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const AdminEmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
    );
  }
}

class AdminErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AdminErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

InputDecoration adminInputDecoration({required String label, IconData? icon}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}

BoxDecoration adminCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ],
  );
}

void showAdminMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

class _AdminHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onBack;

  const _AdminHeader({
    required this.title,
    required this.icon,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
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
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final AdminStat stat;

  const _AdminStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, color: stat.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  stat.label,
                  maxLines: 2,
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

String normalizeAdminSearch(String value) {
  return normalizeSearchText(value);
}

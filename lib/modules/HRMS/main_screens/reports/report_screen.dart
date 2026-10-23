// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/modules/HRMS/main_screens/dashboard/controllers/dash_con.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/attendance_edit_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/attendance_report.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/leave_report.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReportTile {
  const ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String category;
  final Color accentColor;
  final VoidCallback onTap;
}

class ReportController extends GetxController {
  final username = ''.obs;
  final empName = ''.obs;
  final tiles = <ReportTile>[].obs;

  @override
  void onInit() {
    super.onInit();

    try {
      final dash = Get.find<DashboardController>();
      username.value = dash.username.value;
      empName.value = dash.employeeName.value;
    } catch (_) {}

    _buildTiles();
  }

  void _buildTiles() {
    tiles.assignAll([
      ReportTile(
        icon: LucideIcons.calendarClock,
        title: 'Attendance Report',
        subtitle: 'Daily attendance, punch times, status and date filters.',
        category: 'Attendance',
        accentColor: const Color(0xFF16A34A),
        onTap: openAttendanceReport,
      ),
      ReportTile(
        icon: LucideIcons.filePenLine,
        title: 'Attendance Edit Report',
        subtitle: 'Correction requests, review status, comments and history.',
        category: 'Attendance',
        accentColor: const Color(0xFF2563EB),
        onTap: openAttendanceEditReport,
      ),
      ReportTile(
        icon: LucideIcons.umbrella,
        title: 'Leave Report',
        subtitle: 'Leave requests, approvals, balances and filtered history.',
        category: 'Leave',
        accentColor: const Color(0xFFF59E0B),
        onTap: openLeaveReport,
      ),
    ]);
  }

  void openAttendanceReport() {
    Get.to(() => AttendanceReportScreen());
  }

  void openAttendanceEditReport() {
    Get.to(() => const AttendanceEditReportScreen());
  }

  void openLeaveReport() {
    Get.to(() => LeaveReportPage(username: username.value));
  }
}

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key});

  final ReportController controller = Get.put(ReportController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Obx(() {
        final reports = controller.tiles;

        if (reports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final attendanceReports =
            reports.where((item) => item.category == 'Attendance').toList();
        final leaveReports =
            reports.where((item) => item.category == 'Leave').toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ReportOverviewCard(
              employeeName: controller.empName.value,
              reportCount: reports.length,
            ),
            const SizedBox(height: 14),
            _ReportSummaryRow(
              attendanceCount: attendanceReports.length,
              leaveCount: leaveReports.length,
            ),
            const SizedBox(height: 18),
            _ReportSection(
              title: 'Attendance',
              subtitle: 'Punch records and correction requests',
              children: attendanceReports
                  .map((report) => ReportListCard(report: report))
                  .toList(),
            ),
            const SizedBox(height: 18),
            _ReportSection(
              title: 'Leave',
              subtitle: 'Leave request and balance history',
              children: leaveReports
                  .map((report) => ReportListCard(report: report))
                  .toList(),
            ),
          ],
        );
      }),
    );
  }
}

class _ReportOverviewCard extends StatelessWidget {
  const _ReportOverviewCard({
    required this.employeeName,
    required this.reportCount,
  });

  final String employeeName;
  final int reportCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = employeeName.trim().isEmpty ? 'Employee' : employeeName.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary2,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary2.withValues(
              alpha: isDark ? 0.18 : 0.14,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$name, view $reportCount reports with faster navigation.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.chartColumn,
              color: Colors.white,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryRow extends StatelessWidget {
  const _ReportSummaryRow({
    required this.attendanceCount,
    required this.leaveCount,
  });

  final int attendanceCount;
  final int leaveCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryPill(
            icon: LucideIcons.calendarClock,
            label: 'Attendance',
            count: attendanceCount,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryPill(
            icon: LucideIcons.umbrella,
            label: 'Leave',
            count: leaveCount,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
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

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class ReportListCard extends StatelessWidget {
  const ReportListCard({
    super.key,
    required this.report,
  });

  final ReportTile report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        color: isDark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
        child: InkWell(
          onTap: report.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: report.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    report.icon,
                    color: report.accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.64,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

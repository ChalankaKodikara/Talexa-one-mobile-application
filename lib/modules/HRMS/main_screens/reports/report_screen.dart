// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/modules/HRMS/main_screens/dashboard/controllers/dash_con.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/attendance_edit_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/attendance_report.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/leave_report.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _blue = Color(0xFF1769E8);
const _navy = Color(0xFF182237);
const _muted = Color(0xFF89919D);
const _lightBackground = Color(0xFFF5F6F8);
const _darkBackground = Color(0xFF101623);
const _darkSurface = Color(0xFF1B2638);

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
    } catch (_) {
      // Reports remain available when DashboardController is not registered.
    }
    _buildTiles();
  }

  void _buildTiles() {
    tiles.assignAll([
      ReportTile(
        icon: LucideIcons.calendarClock,
        title: 'Attendance Report',
        subtitle: 'Daily records, punch times and attendance status',
        category: 'Attendance',
        accentColor: _blue,
        onTap: openAttendanceReport,
      ),
      ReportTile(
        icon: LucideIcons.filePenLine,
        title: 'Attendance Edit Report',
        subtitle: 'Correction requests and approval history',
        category: 'Attendance',
        accentColor: _blue,
        onTap: openAttendanceEditReport,
      ),
      ReportTile(
        icon: LucideIcons.umbrella,
        title: 'Leave Report',
        subtitle: 'Leave requests, balances and approval history',
        category: 'Leave',
        accentColor: _blue,
        onTap: openLeaveReport,
      ),
    ]);
  }

  void openAttendanceReport() => Get.to(() => AttendanceReportScreen());

  void openAttendanceEditReport() =>
      Get.to(() => const AttendanceEditReportScreen());

  void openLeaveReport() =>
      Get.to(() => LeaveReportPage(username: username.value));
}

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key});

  final ReportController controller = Get.isRegistered<ReportController>()
      ? Get.find<ReportController>()
      : Get.put(ReportController());

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? _darkBackground : _lightBackground;
    final foreground = dark ? Colors.white : _navy;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Reports'),
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
      ),
      body: Obx(() {
        final reports = controller.tiles.toList();
        final employeeName = controller.empName.value.trim();
        if (reports.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }

        final attendance =
            reports.where((r) => r.category == 'Attendance').toList();
        final leave = reports.where((r) => r.category == 'Leave').toList();

        return SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
                children: [
                  _ReportsIntro(
                      employeeName: employeeName, total: reports.length),
                  const SizedBox(height: 24),
                  _SectionHeading(
                    title: 'Attendance',
                    subtitle: 'Your daily records and adjustments',
                    count: attendance.length,
                  ),
                  const SizedBox(height: 11),
                  _ReportGroup(items: attendance),
                  const SizedBox(height: 26),
                  _SectionHeading(
                    title: 'Leave',
                    subtitle: 'Requests, approvals and balances',
                    count: leave.length,
                  ),
                  const SizedBox(height: 11),
                  _ReportGroup(items: leave),
                  const SizedBox(height: 22),
                  _ReportsFootnote(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ReportsIntro extends StatelessWidget {
  const _ReportsIntro({required this.employeeName, required this.total});
  final String employeeName;
  final int total;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = dark ? Colors.white : _navy;
    final secondary = dark ? const Color(0xFF9AA8BA) : _muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REPORT CENTER',
          style: TextStyle(
            color: _blue,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your reports',
          style: TextStyle(
            color: mainColor,
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          employeeName.isEmpty
              ? 'View and manage your HR reports in one place.'
              : '$employeeName, access your HR reports in one place.',
          style: TextStyle(color: secondary, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          decoration: BoxDecoration(
            color: dark ? _darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark ? const Color(0xFF2B374B) : const Color(0xFFECEFF3),
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.files, color: _blue, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total reports available',
                      style: TextStyle(
                        fontSize: 15,
                        color: mainColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Select a report to view its details',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_outline_rounded,
                  color: _blue, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.title, required this.subtitle, required this.count});
  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : _navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: dark ? const Color(0xFF9AA8BA) : _muted,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
              color: _blue, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ReportGroup extends StatelessWidget {
  const _ReportGroup({required this.items});
  final List<ReportTile> items;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? _darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFF2B374B) : const Color(0xFFECEFF3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 55,
                color: dark ? const Color(0xFF2B374B) : const Color(0xFFF0F2F5),
              ),
            ReportListCard(report: items[i]),
          ],
        ],
      ),
    );
  }
}

class ReportListCard extends StatelessWidget {
  const ReportListCard({super.key, required this.report});
  final ReportTile report;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: report.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
          child: Row(
            children: [
              Icon(report.icon, size: 23, color: _blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: TextStyle(
                        color: dark ? Colors.white : _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.subtitle,
                      style: TextStyle(
                        color: dark ? const Color(0xFF9AA8BA) : _muted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: dark ? const Color(0xFF748197) : const Color(0xFFADB4BF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsFootnote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: dark ? const Color(0xFF9AA8BA) : _muted,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Report information reflects the latest data available in your HRMS account.',
            style: TextStyle(
              color: dark ? const Color(0xFF9AA8BA) : _muted,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

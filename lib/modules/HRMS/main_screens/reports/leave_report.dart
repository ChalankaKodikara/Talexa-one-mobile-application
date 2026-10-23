// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:ui';
import 'package:corehris/components/leave_report_card/leavereportcard.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/controllers/leave_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LeaveReportPage extends StatelessWidget {
  final LeaveReportController controller;

  LeaveReportPage({super.key, required String username})
      : controller = Get.put(LeaveReportController());

  Future<void> _pickDateThemed(BuildContext context, bool isStart) async {
    final theme = Theme.of(context);
    final initial = isStart
        ? (controller.startDate.value ?? DateTime.now())
        : (controller.endDate.value ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? "SELECT START DATE" : "SELECT END DATE",
      confirmText: "OK",
      cancelText: "CANCEL",
      builder: (context, child) {
        final isDark = theme.brightness == Brightness.dark;
        final cs = theme.colorScheme;

        final customScheme = cs.copyWith(
          primary: AppColors.primary2,
          onPrimary: Colors.white,
          surface: isDark ? const Color(0xFF111827) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black87,
        );

        return Theme(
          data: theme.copyWith(
            colorScheme: customScheme,
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
              headerBackgroundColor: AppColors.primary2,
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              headerHelpStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.6,
              ),
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              dayStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              todayForegroundColor: const WidgetStatePropertyAll(
                AppColors.primary1,
              ),
              todayBorder: const BorderSide(
                color: AppColors.primary2,
                width: 1.6,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                if (states.contains(WidgetState.disabled)) return Colors.grey;
                return isDark ? Colors.white : Colors.black87;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary2;
                }
                return null;
              }),
              dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.primary2.withOpacity(0.12);
                }
                return null;
              }),
              yearStyle: const TextStyle(fontWeight: FontWeight.w700),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return isDark ? Colors.white : Colors.black87;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary2;
                }
                return null;
              }),
              rangeSelectionBackgroundColor:
                  AppColors.primary2.withOpacity(0.12),
              rangeSelectionOverlayColor: WidgetStatePropertyAll(
                AppColors.primary2.withOpacity(0.08),
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.primary2,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        controller.startDate.value = picked;
      } else {
        controller.endDate.value = picked;
      }
      await controller.fetchLeaveData();
    }
  }

  Widget _dateBox(BuildContext context, String text, {required bool active}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary2.withOpacity(isDark ? 0.22 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary2,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: active
                        ? theme.textTheme.bodyMedium?.color
                        : theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF1E3A8A),
                  Color(0xFF1D4ED8),
                  Color(0xFF2563EB),
                ]
              : const [
                  Color(0xFF2563EB),
                  Color(0xFF2F6BFF),
                  Color(0xFF4F46E5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary2.withOpacity(isDark ? 0.24 : 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerIconButton(
                context,
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Get.back(),
              ),
              const Spacer(),
              Text(
                "Leave Report",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Track your leave history",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Review leave requests, approvals, balances, and past records with date filtering.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.90),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary2),
          const SizedBox(height: 14),
          Text(
            "Loading leave records...",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.72),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary2.withOpacity(
                      isDark ? 0.18 : 0.10,
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      color: AppColors.primary2,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "No leave records found",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Try changing the selected date range to view leave data.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  static Widget _blurBubble({
    required double size,
    required Color color,
  }) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth >= 760 ? 700.0 : screenWidth;
    final horizontalPadding = screenWidth < 360 ? 14.0 : 16.0;
    final stackDateFilters = screenWidth < 390;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [
                          Color(0xFF0B1220),
                          Color(0xFF101A2F),
                          Color(0xFF0F172A),
                        ]
                      : const [
                          Color(0xFFF8FAFF),
                          Color(0xFFF3F6FB),
                          Color(0xFFEEF3FA),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: _blurBubble(
              size: 180,
              color: AppColors.primary2.withOpacity(isDark ? 0.16 : 0.14),
            ),
          ),
          Positioned(
            top: 180,
            left: -30,
            child: _blurBubble(
              size: 120,
              color: AppColors.primary1.withOpacity(isDark ? 0.12 : 0.10),
            ),
          ),
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        Expanded(child: _loadingState(context)),
                      ],
                    ),
                  ),
                );
              }

              final start = controller.startDate.value;
              final end = controller.endDate.value;

              final startText = start == null
                  ? "Start Date"
                  : DateFormat("yyyy-MM-dd").format(start);
              final endText = end == null
                  ? "End Date"
                  : DateFormat("yyyy-MM-dd").format(end);

              final startDateBox = GestureDetector(
                onTap: () => _pickDateThemed(context, true),
                child: _dateBox(
                  context,
                  startText,
                  active: start != null,
                ),
              );
              final endDateBox = GestureDetector(
                onTap: () => _pickDateThemed(context, false),
                child: _dateBox(
                  context,
                  endText,
                  active: end != null,
                ),
              );

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: stackDateFilters
                            ? Column(
                                children: [
                                  startDateBox,
                                  const SizedBox(height: 10),
                                  endDateBox,
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: startDateBox),
                                  const SizedBox(width: 12),
                                  Expanded(child: endDateBox),
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: controller.filteredLeaveData.isEmpty
                            ? _emptyState(context)
                            : RefreshIndicator(
                                color: AppColors.primary2,
                                onRefresh: () async =>
                                    await controller.fetchLeaveData(),
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    0,
                                    horizontalPadding,
                                    20,
                                  ),
                                  itemCount:
                                      controller.filteredLeaveData.length,
                                  itemBuilder: (_, i) {
                                    final leave =
                                        controller.filteredLeaveData[i];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: LeaveReportCard(
                                        leave: leave,
                                        controller: controller,
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

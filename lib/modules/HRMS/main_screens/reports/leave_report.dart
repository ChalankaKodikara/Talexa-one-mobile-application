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

  // View-scoped date filters. Day remembers its own range when switching views.
  final RxString reportView = 'day'.obs;
  final Rx<DateTime> focusedDate = DateTime.now().obs;
  DateTime? _rememberedDayStart;
  DateTime? _rememberedDayEnd;
  final RxBool _changingPeriod = false.obs;

  static DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _monday(DateTime d) =>
      _onlyDate(d).subtract(Duration(days: d.weekday - DateTime.monday));

  Future<void> _applyPeriod(DateTime start, DateTime end) async {
    if (_changingPeriod.value) return;
    _changingPeriod.value = true;
    try {
      controller.startDate.value = _onlyDate(start);
      controller.endDate.value = _onlyDate(end);
      await controller.fetchLeaveData();
    } finally {
      _changingPeriod.value = false;
    }
  }

  Future<void> _changeView(String view) async {
    if (_changingPeriod.value || view == reportView.value) return;
    if (reportView.value == 'day') {
      _rememberedDayStart = controller.startDate.value;
      _rememberedDayEnd = controller.endDate.value;
    }
    reportView.value = view;
    final date = focusedDate.value;
    if (view == 'week') {
      await _setWeek(date);
    } else if (view == 'month') {
      await _setMonth(date);
    } else {
      final end = _rememberedDayEnd ?? _onlyDate(DateTime.now());
      final start =
          _rememberedDayStart ?? end.subtract(const Duration(days: 6));
      await _applyPeriod(start, end);
    }
  }

  Future<void> _setWeek(DateTime date) async {
    focusedDate.value = _onlyDate(date);
    final start = _monday(date);
    await _applyPeriod(start, start.add(const Duration(days: 6)));
  }

  Future<void> _setMonth(DateTime date) async {
    focusedDate.value = DateTime(date.year, date.month, 1);
    await _applyPeriod(
      DateTime(date.year, date.month, 1),
      DateTime(date.year, date.month + 1, 0),
    );
  }

  Future<void> _movePeriod(int offset) async {
    if (_changingPeriod.value) return;
    final date = focusedDate.value;
    if (reportView.value == 'week') {
      await _setWeek(date.add(Duration(days: offset * 7)));
    } else if (reportView.value == 'month') {
      await _setMonth(DateTime(date.year, date.month + offset, 1));
    }
  }

  Future<void> _chooseDayRange(BuildContext context) async {
    final start = controller.startDate.value;
    final end = controller.endDate.value;
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: start != null && end != null && !start.isAfter(end)
          ? DateTimeRange(start: _onlyDate(start), end: _onlyDate(end))
          : null,
      helpText: 'Select leave date range',
      saveText: 'Apply',
      builder: (context, child) {
        final theme = Theme.of(context);
        final dark = theme.brightness == Brightness.dark;
        const selectedBlue = Color(0xFF5B8DEF);
        final rangeBlue =
            dark ? const Color(0xFF284263) : const Color(0xFFDCE9FF);
        final normalText =
            dark ? const Color(0xFFF1F5FB) : const Color(0xFF182237);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: selectedBlue,
              onPrimary: Colors.white,
              onSurface: normalText,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: dark ? const Color(0xFF1B2638) : Colors.white,
              rangeSelectionBackgroundColor: rangeBlue,
              rangeSelectionOverlayColor:
                  const WidgetStatePropertyAll(Colors.transparent),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return normalText;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return selectedBlue;
                }
                return null;
              }),
              todayForegroundColor: const WidgetStatePropertyAll(selectedBlue),
              todayBorder: const BorderSide(
                color: selectedBlue,
                width: 1.2,
              ),
              headerForegroundColor: normalText,
              dividerColor:
                  dark ? const Color(0xFF303D50) : const Color(0xFFE8EDF4),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null) return;
    _rememberedDayStart = selected.start;
    _rememberedDayEnd = selected.end;
    await _applyPeriod(selected.start, selected.end);
  }

  Future<void> _chooseWeek(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: focusedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select a date within the week',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF1769E8),
              ),
        ),
        child: child!,
      ),
    );
    if (selected != null) await _setWeek(selected);
  }

  Future<void> _chooseMonth(BuildContext context) async {
    int year = focusedDate.value.year;
    final chosen = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            const Expanded(
                child: Text('Select month',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded)),
          ]),
          content: SizedBox(
            width: 330,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(
                  onPressed: year <= 2000 ? null : () => refresh(() => year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('$year',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed: year >= 2100 ? null : () => refresh(() => year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ]),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 43,
                ),
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final active = focusedDate.value.year == year &&
                      focusedDate.value.month == month;
                  return Material(
                    color: active
                        ? const Color(0xFF1769E8)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          Navigator.pop(context, DateTime(year, month, 1)),
                      child: Center(
                          child: Text(
                        DateFormat('MMM').format(DateTime(year, month)),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      )),
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
      ),
    );
    if (chosen != null) await _setMonth(chosen);
  }

  Future<void> _quickLastSevenDays() async {
    final end = _onlyDate(DateTime.now());
    final start = end.subtract(const Duration(days: 6));
    _rememberedDayStart = start;
    _rememberedDayEnd = end;
    await _applyPeriod(start, end);
  }

  Future<void> _quickThisMonth() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, 1);
    final end = DateTime(today.year, today.month + 1, 0);
    _rememberedDayStart = start;
    _rememberedDayEnd = end;
    await _applyPeriod(start, end);
  }

  Widget _buildReportDateControls(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? const Color(0xFFA4ADBC) : const Color(0xFF89919D);
    const blue = Color(0xFF1769E8);

    return Obx(() {
      final view = reportView.value;
      final focused = focusedDate.value;
      final busy = _changingPeriod.value;
      final start = controller.startDate.value;
      final end = controller.endDate.value;

      late final String title;
      late final String subtitle;
      late final VoidCallback action;
      if (view == 'week') {
        final first = _monday(focused);
        final last = first.add(const Duration(days: 6));
        title = '${DateFormat('dd MMM').format(first)} – '
            '${DateFormat('dd MMM yyyy').format(last)}';
        subtitle = 'SELECTED WEEK';
        action = () => _chooseWeek(context);
      } else if (view == 'month') {
        title = DateFormat('MMMM yyyy').format(focused);
        subtitle = 'SELECTED MONTH';
        action = () => _chooseMonth(context);
      } else {
        title = start != null && end != null
            ? '${DateFormat('dd MMM').format(start)} – '
                '${DateFormat('dd MMM yyyy').format(end)}'
            : 'Select date range';
        subtitle = 'SELECTED DATE RANGE';
        action = () => _chooseDayRange(context);
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF243145) : const Color(0xFFE8EDF5),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(children: [
              for (final choice in const [
                ('day', 'Day', Icons.calendar_view_day_rounded),
                ('week', 'Week', Icons.view_week_outlined),
                ('month', 'Month', Icons.calendar_month_outlined),
              ])
                Expanded(
                    child: Material(
                  color: view == choice.$1 ? blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: busy ? null : () => _changeView(choice.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(choice.$3,
                                size: 16,
                                color:
                                    view == choice.$1 ? Colors.white : muted),
                            const SizedBox(width: 5),
                            Text(choice.$2,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: view == choice.$1 ? Colors.white : ink,
                                )),
                          ]),
                    ),
                  ),
                )),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                  color:
                      dark ? const Color(0xFF303D50) : const Color(0xFFE7EDF5)),
            ),
            child: Row(children: [
              if (view != 'day')
                IconButton(
                  tooltip: view == 'week' ? 'Previous week' : 'Previous month',
                  onPressed: busy ? null : () => _movePeriod(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              Expanded(
                  child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: busy ? null : action,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Column(children: [
                    Text(subtitle,
                        style: TextStyle(
                          color: muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 5),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800))),
                      const SizedBox(width: 5),
                      const Icon(Icons.expand_more_rounded,
                          size: 18, color: blue),
                    ]),
                  ]),
                ),
              )),
              if (view != 'day')
                IconButton(
                  tooltip: view == 'week' ? 'Next week' : 'Next month',
                  onPressed: busy ? null : () => _movePeriod(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
            ]),
          ),
          if (view == 'day') ...[
            const SizedBox(height: 9),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: busy ? null : _quickLastSevenDays,
                style: OutlinedButton.styleFrom(
                  foregroundColor: blue,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Last 7 Days',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              )),
              const SizedBox(width: 9),
              Expanded(
                  child: OutlinedButton(
                onPressed: busy ? null : _quickThisMonth,
                style: OutlinedButton.styleFrom(
                  foregroundColor: blue,
                  shape: const StadiumBorder(),
                ),
                child: const Text('This Month',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              )),
            ]),
          ],
        ]),
      );
    });
  }

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

  // Read date from the actual leave entry, including nested leave date lists.
  // Do not replace a missing date with today's date.
  static DateTime? _parseLeaveDate(dynamic value, [int depth = 0]) {
    if (value == null || depth > 4) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final date = DateTime.tryParse(value.trim());
      if (date != null) return date;
      final found = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(value);
      return found == null ? null : DateTime.tryParse(found.group(0)!);
    }
    if (value is Iterable) {
      for (final entry in value) {
        final date = _parseLeaveDate(entry, depth + 1);
        if (date != null) return date;
      }
      return null;
    }
    if (value is Map) {
      for (final key in const [
        'leave_date',
        'leaveDate',
        'leave_dates',
        'leaveDates',
        'dates',
        'date',
        'start_date',
        'startDate',
        'from_date',
        'fromDate',
        'requested_date',
        'requestedDate',
        'requested_dates',
        'requestedDates',
        'leave_details',
        'leaveDetails',
        'days',
        'requested_at',
        'requestedAt',
      ]) {
        final date = _parseLeaveDate(value[key], depth + 1);
        if (date != null) return date;
      }
    }
    return null;
  }

  DateTime? _dateForLeave(dynamic leave) {
    dynamic tryRead(dynamic Function() getValue) {
      try {
        return getValue();
      } catch (_) {
        return null;
      }
    }

    final possibilities = <dynamic>[
      tryRead(() => leave.leaveDates),
      tryRead(() => leave.leave_dates),
      tryRead(() => leave.requestedDates),
      tryRead(() => leave.requested_dates),
      tryRead(() => leave.dates),
      tryRead(() => leave.startDate),
      tryRead(() => leave.start_date),
      tryRead(() => leave.fromDate),
      tryRead(() => leave.from_date),
      tryRead(() => leave.leaveDate),
      tryRead(() => leave.leave_date),
      tryRead(() => leave.date),
      tryRead(() => leave.toJson()),
      leave,
    ];
    for (final item in possibilities) {
      final date = _parseLeaveDate(item);
      if (date != null) return date;
    }
    return null;
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

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 6),
                      _buildReportDateControls(context),
                      const SizedBox(height: 4),
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
                                    // Compact card opens the original details in a bottom sheet.
                                    return _LeaveReportEntry(
                                      key: ValueKey('leave-$i'),
                                      date: _dateForLeave(leave),
                                      leave: leave,
                                      controller: controller,
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

/// Compact entry. The full existing LeaveReportCard remains available within
/// the bottom sheet for legacy actions and detailed covering-employee info.
class _LeaveReportEntry extends StatelessWidget {
  const _LeaveReportEntry({
    super.key,
    required this.date,
    required this.leave,
    required this.controller,
  });

  final DateTime? date;
  final dynamic leave;
  final LeaveReportController controller;

  static dynamic _read(dynamic obj, String key) {
    if (obj is Map) return obj[key];
    try {
      final json = obj.toJson();
      if (json is Map) return json[key];
    } catch (_) {}
    return null;
  }

  static dynamic _first(dynamic obj, List<String> keys) {
    for (final key in keys) {
      final v = _read(obj, key);
      if (v == null) continue;
      if (v is String && (v.trim().isEmpty || v.trim().toLowerCase() == 'null'))
        continue;
      return v;
    }
    return null;
  }

  static String _word(dynamic raw, {String fallback = ''}) {
    if (raw == null) return fallback;
    final s = raw.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return fallback;
    return s;
  }

  static String _pretty(String input) {
    return input.replaceAll('_', ' ').trim().split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String get _leaveType {
    final raw = _first(leave, const [
      'leave_type_name',
      'leaveTypeName',
      'category_name',
      'categoryName',
      'leave_type',
      'leaveType',
      'type_name',
      'typeName',
      'name'
    ]);
    if (raw is Map) {
      return _pretty(_word(
          _first(raw, const ['name', 'category_name', 'title']),
          fallback: 'Leave request'));
    }
    return _pretty(_word(raw, fallback: 'Leave request'));
  }

  // Leave models differ between the report API and detail-card model.
  // Read status from actual model fields first, then serialized/nested data.
  static dynamic _directStatus(dynamic obj) {
    if (obj is Map) return null;
    try {
      final v = obj.approved_status_1;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.approvedStatus1;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.approvalStatus;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.approval_status;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.leaveStatus;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.leave_status;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.status;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.isApproved;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.is_approved;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.approved;
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = obj.approval;
      if (v != null) return v;
    } catch (_) {}
    return null;
  }

  static String _normalizedKey(Object? key) => (key?.toString() ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  static dynamic _findStatus(dynamic obj, [int depth = 0]) {
    if (depth > 4 || obj == null) return null;
    if (obj is bool || obj is num) return obj;
    if (obj is String) return obj.trim().isEmpty ? null : obj;

    final direct = _directStatus(obj);
    if (direct != null) return direct;

    Map<dynamic, dynamic>? map;
    if (obj is Map) {
      map = obj;
    } else {
      try {
        final value = obj.toJson();
        if (value is Map) map = value;
      } catch (_) {}
      if (map == null) {
        try {
          final value = obj.toMap();
          if (value is Map) map = value;
        } catch (_) {}
      }
    }
    if (map == null) return null;

    const orderedKeys = [
      'approvedstatus1', // approved_status_1
      'approvalstatus',
      'leavestatus',
      'requeststatus',
      'hrstatus',
      'finalstatus',
      'approvestatus',
      'approval',
      'status',
      'isapproved',
      'approved',
      'isaccepted',
      'isrejected',
    ];
    for (final key in orderedKeys) {
      for (final entry in map.entries) {
        if (_normalizedKey(entry.key) != key) continue;
        final value = entry.value;
        if (value == null) continue;
        if (value is String && value.trim().isEmpty) continue;
        // The status field may be {name: 'APPROVED'} or {status: ...}.
        if (value is Map) {
          for (final nestedKey in const ['label', 'name', 'value', 'status']) {
            for (final e in value.entries) {
              if (_normalizedKey(e.key) == nestedKey && e.value != null) {
                return e.value;
              }
            }
          }
        }
        if (key == 'isrejected' && value is bool)
          return value ? 'REJECTED' : null;
        if (key == 'isaccepted' && value is bool)
          return value ? 'APPROVED' : null;
        return value;
      }
    }
    // Nested data is considered only after checking top-level fields.
    for (final entry in map.entries) {
      final key = _normalizedKey(entry.key);
      if (const ['leave', 'leavedetails', 'request', 'data', 'approvaldetails']
          .contains(key)) {
        final nested = _findStatus(entry.value, depth + 1);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  String get _status {
    final raw = _findStatus(leave);
    if (raw == null) return 'Unknown';
    if (raw is bool) return raw ? 'Approved' : 'Not approved';
    final normalized = raw.toString().trim().toUpperCase().replaceAll('_', ' ');
    if (normalized.isEmpty || normalized == 'NULL') return 'Unknown';
    if (normalized == '1' || normalized == 'TRUE') return 'Approved';
    if (normalized == '0' || normalized == 'FALSE') return 'Not approved';
    if (normalized.contains('NOT APPROV') || normalized.contains('UNAPPROV')) {
      return 'Not approved';
    }
    if (normalized.contains('REJECT') || normalized.contains('DECLIN')) {
      return 'Rejected';
    }
    if (normalized.contains('PENDING') || normalized.contains('WAITING')) {
      return 'Pending';
    }
    if (normalized.contains('APPROV')) return 'Approved';
    if (normalized.contains('CANCEL')) return 'Cancelled';
    return _pretty(normalized);
  }

  String get _reason => _word(_first(leave, const [
        'reason',
        'leave_reason',
        'leaveReason',
        'description',
        'remarks'
      ]));

  Color get _statusColor {
    switch (_status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF18975B);
      case 'not approved':
      case 'rejected':
        return const Color(0xFFE35D4E);
      case 'pending':
        return const Color(0xFFBD8714);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _openDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LeaveDetailsSheet(
        date: date,
        leave: leave,
        controller: controller,
        leaveType: _leaveType,
        status: _status,
        statusColor: _statusColor,
        reason: _reason,
      ),
    );
  }

  // Recent Requests styling, matching Leave Center cards.
  String get _requestedDateLabel {
    final value = _first(leave, const [
      'requested_date',
      'requestedDate',
      'leave_date',
      'leaveDate',
      'start_date',
      'startDate',
    ]);
    final raw = _word(value);
    if (raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return DateFormat('yyyy-MM-dd').format(parsed);
      return raw;
    }
    return date == null
        ? 'Date unavailable'
        : DateFormat('yyyy-MM-dd').format(date!);
  }

  String get _dayPart {
    final value = _first(leave, const [
      'is_half_day',
      'isHalfDay',
      'day_part',
      'dayPart',
      'duration_type',
      'durationType',
    ]);
    if (value == null) return '';
    if (value is bool) return value ? 'Half Day' : 'Full Day';
    if (value is num) return value == 1 ? 'Half Day' : 'Full Day';
    final label = _word(value).toLowerCase();
    if (label == '1' || label == 'true' || label.contains('half'))
      return 'Half Day';
    if (label == '0' || label == 'false' || label.contains('full'))
      return 'Full Day';
    return _pretty(label);
  }

  Color get _cardTint {
    final type = _leaveType.toLowerCase();
    final state = _status.toLowerCase();
    if (state.contains('reject') || state.contains('cancel')) {
      return const Color(0xFFFFECEB);
    }
    if (state.contains('pending') || state.contains('not approved')) {
      return const Color(0xFFFFF4DF);
    }
    if (type.contains('annual')) return const Color(0xFFE3F4EF);
    if (type.contains('casual')) return const Color(0xFFE9F0FF);
    if (type.contains('medical') || type.contains('sick')) {
      return const Color(0xFFFFEEE7);
    }
    return const Color(0xFFE8F0FF);
  }

  Color get _cardAccent {
    final type = _leaveType.toLowerCase();
    final state = _status.toLowerCase();
    if (state.contains('reject') || state.contains('cancel')) {
      return const Color(0xFFDB6157);
    }
    if (state.contains('pending') || state.contains('not approved')) {
      return const Color(0xFFD49B2C);
    }
    if (type.contains('annual')) return const Color(0xFF22A784);
    if (type.contains('casual')) return const Color(0xFF4F85EA);
    if (type.contains('medical') || type.contains('sick')) {
      return const Color(0xFFDF795F);
    }
    return const Color(0xFF4384E8);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? const Color(0xFFA4ADBC) : const Color(0xFF89919D);
    final accent = _cardAccent;
    final day = date == null ? '--' : DateFormat('dd').format(date!);
    final weekday =
        date == null ? '---' : DateFormat('EEE').format(date!).toUpperCase();
    final month =
        date == null ? '---' : DateFormat('MMM').format(date!).toUpperCase();
    final year = date == null ? '' : DateFormat('yyyy').format(date!);
    final dayPart = _dayPart;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  Text(day,
                      style: TextStyle(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.05)),
                  const SizedBox(height: 4),
                  Text(weekday,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1769E8))),
                  const SizedBox(height: 3),
                  Text(month, style: TextStyle(color: muted, fontSize: 10)),
                  Text(year, style: TextStyle(color: muted, fontSize: 9)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: dark ? const Color(0xFF1B2638) : _cardTint,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openDetails(context),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dark
                          ? accent.withOpacity(0.24)
                          : accent.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 37,
                        width: 37,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(dark ? 0.20 : 0.16),
                        ),
                        child: Icon(
                          _leaveType.toLowerCase().contains('annual')
                              ? Icons.beach_access_rounded
                              : Icons.calendar_month_outlined,
                          color: accent,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _leaveType.toUpperCase(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded,
                                    color: muted, size: 17),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Requested $_requestedDateLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: muted, fontSize: 10),
                            ),
                            const SizedBox(height: 11),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 5,
                              children: [
                                if (dayPart.isNotEmpty)
                                  Text(dayPart,
                                      style: TextStyle(
                                          color: muted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: dark
                                        ? _statusColor.withOpacity(.18)
                                        : Colors.white.withOpacity(.80),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    _status.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveStatusPill extends StatelessWidget {
  const _LeaveStatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(.10),
            borderRadius: BorderRadius.circular(99)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
      );
}

class _LeaveDetailsSheet extends StatefulWidget {
  const _LeaveDetailsSheet({
    required this.date,
    required this.leave,
    required this.controller,
    required this.leaveType,
    required this.status,
    required this.statusColor,
    required this.reason,
  });
  final DateTime? date;
  final dynamic leave;
  final LeaveReportController controller;
  final String leaveType;
  final String status;
  final Color statusColor;
  final String reason;

  @override
  State<_LeaveDetailsSheet> createState() => _LeaveDetailsSheetState();
}

class _LeaveDetailsSheetState extends State<_LeaveDetailsSheet> {
  bool showFullDetails = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF182237);
    final muted = dark ? const Color(0xFFA4ADBC) : const Color(0xFF89919D);
    final divider = dark ? const Color(0xFF303D50) : const Color(0xFFE9EDF4);
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .91),
      decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Center(
              child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: divider,
                      borderRadius: BorderRadius.circular(99)))),
          Flexible(
              child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Leave details',
                          style: TextStyle(
                              color: ink,
                              fontSize: 21,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                          widget.date == null
                              ? 'Leave request'
                              : DateFormat('EEEE, d MMM yyyy')
                                  .format(widget.date!),
                          style: TextStyle(color: muted, fontSize: 12)),
                    ])),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: muted)),
              ]),
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.event_available_outlined,
                    color: Color(0xFF1769E8), size: 22),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(widget.leaveType,
                        style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                _LeaveStatusPill(
                    label: widget.status, color: widget.statusColor),
              ]),
              const SizedBox(height: 20),
              Divider(color: divider, height: 1),
              if (widget.reason.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Reason',
                    style: TextStyle(
                        color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(widget.reason,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 18),
                Divider(color: divider, height: 1),
              ],
              const SizedBox(height: 16),
              Text('Full request details',
                  style: TextStyle(
                      color: ink, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 5),
              Text('Covering employees, approval steps and available actions',
                  style: TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => showFullDetails = !showFullDetails),
                    icon: Icon(
                        showFullDetails
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18),
                    label: Text(showFullDetails
                        ? 'Hide full details'
                        : 'View full details & actions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1769E8),
                      side: BorderSide(color: divider),
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                    ),
                  )),
              if (showFullDetails) ...[
                const SizedBox(height: 16),
                LeaveReportCard(
                    leave: widget.leave, controller: widget.controller),
              ],
            ]),
          )),
        ]),
      ),
    );
  }
}

// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:corehris/modules/HRMS/main_screens/reports/controllers/attendance_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance_adjustment_picker.dart';

class AttendanceReportScreen extends StatelessWidget {
  AttendanceReportScreen({super.key});

  final AttendanceReportController controller =
      Get.put(AttendanceReportController());

  // Day keeps the familiar date-left cards; Month uses circular status markers.
  final RxString _viewMode = 'day'.obs;
  final Rxn<DateTime> _selectedDay = Rxn<DateTime>();
  final Rx<DateTime> _focusedDate = DateTime.now().obs;

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _weekStart(DateTime d) =>
      _onlyDate(d).subtract(Duration(days: d.weekday - DateTime.monday));

  DateTime? _recordDate(Map<String, dynamic> row) {
    final value = row['date'] ?? row['work_date_local'];
    return DateTime.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic>? _recordForDay(DateTime day) {
    for (final row in controller.attendanceData) {
      final date = _recordDate(row);
      if (date != null && _sameDate(date, day)) return row;
    }
    return null;
  }

  /// Each view owns the date range that it asks the backend to load.
  /// Day: employee chooses a range (last 7 days or this month).
  /// Week: Monday through Sunday of the focused week.
  /// Month: every calendar date in the focused month.
  Future<void> _setMode(String mode) async {
    if (_viewMode.value == mode) return;
    _viewMode.value = mode;
    _selectedDay.value = null;

    switch (mode) {
      case 'day':
        await _loadDayLastSevenDays();
        break;
      case 'week':
        await _loadWeek(_focusedDate.value);
        break;
      case 'month':
        await _loadMonth(_focusedDate.value);
        break;
    }
  }

  Future<void> _loadDayLastSevenDays() async {
    _selectedDay.value = null;
    await controller.setLastSevenDays();
  }

  Future<void> _loadDayCurrentMonth() async {
    _selectedDay.value = null;
    await controller.setCurrentMonth();
  }

  Future<void> _loadWeek(DateTime date) async {
    _focusedDate.value = _onlyDate(date);
    final start = _weekStart(date);
    final end = start.add(const Duration(days: 6));
    await controller.setDateRange(start: start, end: end);
  }

  Future<void> _loadMonth(DateTime date) async {
    _focusedDate.value = DateTime(date.year, date.month, 1);
    final first = DateTime(date.year, date.month, 1);
    final last = DateTime(date.year, date.month + 1, 0);
    await controller.setDateRange(start: first, end: last);
  }

  Future<void> _movePeriod(int amount) async {
    if (_viewMode.value == 'month') {
      final focused = _focusedDate.value;
      await _loadMonth(DateTime(focused.year, focused.month + amount, 1));
    } else if (_viewMode.value == 'week') {
      await _loadWeek(_focusedDate.value.add(Duration(days: amount * 7)));
    }
  }

  // Calendar / week date tap uses the date already fetched for that period.
  // No additional request is needed until the employee changes the Day filters.
  void _openDay(DateTime date) {
    _selectedDay.value = _onlyDate(date);
    _focusedDate.value = _onlyDate(date);
    _viewMode.value = 'day';
  }

  Future<void> _backToCalendar() async {
    _selectedDay.value = null;
    _viewMode.value = 'month';
    await _loadMonth(_focusedDate.value);
  }

  Future<void> _refreshCurrentView() async {
    // The controller's current range is maintained by each of the loaders.
    await controller.refreshAttendance();
  }

  Future<void> _pickDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final initialDate = isStart
        ? controller.startDate.value ?? DateTime.now()
        : controller.endDate.value ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primary2,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    if (_viewMode.value != 'day') return;
    _selectedDay.value = null;
    if (isStart) {
      await controller.setStartDate(picked);
    } else {
      await controller.setEndDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshCurrentView,
                  color: AppColors.primary2,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildViewSwitcher(context)),
                      Obx(() => SliverToBoxAdapter(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                    sizeFactor: animation, child: child),
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(
                                    '${_viewMode.value}-${_selectedDay.value}'),
                                child: _viewMode.value == 'month'
                                    ? _buildMonthCalendar(context)
                                    : _viewMode.value == 'week'
                                        ? _buildWeekStrip(context)
                                        : Column(children: [
                                            _buildDateFilters(context),
                                            _buildQuickFilters(context),
                                            if (_selectedDay.value == null)
                                              _buildSummarySection(context)
                                            else
                                              _selectedDayHeader(context),
                                          ]),
                              ),
                            ),
                          )),
                      Obx(() {
                        if (controller.isLoading.value) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildLoadingState(context),
                          );
                        }

                        if (controller.hasError.value) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildErrorState(context),
                          );
                        }

                        if (_viewMode.value == 'month') {
                          return const SliverToBoxAdapter(
                            child: SizedBox(height: 18),
                          );
                        }

                        final rows = controller.attendanceData.where((row) {
                          final day = _recordDate(row);
                          if (day == null) return false;
                          if (_viewMode.value == 'day') {
                            final selected = _selectedDay.value;
                            return selected == null || _sameDate(day, selected);
                          }
                          final begin = _weekStart(_focusedDate.value);
                          final end = begin.add(const Duration(days: 6));
                          return !day.isBefore(begin) && !day.isAfter(end);
                        }).toList();

                        if (rows.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(context),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final record = rows[index];
                                return _AttendanceRecordCard(
                                  record: record,
                                  onTap: () =>
                                      _showAttendanceDetails(context, record),
                                );
                              },
                              childCount: rows.length,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewSwitcher(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1B2638) : const Color(0xFFE8EDF5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              _modeButton('day', 'Day', Icons.view_agenda_outlined),
              _modeButton('week', 'Week', Icons.view_week_outlined),
              _modeButton('month', 'Month', Icons.calendar_month_outlined),
            ]),
          ),
        ));
  }

  Widget _modeButton(String mode, String name, IconData icon) {
    final active = _viewMode.value == mode;
    return Expanded(
        child: InkWell(
      onTap: () => _setMode(mode),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1769E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 16, color: active ? Colors.white : const Color(0xFF89919D)),
          const SizedBox(width: 6),
          Text(name,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF89919D))),
        ]),
      ),
    ));
  }

  Widget _selectedDayHeader(BuildContext context) {
    final selected = _selectedDay.value!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(children: [
        const Icon(Icons.event_available_outlined,
            size: 19, color: Color(0xFF1769E8)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(DateFormat('EEEE, dd MMM yyyy').format(selected),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : const Color(0xFF182237)))),
        TextButton(
          onPressed: _backToCalendar,
          child: const Text('Calendar'),
        ),
      ]),
    );
  }

  Widget _periodHeader(BuildContext context, String title, String subtitle) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      IconButton(
          onPressed: () => _movePeriod(-1),
          icon: const Icon(Icons.chevron_left_rounded)),
      Expanded(
          child: Column(children: [
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : const Color(0xFF182237))),
        if (subtitle.isNotEmpty)
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF89919D))),
      ])),
      IconButton(
          onPressed: () => _movePeriod(1),
          icon: const Icon(Icons.chevron_right_rounded)),
    ]);
  }

  Widget _buildMonthCalendar(BuildContext context) {
    final focused = _focusedDate.value;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final first = DateTime(focused.year, focused.month, 1);
    final days = DateTime(focused.year, focused.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = ((offset + days + 6) ~/ 7) * 7;
    final today = _onlyDate(DateTime.now());
    final ink = dark ? Colors.white : const Color(0xFF182237);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1B2638) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: dark ? Colors.white12 : const Color(0xFFE7EDF5)),
        ),
        child: Column(children: [
          _periodHeader(context, DateFormat('MMMM yyyy').format(focused),
              'Tap a date to view attendance'),
          const SizedBox(height: 15),
          Row(children: [
            for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                  child: Center(
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF89919D))))),
          ]),
          const SizedBox(height: 9),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final number = index - offset + 1;
              if (number < 1 || number > days) return const SizedBox.shrink();
              final date = DateTime(focused.year, focused.month, number);
              final record = _recordForDay(date);
              final hasRecord = record != null;
              final status = hasRecord
                  ? _statusData(
                      _safeText(record['status'], fallback: 'No attendance'))
                  : null;
              final isToday = _sameDate(date, today);
              final color = status?.foregroundColor ?? const Color(0xFFB6C1CE);
              return InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () => _openDay(date),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 230),
                        width: 35,
                        height: 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasRecord
                              ? color.withOpacity(dark ? 0.24 : 0.12)
                              : Colors.transparent,
                          border: isToday
                              ? Border.all(
                                  color: const Color(0xFF1769E8), width: 1.4)
                              : null,
                        ),
                        child: Text('$number',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: hasRecord ? color : ink,
                                fontWeight: hasRecord || isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasRecord ? color : Colors.transparent)),
                    ]),
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
              spacing: 14,
              runSpacing: 7,
              alignment: WrapAlignment.center,
              children: [
                _legend('Present', const Color(0xFF16A34A)),
                _legend('Late', const Color(0xFFD97706)),
                _legend('Absent', const Color(0xFFDC2626)),
                _legend('Pending', const Color(0xFFCA8A04)),
              ]),
        ]),
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF89919D))),
        ],
      );

  Widget _buildWeekStrip(BuildContext context) {
    final start = _weekStart(_focusedDate.value);
    final end = start.add(const Duration(days: 6));
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1B2638) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: dark ? Colors.white12 : const Color(0xFFE7EDF5)),
        ),
        child: Column(children: [
          _periodHeader(
              context,
              '${DateFormat('dd MMM').format(start)} – ${DateFormat('dd MMM').format(end)}',
              'Select a day to see details'),
          const SizedBox(height: 12),
          Row(
              children: List.generate(7, (index) {
            final date = start.add(Duration(days: index));
            final record = _recordForDay(date);
            final status = record == null
                ? null
                : _statusData(
                    _safeText(record['status'], fallback: 'No attendance'));
            return Expanded(
                child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDay(date),
              child: Column(children: [
                Text(DateFormat('E').format(date).substring(0, 1),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF89919D))),
                const SizedBox(height: 6),
                Container(
                  width: 35,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: status?.foregroundColor.withOpacity(0.12) ??
                          Colors.transparent),
                  child: Text('${date.day}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: status?.foregroundColor ??
                              (dark ? Colors.white : const Color(0xFF182237)))),
                ),
              ]),
            ));
          })),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF2F6BFF),
            Color(0xFF4F46E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: Get.back,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Report',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Review attendance, working time and locations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              _headerIconButton(
                icon: Icons.refresh_rounded,
                onTap: _refreshCurrentView,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(
      () => Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary2.withOpacity(0.10),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primary2,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeText(
                      controller.employeeName.value,
                      fallback: 'Employee',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _safeText(
                      controller.username.value,
                      fallback: 'Employee number unavailable',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _DateSelector(
                label: 'Start Date',
                date: controller.startDate.value,
                onTap: () => _pickDate(
                  context,
                  isStart: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(
              () => _DateSelector(
                label: 'End Date',
                date: controller.endDate.value,
                onTap: () => _pickDate(
                  context,
                  isStart: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _QuickFilterButton(
              label: 'Last 7 Days',
              icon: Icons.date_range_rounded,
              onTap: _loadDayLastSevenDays,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickFilterButton(
              label: 'This Month',
              icon: Icons.calendar_view_month_rounded,
              onTap: _loadDayCurrentMonth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF182237);

    final mutedColor =
        isDark ? const Color(0xFF9BA7B8) : const Color(0xFF89919D);

    final dividerColor =
        isDark ? const Color(0xFF303D50) : const Color(0xFFE8ECF2);

    return Obx(() {
      final stats = [
        ('Records', controller.totalRecords.value),
        ('Present', controller.presentDays.value),
        ('Late', controller.lateDays.value),
        ('Absent', controller.absentDays.value),
        ('Incomplete', controller.incompleteDays.value),
      ];

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(stats.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Container(
                width: 1,
                height: 30,
                color: dividerColor,
              );
            }

            final stat = stats[index ~/ 2];

            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stat.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${stat.$2}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    });
  }

  /// Shows only the essentials first. Diagnostics are opt-in so employees do
  /// not need to scroll through technical fields to request a correction.
  void _showAttendanceDetails(
    BuildContext reportContext,
    Map<String, dynamic> record,
  ) {
    final status = _safeText(
        _recordValue(record, const ['status', 'attendance_status']),
        fallback: 'No attendance');
    final statusData = _statusData(status);
    bool expanded = false;

    showModalBottomSheet<void>(
      context: reportContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final theme = Theme.of(sheetContext);
          final dark = theme.brightness == Brightness.dark;
          final surface = dark ? const Color(0xFF1B2638) : Colors.white;
          final muted =
              dark ? const Color(0xFFA4AFC0) : const Color(0xFF89919D);
          final border =
              dark ? const Color(0xFF303C50) : const Color(0xFFE8EDF4);
          final ink = dark ? Colors.white : const Color(0xFF182237);
          final height = MediaQuery.sizeOf(sheetContext).height;

          Widget line(IconData icon, String label, String value,
              {bool last = false}) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFF1769E8)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(label,
                              style: TextStyle(color: muted, fontSize: 12))),
                      Flexible(
                          child: Text(value,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
                if (!last) Divider(color: border, height: 1),
              ],
            );
          }

          final checkIn = _recordValue(
              record, const ['check_in_time', 'checkIN_time', 'checkin_time']);
          final checkOut = _recordValue(record,
              const ['check_out_time', 'checkOUT_time', 'checkout_time']);
          final worked =
              _recordValue(record, const ['worked_minutes', 'workedMinutes']);
          final late =
              _recordValue(record, const ['late_minutes', 'lateMinutes']);
          final early = _recordValue(record,
              const ['early_departure_minutes', 'earlyDepartureMinutes']);
          final ot = _recordValue(
              record, const ['overtime_minutes', 'overtimeMinutes', 'OT']);
          final workDate = _recordValue(
              record, const ['date', 'work_date_local', 'work_date']);

          final diagnosticGroups = <Widget>[
            const SizedBox(height: 20),
            Text('Punch Information',
                style: TextStyle(
                    color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            line(
                Icons.login_outlined,
                'Check In Source',
                _safeText(_recordValue(
                    record, const ['checkIN_source', 'check_in_source']))),
            line(
                Icons.logout_outlined,
                'Check Out Source',
                _safeText(_recordValue(
                    record, const ['checkOUT_source', 'check_out_source']))),
            line(
                Icons.devices_outlined,
                'Check In Mode',
                _safeText(_recordValue(
                    record, const ['checkIN_mode', 'check_in_mode']))),
            line(
                Icons.devices_outlined,
                'Check Out Mode',
                _safeText(_recordValue(
                    record, const ['checkOUT_mode', 'check_out_mode']))),
            line(
                Icons.compare_arrows_rounded,
                'Mixed Source',
                _displayNullableBool(_recordValue(
                    record, const ['is_mixed_source', 'isMixedSource']))),
            line(
                Icons.login_rounded,
                'Missing Check In',
                _displayNullableBool(_recordValue(record,
                    const ['is_missing_checkin', 'is_missing_check_in']))),
            line(
                Icons.logout_rounded,
                'Missing Check Out',
                _displayNullableBool(_recordValue(record,
                    const ['is_missing_checkout', 'is_missing_check_out'])),
                last: true),
            const SizedBox(height: 20),
            Text('Authorization',
                style: TextStyle(
                    color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            line(
                Icons.verified_user_outlined,
                'Overall Authorization',
                _safeText(
                    _recordValue(record, const ['authorization_status']))),
            line(
                Icons.login_rounded,
                'Check In Authorization',
                _safeText(_recordValue(record, const [
                  'checkIN_authorization_status',
                  'check_in_authorization_status'
                ]))),
            line(
                Icons.logout_rounded,
                'Check Out Authorization',
                _safeText(_recordValue(record, const [
                  'checkOUT_authorization_status',
                  'check_out_authorization_status'
                ]))),
            line(
                Icons.location_on_outlined,
                'Authorized Location',
                _displayNullableBool(
                    _recordValue(record, const ['is_authorized_location'])),
                last: true),
            const SizedBox(height: 20),
            Text('Location Details',
                style: TextStyle(
                    color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            line(
                Icons.place_outlined,
                'Check In Address',
                _safeText(_recordValue(
                    record, const ['check_in_address', 'checkIN_address']))),
            line(
                Icons.place_outlined,
                'Check Out Address',
                _safeText(_recordValue(
                    record, const ['check_out_address', 'checkOUT_address'])),
                last: true),
          ];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: height * (expanded ? 0.91 : 0.60),
            decoration: BoxDecoration(
              color: surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                      child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                              color: border,
                              borderRadius: BorderRadius.circular(99)))),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_formatDate(workDate),
                                      style: TextStyle(
                                          color: ink,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 7),
                                  _StatusChip(
                                    label: statusData.label,
                                    foregroundColor: statusData.foregroundColor,
                                    backgroundColor: statusData.backgroundColor,
                                  ),
                                ],
                              )),
                              IconButton(
                                icon: Icon(Icons.close_rounded, color: muted),
                                tooltip: 'Close',
                                onPressed: () => Navigator.pop(sheetContext),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text('Time Summary',
                              style: TextStyle(
                                  color: ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          line(Icons.login_rounded, 'Check In',
                              _formatTime(checkIn)),
                          line(Icons.logout_rounded, 'Check Out',
                              _formatTime(checkOut)),
                          line(Icons.schedule_outlined, 'Worked Time',
                              _formatMinutes(worked),
                              last: !expanded),
                          if (expanded) ...[
                            line(Icons.access_time_outlined, 'Late Time',
                                _formatMinutes(late)),
                            line(Icons.directions_run_outlined,
                                'Early Departure', _formatMinutes(early)),
                            line(Icons.more_time_rounded, 'Overtime',
                                _formatMinutes(ot),
                                last: true),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setSheetState(() => expanded = !expanded),
                              icon: Icon(expanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded),
                              label: Text(
                                  expanded ? 'Show less' : 'Show more details'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1769E8),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                          if (expanded) ...diagnosticGroups,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border(top: BorderSide(color: border)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1769E8),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        icon:
                            const Icon(Icons.edit_calendar_outlined, size: 18),
                        label: const Text('Request Attendance Adjustment',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12.5)),
                        onPressed: () async {
                          final date = DateTime.tryParse(workDate);
                          if (date == null) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'A valid attendance date is required.')),
                            );
                            return;
                          }
                          Navigator.of(sheetContext).pop();
                          // The report context survives the dismissed bottom sheet.
                          if (!reportContext.mounted) return;
                          final changed = await AttendanceAdjustmentPicker.open(
                            context: reportContext,
                            date: date,
                            attendance: record,
                            employeeNo: controller.username.value,
                            employeeName: controller.employeeName.value,
                          );
                          if (changed) await controller.refreshAttendance();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Read API aliases without turning absent data into a fabricated value.
  static dynamic _recordValue(Map<String, dynamic> record, List<String> keys) {
    for (final key in keys) {
      final value = record[key];
      if (value == null) continue;
      if (value is String &&
          (value.trim().isEmpty || value.trim().toLowerCase() == 'null')) {
        continue;
      }
      return value;
    }
    return null;
  }

  static String _displayNullableBool(dynamic value) {
    final parsed = _toNullableBool(value);
    return parsed == null ? 'Not available' : (parsed ? 'Yes' : 'No');
  }

  Widget _buildDetailsHeader(
    BuildContext context, {
    required Map<String, dynamic> record,
    required _AttendanceStatusData statusData,
  }) {
    final theme = Theme.of(context);

    final employeeName = _safeText(
      record['employee_fullname'],
      fallback: controller.employeeName.value,
    );

    final employeeNumber = _safeText(
      record['employee_no'],
      fallback: controller.username.value,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: statusData.backgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            statusData.icon,
            color: statusData.foregroundColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(record['date'] ?? record['work_date_local']),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$employeeName • $employeeNumber',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.68),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              _StatusChip(
                label: statusData.label,
                foregroundColor: statusData.foregroundColor,
                backgroundColor: statusData.backgroundColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary2),
            const SizedBox(height: 16),
            Text(
              'Loading attendance records...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load attendance',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: controller.refreshAttendance,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary2,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: Color(0xFF2563EB),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No attendance records',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No records were found for the selected date range.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }

  Widget _detailsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.045) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String trailing = '',
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.68),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _safeText(value),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing.trim().isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary2.withOpacity(0.09),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                trailing,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary2,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailBooleanRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required dynamic value,
    bool negativeIsGood = false,
  }) {
    final bool? booleanValue = _toNullableBool(value);

    String displayValue;
    Color color;

    if (booleanValue == null) {
      displayValue = 'Not available';
      color = const Color(0xFF64748B);
    } else if (booleanValue) {
      displayValue = 'Yes';
      color =
          negativeIsGood ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    } else {
      displayValue = 'No';
      color =
          negativeIsGood ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    }

    return Row(
      children: [
        _detailIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            displayValue,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressBlock(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String authorizationStatus,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.68),
                      ),
                    ),
                  ),
                  if (authorizationStatus.isNotEmpty)
                    _AuthorizationChip(status: authorizationStatus),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary2.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 18,
        color: AppColors.primary2,
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        color:
            isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _headerIconButton({
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
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }

  static _AttendanceStatusData _statusData(String value) {
    final status = value.toLowerCase();

    if (status.contains('no attendance')) {
      return const _AttendanceStatusData(
        label: 'No Attendance',
        icon: Icons.event_busy_rounded,
        foregroundColor: Color(0xFF64748B),
        backgroundColor: Color(0xFFE2E8F0),
      );
    }

    if (status.contains('incomplete') || status.contains('missing')) {
      return const _AttendanceStatusData(
        label: 'Incomplete',
        icon: Icons.warning_amber_rounded,
        foregroundColor: Color(0xFFEA580C),
        backgroundColor: Color(0xFFFFEDD5),
      );
    }

    if (status.contains('late')) {
      return const _AttendanceStatusData(
        label: 'Late',
        icon: Icons.schedule_rounded,
        foregroundColor: Color(0xFFD97706),
        backgroundColor: Color(0xFFFEF3C7),
      );
    }

    if (status.contains('short')) {
      return const _AttendanceStatusData(
        label: 'Short Leave',
        icon: Icons.trending_down_rounded,
        foregroundColor: Color(0xFFEA580C),
        backgroundColor: Color(0xFFFFEDD5),
      );
    }

    if (status.contains('half')) {
      return const _AttendanceStatusData(
        label: 'Half Day',
        icon: Icons.hourglass_bottom_rounded,
        foregroundColor: Color(0xFFD97706),
        backgroundColor: Color(0xFFFEF3C7),
      );
    }

    if (status.contains('absent')) {
      return const _AttendanceStatusData(
        label: 'Absent',
        icon: Icons.cancel_rounded,
        foregroundColor: Color(0xFFDC2626),
        backgroundColor: Color(0xFFFEE2E2),
      );
    }

    if (status.contains('leave')) {
      return const _AttendanceStatusData(
        label: 'Leave',
        icon: Icons.event_available_rounded,
        foregroundColor: Color(0xFF7C3AED),
        backgroundColor: Color(0xFFEDE9FE),
      );
    }

    if (status.contains('pending')) {
      return const _AttendanceStatusData(
        label: 'Pending',
        icon: Icons.pending_actions_rounded,
        foregroundColor: Color(0xFFCA8A04),
        backgroundColor: Color(0xFFFEF9C3),
      );
    }

    return const _AttendanceStatusData(
      label: 'Present',
      icon: Icons.check_circle_rounded,
      foregroundColor: Color(0xFF16A34A),
      backgroundColor: Color(0xFFDCFCE7),
    );
  }

  static String _safeText(
    dynamic value, {
    String fallback = '--',
  }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'undefined') {
      return fallback;
    }

    return text;
  }

  static String _formatDate(dynamic value) {
    final raw = _safeText(value, fallback: '');

    if (raw.isEmpty) {
      return 'No attendance date';
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    return DateFormat('EEE, dd MMM yyyy').format(date);
  }

  static String _formatShortDate(dynamic value) {
    final raw = _safeText(value, fallback: '');

    if (raw.isEmpty) {
      return 'No date';
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    return DateFormat('dd MMM yyyy').format(date);
  }

  static String _formatTime(dynamic value) {
    final raw = _safeText(value, fallback: '');

    if (raw.isEmpty) {
      return '--';
    }

    try {
      final parsedDateTime = DateTime.tryParse(raw);

      if (parsedDateTime != null && raw.contains('-')) {
        return DateFormat('hh:mm a').format(parsedDateTime.toLocal());
      }

      final timeParts = raw.split(':');

      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);

        if (hour != null && minute != null) {
          final dateTime = DateTime(2000, 1, 1, hour, minute);

          return DateFormat('hh:mm a').format(dateTime);
        }
      }
    } catch (_) {}

    return raw;
  }

  static String _formatMinutes(dynamic value) {
    if (value == null) {
      return '--';
    }

    final totalMinutes = value is num
        ? value.round()
        : double.tryParse(value.toString())?.round();

    if (totalMinutes == null) {
      return '--';
    }

    if (totalMinutes <= 0) {
      return '0 min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '$minutes min';
    }

    if (minutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $minutes min';
  }

  static String _resolveOvertime(Map<String, dynamic> record) {
    final overtimeMinutes = record['overtime_minutes'];

    if (overtimeMinutes != null) {
      return _formatMinutes(overtimeMinutes);
    }

    return _safeText(record['OT']);
  }

  static bool? _toNullableBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value.toString().trim().toLowerCase();

    if (['true', '1', 'yes', 'authorized'].contains(normalized)) {
      return true;
    }

    if (['false', '0', 'no', 'unauthorized'].contains(normalized)) {
      return false;
    }

    return null;
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onTap;

  const _AttendanceRecordCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF4F7FC) : const Color(0xFF182237);
    final muted = dark ? const Color(0xFF98A6BC) : const Color(0xFF89919D);
    final border = dark ? const Color(0xFF303D50) : const Color(0xFFE7EDF5);

    final status = AttendanceReportScreen._safeText(
      record['status'],
      fallback: 'No attendance',
    );
    final statusData = AttendanceReportScreen._statusData(status);
    final checkIn = AttendanceReportScreen._formatTime(record['check_in_time']);
    final checkOut =
        AttendanceReportScreen._formatTime(record['check_out_time']);
    final worked =
        AttendanceReportScreen._formatMinutes(record['worked_minutes']);
    final missingIn =
        AttendanceReportScreen._toNullableBool(record['is_missing_checkin']) ??
            false;
    final missingOut =
        AttendanceReportScreen._toNullableBool(record['is_missing_checkout']) ??
            false;
    final mixed =
        AttendanceReportScreen._toNullableBool(record['is_mixed_source']) ??
            false;

    // Date is intentionally outside the card, matching Leave Requests.
    final rawDate = AttendanceReportScreen._safeText(
        record['date'] ?? record['work_date_local'],
        fallback: '');
    final parsedDate = DateTime.tryParse(rawDate);
    final day = parsedDate == null ? '--' : DateFormat('dd').format(parsedDate);

    final weekday = parsedDate == null
        ? '---'
        : DateFormat('EEE').format(parsedDate).toUpperCase();

    final month = parsedDate == null
        ? '---'
        : DateFormat('MMM').format(parsedDate).toUpperCase();

    final year =
        parsedDate == null ? '' : DateFormat('yyyy').format(parsedDate);

    final tint = statusData.foregroundColor;
    final cardColor = Color.alphaBlend(
      tint.withOpacity(dark ? 0.13 : 0.095),
      dark ? const Color(0xFF1B2638) : Colors.white,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 49,
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Column(
                children: [
                  Text(day,
                      style: TextStyle(
                          color: ink,
                          fontSize: 21,
                          height: 1.05,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(weekday,
                      style: const TextStyle(
                          color: Color(0xFF1769E8),
                          fontSize: 10,
                          letterSpacing: 0.35,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(month,
                      style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(year,
                      style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: cardColor,
              borderRadius: BorderRadius.circular(19),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    border:
                        Border.all(color: tint.withOpacity(dark ? 0.20 : 0.10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tint.withOpacity(dark ? 0.20 : 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(statusData.icon, color: tint, size: 19),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(statusData.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text('Attendance status',
                                    style: TextStyle(
                                        color: muted, fontSize: 10.5)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 19, color: muted),
                        ],
                      ),
                      if (mixed || missingIn || missingOut) ...[
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            if (mixed)
                              const _StatusChip(
                                label: 'Mixed Source',
                                foregroundColor: Color(0xFF7C3AED),
                                backgroundColor: Color(0xFFEDE9FE),
                              ),
                            if (missingIn || missingOut)
                              const _StatusChip(
                                label: 'Missing Punch',
                                foregroundColor: Color(0xFFDC2626),
                                backgroundColor: Color(0xFFFEE2E2),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 11),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF202B3B)
                              : Colors.white.withOpacity(0.83),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: _TimeBox(
                              title: 'Check In',
                              value: checkIn,
                              icon: Icons.login_rounded,
                            )),
                            Container(height: 28, width: 1, color: border),
                            Expanded(
                                child: _TimeBox(
                              title: 'Check Out',
                              value: checkOut,
                              icon: Icons.logout_rounded,
                            )),
                            Container(height: 28, width: 1, color: border),
                            Expanded(
                                child: _TimeBox(
                              title: 'Worked',
                              value: worked,
                              icon: Icons.schedule_rounded,
                            )),
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

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.primary2.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary2,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date == null
                          ? 'Select'
                          : DateFormat('dd MMM yyyy').format(date!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickFilterButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary2.withOpacity(0.12)
                : AppColors.primary2.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.primary2,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary2,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 122,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: foregroundColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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

class _TimeBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _TimeBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? const Color(0xFF98A6BC) : const Color(0xFF89919D);
    final ink = dark ? Colors.white : const Color(0xFF182237);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: muted, fontSize: 9.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(
                    color: ink, fontSize: 11.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _SourceLabel extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SourceLabel({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sensors_rounded,
            size: 14,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorizationChip extends StatelessWidget {
  final String status;

  const _AuthorizationChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final bool authorized = normalized.contains('authorized') &&
        !normalized.contains('unauthorized');

    final bool mixed = normalized.contains('mixed');

    final foregroundColor = mixed
        ? const Color(0xFF7C3AED)
        : authorized
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);

    final backgroundColor = mixed
        ? const Color(0xFFEDE9FE)
        : authorized
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _StatusChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AttendanceStatusData {
  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _AttendanceStatusData({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });
}

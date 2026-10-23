// ignore_for_file: depend_on_referenced_packages, avoid_print, deprecated_member_use

import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';

import 'package:corehris/theme/theme.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:table_calendar/table_calendar.dart';

import '../../../../auth/authservices.dart';

import 'leave_request_page.dart';

import 'package:corehris/components/leavedata.dart' as model;

/* ================================================================

                        ENUM

================================================================ */

enum HalfDayType { morning, evening }

/* ================================================================

                        PAGE

================================================================ */

class LeavesCalendarPage extends StatelessWidget {
  final LeaveCalendarController controller = Get.put(LeaveCalendarController());

  LeavesCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        controller.navigateBackToDashboard();

        return false;
      },
      child: Scaffold(
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF111318)
            : const Color(0xFFF8FAFD),
        appBar: AppBar(
          title: const Text('Apply Leave',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF111318)
              : const Color(0xFFF8FAFD),
          foregroundColor: theme.appBarTheme.foregroundColor ?? cs.onBackground,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth =
                constraints.maxWidth >= 720 ? 640.0 : constraints.maxWidth;

            final horizontalPadding = constraints.maxWidth < 360 ? 14.0 : 18.0;

            return Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: cs.primary),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.fetchLeaves,
                      color: cs.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          24,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LeaveHeader(controller: controller),
                                const SizedBox(height: 14),
                                _CalendarPanel(controller: controller),
                                const SizedBox(height: 18),
                                _SelectedDatesSection(controller: controller),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _ContinueBar(controller: controller),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}

class _LeaveHeader extends StatelessWidget {
  final LeaveCalendarController controller;
  const _LeaveHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? const Color(0xFF97A0AF) : const Color(0xFF7E899B);
    final ink = dark ? Colors.white : const Color(0xFF152238);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PLAN YOUR TIME',
                    style: TextStyle(
                      color: Color(0xFF1769E8),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.35,
                    )),
                const SizedBox(height: 8),
                Text('Choose your days',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -0.8,
                      color: ink,
                    )),
                const SizedBox(height: 6),
                Text('Tap any date to plan your leave.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12.5,
                    )),
              ],
            ),
          ),
          Obx(() => _CountPill(
                count: controller.selectedDates.length,
                label: controller.selectedDates.length == 1 ? 'day' : 'days',
              )),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;

  final String label;

  const _CountPill({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(
          theme.brightness == Brightness.dark ? 0.22 : 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: cs.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: cs.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  final LeaveCalendarController controller;
  const _CalendarPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF7F8FC) : const Color(0xFF14213A);
    final surface = dark ? const Color(0xFF181C24) : Colors.white;
    return Column(
      children: [
        Obx(() {
          final month = controller.focusedDay.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _monthArrow(context, Icons.chevron_left_rounded, () {
                final current = controller.focusedDay.value;
                controller.focusedDay.value =
                    DateTime(current.year, current.month - 1, 1);
              }),
              Column(children: [
                Text(DateFormat('MMMM').format(month),
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      letterSpacing: -1.0,
                    )),
                Text(DateFormat('yyyy').format(month),
                    style: TextStyle(
                      color: dark ? Colors.white54 : const Color(0xFF8692A5),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    )),
              ]),
              _monthArrow(context, Icons.chevron_right_rounded, () {
                final current = controller.focusedDay.value;
                controller.focusedDay.value =
                    DateTime(current.year, current.month + 1, 1);
              }),
            ],
          );
        }),
        const SizedBox(height: 20),
        // Use TableCalendar as the calendar engine; keep its existing
        // multi-date selection and bottom-sheet callbacks untouched.
        Container(
          padding: const EdgeInsets.fromLTRB(3, 8, 3, 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
                color:
                    dark ? const Color(0xFF2A303B) : const Color(0xFFF0F2F6)),
          ),
          child: Obx(() => _ThemedCalendar(controller: controller)),
        ),
      ],
    );
  }

  Widget _monthArrow(
      BuildContext context, IconData icon, VoidCallback callback) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF252A34) : const Color(0xFFF0F4FA),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: callback,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
            width: 43,
            height: 43,
            child: Icon(icon,
                color: dark ? Colors.white : const Color(0xFF344054))),
      ),
    );
  }
}

class _SelectedDatesSection extends StatelessWidget {
  final LeaveCalendarController controller;

  const _SelectedDatesSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Selected Dates',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: cs.onBackground,
                ),
              ),
            ),
            Obx(
              () => Text(
                '${controller.selectedDates.length} selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onBackground.withOpacity(0.56),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.selectedDates.isEmpty) {
            return const _EmptySelectionCard();
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey(controller.selectedDates.length),
              children: controller.sortedSelectedDates.map((date) {
                final info = controller.getDateDetail(date);

                return _SelectedDateCard(
                  date: date,
                  info: info,
                  onEdit: () => controller.editSelectedDate(context, date),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}

class _EmptySelectionCard extends StatelessWidget {
  const _EmptySelectionCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(isDark ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.touch_app_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap a date on the calendar to choose leave details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onBackground.withOpacity(0.66),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  final LeaveCalendarController controller;

  const _ContinueBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor.withOpacity(0.30)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.09),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.selectedDates.isEmpty
                    ? null
                    : controller.navigateToRequestPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  disabledBackgroundColor: cs.primary.withOpacity(0.34),
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  controller.selectedDates.isEmpty
                      ? 'Select dates to continue'
                      : 'Continue with ${controller.selectedDates.length} ${controller.selectedDates.length == 1 ? 'day' : 'days'}',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ================================================================

                        THEMED CALENDAR WIDGET

================================================================ */

class _ThemedCalendar extends StatelessWidget {
  final LeaveCalendarController controller;
  const _ThemedCalendar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF5F7FB) : const Color(0xFF1D2939);
    final muted = dark ? const Color(0xFF8D95A5) : const Color(0xFF98A2B3);
    final width = MediaQuery.of(context).size.width;
    return TableCalendar(
      key: const ValueKey('talexa_leave_month_grid'),
      focusedDay: controller.focusedDay.value,
      firstDay: DateTime(DateTime.now().year - 1),
      lastDay: DateTime(DateTime.now().year + 1),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      sixWeekMonthsEnforced: false,
      rowHeight: width < 360 ? 51 : 57,
      daysOfWeekHeight: 32,
      availableGestures: AvailableGestures.horizontalSwipe,
      selectedDayPredicate: controller.isSelected,
      onDaySelected: (day, _) => controller.onDayTapped(day),
      onPageChanged: (day) => controller.focusedDay.value = day,
      headerVisible: false,
      calendarStyle: const CalendarStyle(outsideDaysVisible: false),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle:
            TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700),
        weekendStyle:
            TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) => _dayCell(context, day),
        todayBuilder: (context, day, focusedDay) =>
            _dayCell(context, day, today: true),
        selectedBuilder: (context, day, focusedDay) =>
            _dayCell(context, day, selected: true),
        outsideBuilder: (context, day, focusedDay) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _dayCell(BuildContext context, DateTime date,
      {bool selected = false, bool today = false}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = selected || controller.isSelected(date);
    final bg = active
        ? (dark ? const Color(0xFF1769E8) : const Color(0xFFEAF2FF))
        : dark
            ? const Color(0xFF22262D)
            : const Color(0xFFF7F9FC);
    final foreground = active
        ? (dark ? Colors.white : const Color(0xFF1769E8))
        : (dark ? const Color(0xFFF1F3F7) : const Color(0xFF1D2939));
    final border = active
        ? const Color(0xFF1769E8)
        : today
            ? (dark ? const Color(0xFF678FD4) : const Color(0xFFBCD4F9))
            : (dark ? const Color(0xFF333941) : const Color(0xFFE9EDF3));
    return Container(
      margin: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border, width: active ? 1.5 : 0.8),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 6, 0, 0),
              child: Text('${date.day}',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight:
                        active || today ? FontWeight.w800 : FontWeight.w600,
                  )),
            ),
          ),
          if (active)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: dark ? Colors.white : const Color(0xFF1769E8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          if (today && !active)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF1769E8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LeaveCalendarController extends GetxController {
  final AuthService _auth = AuthService();

  final leaveList = <model.Leave>[].obs;

  final selectedDates = <DateTime>[].obs;

  final dateTypeDetails = <String, Map<String, dynamic>>{}.obs;

  final employeeId = ''.obs;

  final isLoading = false.obs;

  var focusedDay = DateTime.now().obs;

  List<DateTime> get sortedSelectedDates {
    final dates = selectedDates.toList();

    dates.sort((a, b) => a.compareTo(b));

    return dates;
  }

  @override
  void onInit() {
    super.onInit();

    loadEmployeeId();
  }

  Future<void> loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();

    employeeId.value = prefs.getString('employee_no') ?? "";

    if (employeeId.value.isNotEmpty) fetchLeaves();
  }

  Future<void> fetchLeaves() async {
    try {
      isLoading.value = true;

      final resp = await _auth.leave.countLeaveData(employeeId.value);

      leaveList.assignAll(resp.leaves);
    } finally {
      isLoading.value = false;
    }
  }

  bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isSelected(DateTime day) => selectedDates.any((d) => isSameDate(d, day));

  void onDayTapped(DateTime day) {
    if (isSelected(day)) {
      selectedDates.removeWhere((d) => isSameDate(d, day));

      dateTypeDetails.remove(day.toIso8601String());
    } else {
      editSelectedDate(Get.context!, day);
    }
  }

  void saveDateDetails(DateTime date, model.Leave leave, HalfDayType? half) {
    dateTypeDetails[date.toIso8601String()] = {
      "leave_category": leave.leaveCategoryId,
      "leave_type": leave.categoryName,
      "is_half_day": half != null ? 1 : 0,
      "half_day_type": half?.name,
    };

    if (!isSelected(date)) selectedDates.add(date);
  }

  Map<String, dynamic> getDateDetail(DateTime date) {
    return dateTypeDetails[date.toIso8601String()] ??
        {"leave_type": "Unknown", "is_half_day": 0};
  }

  void editSelectedDate(BuildContext context, DateTime date) {
    Get.bottomSheet(
      _LeaveTypeBottomSheet(
        date: date,
        categories: leaveList,
        onConfirm: (leave, half) {
          saveDateDetails(date, leave, half);

          Get.back();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    );
  }

  void navigateToRequestPage() {
    final mapped = sortedSelectedDates.map((d) {
      return {
        "date": d,
        ...dateTypeDetails[d.toIso8601String()]!,
      };
    }).toList();

    Get.to(() => LeaveRequestPage(selectedDates: mapped));
  }

  void navigateBackToDashboard() {
    Get.offAll(() => DashboardScreen());
  }
}

/* ================================================================

                SELECTED DATE CARD

================================================================ */

class _SelectedDateCard extends StatelessWidget {
  final DateTime date;

  final Map<String, dynamic> info;

  final VoidCallback onEdit;

  const _SelectedDateCard({
    required this.date,
    required this.info,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    final cardShadow = Colors.black.withOpacity(
      theme.brightness == Brightness.dark ? 0.28 : 0.05,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.30)),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(
                theme.brightness == Brightness.dark ? 0.22 : 0.10,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMM yyyy').format(date),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      label: (info['leave_type'] ?? 'Unknown').toString(),
                      color: cs.primary,
                    ),
                    if (info['is_half_day'] == 1)
                      _InfoChip(
                        label: info['half_day_type'] == 'morning'
                            ? 'Morning Half'
                            : 'Evening Half',
                        color: info['half_day_type'] == 'morning'
                            ? AppColors.warning
                            : Colors.indigo,
                      ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(
                    theme.brightness == Brightness.dark ? 0.20 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.edit_rounded, size: 18, color: cs.primary),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    final bg =
        color.withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color == Colors.indigo ? cs.onBackground : color,
        ),
      ),
    );
  }
}

/* ================================================================

                BOTTOM SHEET

================================================================ */

class _LeaveTypeBottomSheet extends StatefulWidget {
  final DateTime date;

  final List<model.Leave> categories;

  final Function(model.Leave, HalfDayType?) onConfirm;

  const _LeaveTypeBottomSheet({
    required this.date,
    required this.categories,
    required this.onConfirm,
  });

  @override
  State<_LeaveTypeBottomSheet> createState() => _LeaveTypeBottomSheetState();
}

class _LeaveTypeBottomSheetState extends State<_LeaveTypeBottomSheet> {
  model.Leave? selected;

  HalfDayType? halfDayType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final size = MediaQuery.of(context).size;

    final maxHeight = size.height * 0.88;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 640, maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.45 : 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cs.onBackground.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(
                                  isDark ? 0.24 : 0.10,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.event_note_rounded,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Apply Leave",
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    DateFormat('EEEE, d MMM yyyy')
                                        .format(widget.date),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onBackground.withOpacity(0.62),
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          "Leave Type",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onBackground,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (widget.categories.isEmpty)
                          _NoLeaveTypesCard(colorScheme: cs)
                        else
                          ...widget.categories.map(_leaveTypeOption),
                        const SizedBox(height: 16),
                        Text(
                          "Half Day (Optional)",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onBackground,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _HalfDayCard(
                              title: "Morning",
                              icon: Icons.wb_sunny_outlined,
                              color: Colors.orange,
                              active: halfDayType == HalfDayType.morning,
                              onTap: () => setState(
                                () => halfDayType =
                                    halfDayType == HalfDayType.morning
                                        ? null
                                        : HalfDayType.morning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _HalfDayCard(
                              title: "Evening",
                              icon: Icons.nights_stay_outlined,
                              color: Colors.indigo,
                              active: halfDayType == HalfDayType.evening,
                              onTap: () => setState(
                                () => halfDayType =
                                    halfDayType == HalfDayType.evening
                                        ? null
                                        : HalfDayType.evening,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withOpacity(0.25),
                      ),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: selected == null
                        ? null
                        : () => widget.onConfirm(selected!, halfDayType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      disabledBackgroundColor: cs.primary.withOpacity(0.34),
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Confirm Leave",
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _leaveTypeOption(model.Leave leave) {
    final active = selected == leave;

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        final cs = theme.colorScheme;

        final isDark = theme.brightness == Brightness.dark;

        final border =
            active ? cs.primary : theme.dividerColor.withOpacity(0.35);

        final bg = active
            ? cs.primary.withOpacity(isDark ? 0.20 : 0.08)
            : theme.scaffoldBackgroundColor.withOpacity(isDark ? 0.50 : 0.75);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => selected = leave),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: active ? 1.4 : 1),
                  color: bg,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primary.withOpacity(isDark ? 0.24 : 0.12)
                            : cs.onBackground.withOpacity(isDark ? 0.10 : 0.05),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.work_outline_rounded,
                        size: 20,
                        color: active
                            ? cs.primary
                            : cs.onBackground.withOpacity(0.54),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.categoryName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onBackground,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Available ${leave.actualLeaveCounts} of ${leave.leaveCount}",
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: cs.onBackground.withOpacity(0.62),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: active ? 1 : 0,
                      child:
                          Icon(Icons.check_circle_rounded, color: cs.primary),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoLeaveTypesCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _NoLeaveTypesCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.28)),
      ),
      child: Text(
        'No leave types available right now.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onBackground.withOpacity(0.65),
        ),
      ),
    );
  }
}

class _HalfDayCard extends StatelessWidget {
  final String title;

  final IconData icon;

  final Color color;

  final bool active;

  final VoidCallback onTap;

  const _HalfDayCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    final border = active ? color : theme.dividerColor.withOpacity(0.6);

    final bg = active
        ? color.withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.15)
        : theme.cardColor;

    final fg = active ? color : cs.onBackground.withOpacity(0.55);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: active ? 1.5 : 1),
              color: bg,
            ),
            child: Column(
              children: [
                Icon(icon, color: fg),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

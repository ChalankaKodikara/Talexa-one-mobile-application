// lib/modules/HRMS/main_screens/timesheet/screens/timesheet_screen.dart
// Talexa HRMS - simplified timesheet view.
import 'package:corehris/modules/HRMS/main_screens/timesheet/controllers/timesheet_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TimesheetScreen extends StatefulWidget {
  final String employeeNo;

  const TimesheetScreen({super.key, required this.employeeNo});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  late final TimesheetController controller;
  bool _timelineView = true;

  static const _blue = Color(0xFF1769E8);
  static const _navy = Color(0xFF182237);
  static const _muted = Color(0xFF89919D);

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<TimesheetController>()
        ? Get.find<TimesheetController>()
        : Get.put(TimesheetController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadTimesheet(widget.employeeNo);
    });
  }

  bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _surface(BuildContext context) =>
      _dark(context) ? const Color(0xFF1B2638) : Colors.white;

  Color _ink(BuildContext context) =>
      _dark(context) ? const Color(0xFFF4F7FC) : _navy;

  Color _sub(BuildContext context) =>
      _dark(context) ? const Color(0xFFA5B1C2) : _muted;

  Color _line(BuildContext context) =>
      _dark(context) ? const Color(0xFF303D50) : const Color(0xFFE9EEF5);

  String _timeRange(String? start, String? end) {
    final a = (start ?? '').trim();
    final b = (end ?? '').trim();
    if (a.isEmpty && b.isEmpty) return 'Not configured';
    if (a.isEmpty) return 'Until $b';
    if (b.isEmpty) return 'From $a';
    return '$a  –  $b';
  }

  // Timeline is built from the configured timetable windows, not punch history.
  // An absent window appears as "Not configured" after configured windows.
  int? _minutes(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text == '-' || text == '--') return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?')
        .firstMatch(text);
    if (match == null) return null;
    var h = int.tryParse(match.group(1)!) ?? -1;
    final m = int.tryParse(match.group(2)!) ?? -1;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    final ap = match.group(3)?.toUpperCase();
    if (ap != null) {
      if (h > 12 || h < 1) return null;
      h = (h % 12) + (ap == 'PM' ? 12 : 0);
    }
    return h * 60 + m;
  }

  Widget _viewSwitch(BuildContext context) {
    final dark = _dark(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B2638) : const Color(0xFFE7EDF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        _modeButton(context, 'Timeline', Icons.linear_scale_rounded, true),
        _modeButton(context, 'List', Icons.format_list_bulleted_rounded, false),
      ]),
    );
  }

  Widget _modeButton(
      BuildContext context, String title, IconData icon, bool timeline) {
    final selected = _timelineView == timeline;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () {
          if (_timelineView != timeline)
            setState(() => _timelineView = timeline);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _blue : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 17, color: selected ? Colors.white : _sub(context)),
            const SizedBox(width: 7),
            Text(title,
                style: TextStyle(
                  color: selected ? Colors.white : _sub(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                )),
          ]),
        ),
      ),
    );
  }

  Widget _timeline(BuildContext context, List<_TimeWindow> windows) {
    final ordered = [...windows];
    ordered.sort((a, b) {
      final aMin = _minutes(a.start);
      final bMin = _minutes(b.start);
      if (aMin == null && bMin == null) return a.order.compareTo(b.order);
      if (aMin == null) return 1;
      if (bMin == null) return -1;
      final result = aMin.compareTo(bMin);
      return result != 0 ? result : a.order.compareTo(b.order);
    });
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 19, 15, 17),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line(context)),
      ),
      child: Column(
          children: List.generate(ordered.length, (index) {
        final item = ordered[index];
        final available =
            _minutes(item.start) != null || _minutes(item.end) != null;
        final last = index == ordered.length - 1;
        final dot = available ? _blue : _sub(context).withOpacity(.55);
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 25,
              child: Column(children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: available ? _blue.withOpacity(.11) : _line(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 14, color: dot),
                ),
                if (!last)
                  Expanded(
                      child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: _line(context),
                  )),
              ]),
            ),
            const SizedBox(width: 13),
            Expanded(
                child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 22, top: 2),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: TextStyle(
                          color: _ink(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 5),
                    Text(_timeRange(item.start, item.end),
                        style: TextStyle(
                          color: available ? _ink(context) : _sub(context),
                          fontSize: 12.5,
                          fontWeight:
                              available ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ]),
            )),
          ]),
        );
      })),
    );
  }

  Widget _scheduleRow(
    BuildContext context, {
    required String label,
    required String time,
    required IconData icon,
    bool showDivider = true,
  }) {
    final absent = time == 'Not configured';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: _blue, size: 19),
              const SizedBox(width: 13),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink(context),
                    )),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  time,
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: absent ? FontWeight.w400 : FontWeight.w700,
                    color: absent ? _sub(context) : _ink(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: _line(context)),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _blue),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          color: _ink(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(color: _sub(context), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: _surface(context),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _line(context)),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _overview(
      BuildContext context, String name, String number, String? workingDays) {
    final validName = name.trim().isEmpty ? 'My Timesheet' : name.trim();
    final days = (workingDays ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: _blue, size: 25),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(validName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        color: _ink(context),
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(number,
                    style: TextStyle(fontSize: 11, color: _sub(context))),
              ],
            ),
          ),
          if (days.isNotEmpty && days != '-') ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _dark(context)
                    ? const Color(0xFF253A59)
                    : const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(days,
                      style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                  const Text('Working days',
                      style: TextStyle(color: _blue, fontSize: 9)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * .22),
        Icon(Icons.event_busy_outlined, color: _sub(context), size: 40),
        const SizedBox(height: 15),
        Center(
            child: Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: _sub(context), fontSize: 13))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text('My Timesheet',
            style: TextStyle(
                color: _ink(context),
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor:
            dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8),
        foregroundColor: _ink(context),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: () => controller.loadTimesheet(widget.employeeNo),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: _blue));
          }
          if (!controller.success.value) {
            return _empty(
                context,
                controller.errorMessage.value.isEmpty
                    ? 'No timesheet available'
                    : controller.errorMessage.value);
          }
          final timetable = controller.employeeTimetable.value;
          final detail = controller.primaryDetail;
          if (timetable == null || detail == null) {
            return _empty(context, 'No timesheet data available');
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _overview(context, timetable.employeeNameInitial ?? 'Employee',
                  timetable.employeeNo, detail.workingDays),
              const SizedBox(height: 16),
              _viewSwitch(context),
              const SizedBox(height: 19),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                child: _timelineView
                    ? Column(
                        key: const ValueKey('timeline'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily schedule',
                              style: TextStyle(
                                color: _ink(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 5),
                          Text('Your timetable windows in time order',
                              style: TextStyle(
                                  color: _sub(context), fontSize: 11)),
                          const SizedBox(height: 12),
                          _timeline(context, [
                            _TimeWindow(0, 'Check In', detail.startCheckInTime,
                                detail.endCheckInTime, Icons.login_rounded),
                            _TimeWindow(1, 'Grace Period', detail.graceStart,
                                detail.graceEnd, Icons.schedule_outlined),
                            _TimeWindow(
                                2,
                                'Short Leave',
                                detail.shortStart,
                                detail.shortEnd,
                                Icons.directions_walk_outlined),
                            _TimeWindow(3, 'Half Day', detail.halfStart,
                                detail.halfEnd, Icons.timelapse_outlined),
                            _TimeWindow(
                                4,
                                'Afternoon Half Day',
                                detail.eveHalfStart,
                                detail.eveHalfEnd,
                                Icons.timelapse_outlined),
                            _TimeWindow(
                                5,
                                'Afternoon Short Leave',
                                detail.eveShortStart,
                                detail.eveShortEnd,
                                Icons.directions_walk_outlined),
                            _TimeWindow(6, 'Check Out', detail.checkOutStart,
                                detail.checkOutEnd, Icons.logout_rounded),
                          ]),
                        ],
                      )
                    : Column(
                        key: const ValueKey('list'),
                        children: [
                          const SizedBox(height: 22),
                          _section(
                            context,
                            title: 'Morning & daytime',
                            subtitle: 'Arrival and leave time windows',
                            icon: Icons.wb_sunny_outlined,
                            rows: [
                              _scheduleRow(context,
                                  label: 'Check In',
                                  icon: Icons.login_rounded,
                                  time: _timeRange(detail.startCheckInTime,
                                      detail.endCheckInTime)),
                              _scheduleRow(context,
                                  label: 'Grace Period',
                                  icon: Icons.schedule_outlined,
                                  time: _timeRange(
                                      detail.graceStart, detail.graceEnd)),
                              _scheduleRow(context,
                                  label: 'Short Leave',
                                  icon: Icons.directions_walk_outlined,
                                  time: _timeRange(
                                      detail.shortStart, detail.shortEnd)),
                              _scheduleRow(context,
                                  label: 'Half Day',
                                  icon: Icons.timelapse_outlined,
                                  time: _timeRange(
                                      detail.halfStart, detail.halfEnd),
                                  showDivider: false),
                            ],
                          ),
                          const SizedBox(height: 23),
                          _section(
                            context,
                            title: 'Afternoon & checkout',
                            subtitle: 'Departure and afternoon leave windows',
                            icon: Icons.nights_stay_outlined,
                            rows: [
                              _scheduleRow(context,
                                  label: 'Afternoon Half Day',
                                  icon: Icons.timelapse_outlined,
                                  time: _timeRange(
                                      detail.eveHalfStart, detail.eveHalfEnd)),
                              _scheduleRow(context,
                                  label: 'Afternoon Short Leave',
                                  icon: Icons.directions_walk_outlined,
                                  time: _timeRange(detail.eveShortStart,
                                      detail.eveShortEnd)),
                              _scheduleRow(context,
                                  label: 'Check Out',
                                  icon: Icons.logout_rounded,
                                  time: _timeRange(
                                      detail.checkOutStart, detail.checkOutEnd),
                                  showDivider: false),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('Times are based on your assigned work schedule.',
                    style: TextStyle(color: _sub(context), fontSize: 11)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TimeWindow {
  final int order;
  final String label;
  final String? start;
  final String? end;
  final IconData icon;

  const _TimeWindow(this.order, this.label, this.start, this.end, this.icon);
}

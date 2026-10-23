import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance_adjustment_picker.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/attendance_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

/// Quick Access entry point. Uses the same attendance range API as the
/// Attendance Report and the same adjustment submit form.
class AttendanceAdjustmentHome extends StatefulWidget {
  const AttendanceAdjustmentHome({super.key});

  @override
  State<AttendanceAdjustmentHome> createState() => _AttendanceAdjustmentHomeState();
}

class _AttendanceAdjustmentHomeState extends State<AttendanceAdjustmentHome> {
  final _auth = AuthService.instance;
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  String _employeeNo = '';
  bool _loading = true;
  String? _error;
  Map<String, Map<String, dynamic>> _days = {};

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface => _dark ? const Color(0xFF1B2638) : Colors.white;
  Color get _ink => _dark ? Colors.white : const Color(0xFF182237);
  Color get _muted => const Color(0xFF89919D);
  String _key(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _employeeNo = prefs.getString('employee_no') ?? prefs.getString('employee_id') ?? '';
      await _auth.initialize();
      await _loadMonth();
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMonth() async {
    if (_employeeNo.trim().isEmpty) {
      if (mounted) setState(() { _loading = false; _error = 'Employee number not found. Please sign in again.'; });
      return;
    }
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final first = DateTime(_focused.year, _focused.month, 1);
      final last = DateTime(_focused.year, _focused.month + 1, 0);
      final rows = await _auth.attendance.fetchAttendanceRange(_employeeNo, first, last);
      final mapped = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final raw = (row['date'] ?? row['work_date_local'] ?? row['attendance_date'])?.toString();
        if (raw == null) continue;
        final date = DateTime.tryParse(raw);
        if (date != null) mapped[_key(date)] = row;
      }
      if (mounted) setState(() { _days = mapped; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openChoice() async {
    final row = _days[_key(_selected)];
    if (row == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No attendance record for this date. A separate missing-day request flow is required.'),
      ));
      return;
    }
    final submitted = await AttendanceAdjustmentPicker.open(
      context: context, date: _selected, attendance: row, employeeNo: _employeeNo,
    );
    if (submitted && mounted) await _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final dateRecord = _days[_key(_selected)];
    final status = (dateRecord?['status'] ?? 'No attendance record').toString();
    return Scaffold(
      backgroundColor: _dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Attendance Adjustment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true, elevation: 0, scrolledUnderElevation: 0,
        backgroundColor: _dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8),
        actions: [IconButton(onPressed: _loading ? null : _loadMonth, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMonth,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 28), children: [
          const Text('SELECT A DAY', style: TextStyle(color: Color(0xFF1769E8),
            letterSpacing: 1.1, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Correct attendance', style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text('Review the recorded day, then request a correction.',
            style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(22)),
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: TableCalendar<Map<String, dynamic>>(
              focusedDay: _focused,
              firstDay: DateTime(2020), lastDay: DateTime(2100),
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              onDaySelected: (day, focused) => setState(() { _selected = day; _focused = focused; }),
              onPageChanged: (day) { setState(() { _focused = day; }); _loadMonth(); },
              headerStyle: HeaderStyle(formatButtonVisible: false,
                titleCentered: true, titleTextStyle: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 17)),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Color(0xFF182237)),
                selectedDecoration: const BoxDecoration(color: Color(0xFF1769E8), shape: BoxShape.circle),
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: _ink),
                weekendTextStyle: TextStyle(color: _ink),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (ctx, day, _) {
                  final record = _days[_key(day)];
                  if (record == null) return null;
                  final label = (record['status'] ?? '').toString().toLowerCase();
                  final dot = label.contains('absent') ? const Color(0xFFEA5455)
                    : label.contains('late') || label.contains('pending') ? const Color(0xFFF59E0B)
                    : const Color(0xFF16A34A);
                  return Positioned(bottom: 3, child: Container(height: 4, width: 4,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: dot)));
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator()))
          else if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red)))
          else Container(
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('EEEE, d MMM yyyy').format(_selected),
                style: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(status, style: const TextStyle(color: Color(0xFF1769E8), fontWeight: FontWeight.w600, fontSize: 12)),
              const Divider(height: 24),
              Row(children: [
                Expanded(child: _Value(label: 'Check In', value: _time(dateRecord, 'check_in_time', 'checkIN_time'))),
                Expanded(child: _Value(label: 'Check Out', value: _time(dateRecord, 'check_out_time', 'checkOUT_time'))),
              ]),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, height: 52, child: FilledButton(
                onPressed: dateRecord == null ? null : _openChoice,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1769E8),
                  shape: const StadiumBorder()),
                child: const Text('Request Adjustment', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
          const SizedBox(height: 12),
          Material(color: _surface, borderRadius: BorderRadius.circular(18), child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Get.to(() => AttendanceEditReportScreen()),
            child: Padding(padding: const EdgeInsets.all(17), child: Row(children: [
              const Icon(Icons.history_rounded, color: Color(0xFF1769E8)),
              const SizedBox(width: 12),
              Expanded(child: Text('Adjustment History', style: TextStyle(color: _ink, fontWeight: FontWeight.w700))),
              Icon(Icons.chevron_right_rounded, color: _muted),
            ])),
          )),
        ]),
      ),
    );
  }

  static String _time(Map<String, dynamic>? record, String a, String b) {
    final raw = (record?[a] ?? record?[b])?.toString() ?? '';
    if (raw.trim().isEmpty || raw == '--') return '--';
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return DateFormat('hh:mm a').format(parsed);
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return DateFormat('hh:mm a').format(DateTime(2000, 1, 1, h, m));
      }
    }
    return raw;
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark ? Colors.white60 : const Color(0xFF89919D);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: muted)),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }
}

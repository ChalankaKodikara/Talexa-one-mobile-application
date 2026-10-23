import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Calendar-inspired request detail view. Displays data supplied by the
/// existing LeaveRequestDetailPage navigation, without extra API calls.
class LeaveRequestDetailPage extends StatelessWidget {
  final Map<String, dynamic> leaveData;
  final String employeeId;

  const LeaveRequestDetailPage({
    super.key,
    required this.leaveData,
    required this.employeeId,
  });

  static const Color _blue = Color(0xFF1769E8);
  static const Color _navy = Color(0xFF152238);

  bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  Color _bg(BuildContext c) =>
      _dark(c) ? const Color(0xFF0F1521) : const Color(0xFFF6F8FC);
  Color _surface(BuildContext c) =>
      _dark(c) ? const Color(0xFF1C2533) : Colors.white;
  Color _ink(BuildContext c) => _dark(c) ? const Color(0xFFF4F7FC) : _navy;
  Color _sub(BuildContext c) =>
      _dark(c) ? const Color(0xFF9FABBD) : const Color(0xFF8A95A6);
  Color _line(BuildContext c) =>
      _dark(c) ? const Color(0xFF303B4A) : const Color(0xFFE8EDF4);

  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    return date == null
        ? (value?.toString() ?? '-')
        : DateFormat('d MMM yyyy').format(date);
  }

  bool _isHalf(dynamic value) {
    final string = value?.toString().toLowerCase() ?? '';
    return value == true || string == '1' || string == 'true';
  }

  Color _statusColor(String value) {
    final s = value.toUpperCase();
    if (s.contains('NOT APPROV') || s.contains('REJECT')) {
      return const Color(0xFFD95B65);
    }
    if (s.contains('APPROV')) return const Color(0xFF159B78);
    if (s.contains('CANCEL')) return const Color(0xFF818B9B);
    return const Color(0xFFD48C28);
  }

  IconData _iconFor(String name) {
    final s = name.toLowerCase();
    if (s.contains('annual')) return Icons.beach_access_rounded;
    if (s.contains('medical')) return Icons.medical_services_outlined;
    if (s.contains('casual')) return Icons.event_available_rounded;
    return Icons.event_note_rounded;
  }

  List<Map<String, dynamic>> _covering() {
    final raw = leaveData['covering_employees'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final category = (leaveData['category_name'] ?? 'Leave').toString().trim();
    final status =
        (leaveData['approved_status_1'] ?? 'PENDING').toString().trim();
    final requested = _parseDate(leaveData['requested_date']);
    final displayDate = requested ?? DateTime.now();
    final half = _isHalf(leaveData['is_half_day']);
    final reason = (leaveData['reason'] ?? '').toString().trim();
    final remarks = (leaveData['remarks'] ?? '').toString().trim();
    final employees = _covering();
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        centerTitle: true,
        title: Text('Leave Calendar',
            style: TextStyle(
                color: _ink(context),
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(Icons.calendar_month_outlined, color: _blue, size: 23),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(displayDate),
                  style: TextStyle(
                      fontSize: 29,
                      letterSpacing: -0.9,
                      fontWeight: FontWeight.w800,
                      color: _ink(context)),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(displayDate),
                  style: TextStyle(fontSize: 13, color: _sub(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _dateStrip(context, displayDate, highlight: requested != null),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: _blue, shape: BoxShape.circle)),
              const SizedBox(width: 9),
              Text('Request details',
                  style: TextStyle(
                      color: _ink(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 19),
          _leaveEventCard(
              context, category, status, statusColor, half, reason, requested),
          const SizedBox(height: 17),
          _sectionLabel(context, 'REQUEST INFORMATION'),
          const SizedBox(height: 9),
          _detailsSurface(context, children: [
            _detailRow(context, Icons.calendar_today_outlined, 'Requested date',
                _formatDate(leaveData['requested_date'])),
            Divider(height: 22, color: _line(context)),
            _detailRow(context, Icons.timelapse_outlined, 'Duration',
                half ? 'Half Day' : 'Full Day'),
          ]),
          const SizedBox(height: 18),
          _sectionLabel(context, 'REASON & NOTES'),
          const SizedBox(height: 9),
          _detailsSurface(context, children: [
            Text(
              reason.isEmpty ? 'No reason provided' : reason,
              style: TextStyle(
                  color: reason.isEmpty ? _sub(context) : _ink(context),
                  fontSize: 13,
                  height: 1.55),
            ),
            if (remarks.isNotEmpty) ...[
              Divider(height: 24, color: _line(context)),
              Text('Remarks',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _sub(context))),
              const SizedBox(height: 6),
              Text(remarks,
                  style: TextStyle(
                      color: _ink(context), fontSize: 13, height: 1.5)),
            ],
          ]),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _sectionLabel(context, 'COVERING EMPLOYEES')),
              Text('${employees.length} assigned',
                  style: TextStyle(color: _sub(context), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 9),
          if (employees.isEmpty)
            _detailsSurface(
              context,
              children: [
                Text('No covering employees assigned',
                    style: TextStyle(color: _sub(context), fontSize: 12))
              ],
            )
          else
            ...employees.map((employee) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _coveringCard(context, employee),
                )),
        ],
      ),
    );
  }

  /// Dates are for context, not an interactive attendance/leave-history browser.
  /// This detail page only receives one leave request from its parent.
  Widget _dateStrip(BuildContext context, DateTime selected,
      {required bool highlight}) {
    return SizedBox(
      height: 113,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 4 * 9) / 5;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (_, index) {
              final day = selected.add(Duration(days: index - 2));
              final active = index == 2 && highlight;
              return Container(
                width: width,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? _blue : _surface(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: active ? _blue : _line(context)),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: _blue.withOpacity(0.18),
                              blurRadius: 13,
                              offset: const Offset(0, 5))
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle,
                        size: 5,
                        color: active
                            ? const Color(0xFFE0E9FF)
                            : const Color(0xFFD6DFEC)),
                    const SizedBox(height: 8),
                    Text('${day.day}',
                        style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : _ink(context))),
                    const SizedBox(height: 4),
                    Text(DateFormat('EEE').format(day),
                        style: TextStyle(
                            fontSize: 11,
                            color: active
                                ? Colors.white.withOpacity(0.9)
                                : _sub(context))),
                    const SizedBox(height: 7),
                    Container(
                        width: 17,
                        height: 3,
                        decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(3))),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _leaveEventCard(BuildContext context, String category, String status,
      Color tone, bool half, String reason, DateTime? requested) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            color: _dark(context)
                ? const Color(0xFF222E40)
                : const Color(0xFFEBF3FF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                      color: _dark(context)
                          ? const Color(0xFF324B75)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Icon(_iconFor(category), color: _blue, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(category,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink(context))),
                      const SizedBox(height: 5),
                      Text('Leave application',
                          style:
                              TextStyle(fontSize: 11.5, color: _sub(context))),
                    ])),
                const SizedBox(width: 6),
                _statusPill(context, status, tone),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 19),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: _blue),
                const SizedBox(width: 7),
                Expanded(
                    child: Text(
                        requested == null
                            ? _formatDate(leaveData['requested_date'])
                            : DateFormat('EEEE, d MMM yyyy').format(requested),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: _ink(context)))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 16, color: _blue),
                const SizedBox(width: 7),
                Text(half ? 'Half Day' : 'Full Day',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: _ink(context),
                        fontWeight: FontWeight.w600)),
              ]),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(height: 1, color: _line(context)),
                const SizedBox(height: 12),
                Text(reason,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.5, color: _sub(context))),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context, String text, Color tone) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
          color: tone.withOpacity(_dark(context) ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(30)),
      child: Text(text.toUpperCase().replaceAll('_', ' '),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: tone, fontSize: 9.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: _sub(context)));
  }

  Widget _detailsSurface(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: _surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line(context))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _detailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(children: [
      Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: _dark(context)
                  ? const Color(0xFF283C5B)
                  : const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _blue, size: 18)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: _sub(context))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _ink(context))),
      ])),
    ]);
  }

  Widget _coveringCard(BuildContext context, Map<String, dynamic> emp) {
    final name = (emp['covering_employee_name'] ??
            emp['employee_name'] ??
            emp['covering_employee_no'] ??
            '-')
        .toString();
    final status = (emp['status'] ?? 'pending').toString();
    final start = (emp['start_time'] ?? '-').toString();
    final end = (emp['end_time'] ?? '-').toString();
    return _detailsSurface(context, children: [
      Row(children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: _dark(context)
                    ? const Color(0xFF283C5B)
                    : const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.person_outline_rounded,
                color: _blue, size: 20)),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _ink(context))),
          const SizedBox(height: 5),
          Text('$start - $end',
              style: TextStyle(fontSize: 11, color: _sub(context))),
        ])),
        const SizedBox(width: 5),
        _statusPill(context, status, _statusColor(status)),
      ]),
    ]);
  }
}

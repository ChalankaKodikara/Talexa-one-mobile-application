import 'package:corehris/modules/HRMS/main_screens/reports/controllers/leave_con.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveReportCard extends StatelessWidget {
  final Map<String, dynamic> leave;
  final LeaveReportController controller;

  const LeaveReportCard({
    super.key,
    required this.leave,
    required this.controller,
  });

  static const Color _blue = Color(0xFF1769E8);
  static const Color _ink = Color(0xFF182237);
  static const Color _muted = Color(0xFF89919D);

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _text(BuildContext context) => _isDark(context) ? Colors.white : _ink;

  Color _secondary(BuildContext context) =>
      _isDark(context) ? const Color(0xFFA4ADBC) : _muted;

  Color _divider(BuildContext context) =>
      _isDark(context) ? const Color(0xFF303D50) : const Color(0xFFE9EDF3);

  String _safe(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  String _pretty(String value) {
    if (value.isEmpty) return value;

    return value.replaceAll('_', ' ').split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';

      return '${word[0].toUpperCase()}'
          '${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  Color _statusColor(String status) {
    final value = status.trim().toUpperCase();

    if (value.contains('RECLAIM') || value.contains('CANCEL')) {
      return const Color(0xFF64748B);
    }

    if (value.contains('NOT APPROV') || value.contains('PENDING')) {
      return const Color(0xFFB98513);
    }

    if (value.contains('REJECT')) {
      return const Color(0xFFDC4C4C);
    }

    if (value.contains('APPROV')) {
      return const Color(0xFF15965B);
    }

    return const Color(0xFF64748B);
  }

  IconData _leaveIcon(String type) {
    final value = type.toLowerCase();

    if (value.contains('annual')) {
      return Icons.beach_access_rounded;
    }

    if (value.contains('casual')) {
      return Icons.event_available_outlined;
    }

    if (value.contains('sick') || value.contains('medical')) {
      return Icons.medical_services_outlined;
    }

    if (value.contains('maternity')) {
      return Icons.child_friendly_outlined;
    }

    return Icons.event_note_outlined;
  }

  String _dayType(dynamic value) {
    return value == 1 || value == '1' || value == true
        ? 'Half Day'
        : 'Full Day';
  }

  double _noPayWeight() {
    final raw = leave['no_pay_weight'];

    if (raw is num) return raw.toDouble();

    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String _leaveMode() {
    final type = _safe(
      leave['leave_type'],
    ).toLowerCase();

    if (type == 'normal') {
      return 'Normal Leave';
    }

    if (type == 'no_pay') {
      final weight = _noPayWeight();

      if (weight == 1) return 'No-Pay • Full Day';
      if (weight == 0.5) return 'No-Pay • Half Day';

      return 'No-Pay • $weight Days';
    }

    return '';
  }

  Widget _pill(
    String label,
    Color color,
    bool dark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _dateText(dynamic value) {
    final raw = _safe(value);

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw.isEmpty ? 'Date unavailable' : raw;
    }

    return DateFormat('dd MMM yyyy').format(parsed);
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _text(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _coveringEmployee(
    BuildContext context,
    Map<String, dynamic> employee,
  ) {
    final dark = _isDark(context);

    final name = _safe(
      employee['covering_employee_name'],
      fallback: 'Unknown employee',
    );

    final startTime = _safe(employee['start_time']);
    final endTime = _safe(employee['end_time']);

    final status = _safe(
      employee['status'],
      fallback: 'Pending',
    );

    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline_rounded,
            color: _blue,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (startTime.isNotEmpty || endTime.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: _secondary(context),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$startTime – $endTime',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _secondary(context),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pill(
            _pretty(status),
            color,
            dark,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);

    final status = _safe(
      leave['approved_status_1'],
      fallback: 'Pending',
    );

    final type = _safe(
      leave['category_name'],
      fallback: 'Leave',
    );

    final reason = _safe(
      leave['reason'],
      fallback: 'No reason provided',
    );

    final date = _dateText(
      leave['requested_date'],
    );

    final mode = _leaveMode();

    final statusColor = _statusColor(status);

    final coveringRaw = leave['covering_employees'];

    final List<Map<String, dynamic>> covering = [];

    if (coveringRaw is List) {
      for (final item in coveringRaw) {
        if (item is Map) {
          covering.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    return Container(
      width: double.infinity,

      // No outer margin: suitable for bottom sheets.
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 4,
      ),

      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ========================================
          // LEAVE HEADER
          // ========================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _leaveIcon(type),
                color: _blue,
                size: 22,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _text(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      date,
                      style: TextStyle(
                        color: _secondary(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _pill(
                  _pretty(status),
                  statusColor,
                  dark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          // ========================================
          // HALF DAY / NORMAL LEAVE
          // ========================================

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                _dayType(leave['is_half_day']),
                const Color(0xFFBE8313),
                dark,
              ),
              if (mode.isNotEmpty)
                _pill(
                  mode,
                  mode.startsWith('No-Pay')
                      ? const Color(0xFFDC4C4C)
                      : const Color(0xFF15965B),
                  dark,
                ),
            ],
          ),

          const SizedBox(height: 20),

          Divider(
            color: _divider(context),
            height: 1,
          ),

          const SizedBox(height: 18),

          // ========================================
          // REASON
          // ========================================

          _sectionTitle(context, 'Reason'),

          const SizedBox(height: 7),

          Text(
            reason,
            style: TextStyle(
              color: _secondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 19),

          Divider(
            color: _divider(context),
            height: 1,
          ),

          const SizedBox(height: 18),

          // ========================================
          // COVERING EMPLOYEES
          // ========================================

          _sectionTitle(
            context,
            'Covering Employees',
            trailing: Text(
              '${covering.length}',
              style: TextStyle(
                color: _secondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (covering.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'No covering employees assigned',
                style: TextStyle(
                  color: _secondary(context),
                  fontSize: 12,
                ),
              ),
            )
          else
            ...covering.map(
              (employee) => _coveringEmployee(
                context,
                employee,
              ),
            ),

          // ========================================
          // DELETE REQUEST
          // Existing business condition preserved
          // ========================================

          if (status.trim().toUpperCase() == 'NOT APPROVED') ...[
            const SizedBox(height: 22),
            Divider(
              color: _divider(context),
              height: 1,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  controller.confirmDelete(
                    context,
                    leave['id'],
                  );
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Delete Leave Request',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC4C4C),
                  minimumSize: const Size.fromHeight(46),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

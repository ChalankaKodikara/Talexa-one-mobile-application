// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:corehris/modules/HRMS/main_screens/reports/controllers/leave_con.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:corehris/theme/theme.dart';

class LeaveReportCard extends StatelessWidget {
  final Map<String, dynamic> leave;
  final LeaveReportController controller;

  const LeaveReportCard({
    super.key,
    required this.leave,
    required this.controller,
  });

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'NOT APPROVED':
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // LEAVE ICON
  // ============================================================

  IconData _icon(String type) {
    final String value = type.toLowerCase();

    if (value.contains('sick')) {
      return Icons.sick_outlined;
    }

    if (value.contains('annual')) {
      return Icons.beach_access_rounded;
    }

    if (value.contains('casual')) {
      return Icons.event_available_outlined;
    }

    if (value.contains('maternity')) {
      return Icons.child_friendly_outlined;
    }

    return Icons.event_note_outlined;
  }

  // ============================================================
  // HALF DAY TEXT
  // ============================================================

  String _halfDay(dynamic value) {
    return (value == 1 || value == '1') ? 'Half Day' : 'Full Day';
  }

  // ============================================================
  // HALF DAY COLOR
  // ============================================================

  Color _halfColor(dynamic value) {
    return (value == 1 || value == '1') ? Colors.orange : AppColors.primary2;
  }

  // ============================================================
  // SAFE STRING
  // ============================================================

  String _safeString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  // ============================================================
  // NO PAY WEIGHT
  // ============================================================

  double _noPayWeight() {
    final dynamic raw = leave['no_pay_weight'];

    if (raw == null) {
      return 0;
    }

    if (raw is num) {
      return raw.toDouble();
    }

    return double.tryParse(
          raw.toString(),
        ) ??
        0;
  }

  // ============================================================
  // LEAVE TYPE BADGE
  // ============================================================

  Widget _leaveTypeBadge({
    required bool isDark,
  }) {
    final String leaveType = _safeString(
      leave['leave_type'],
    ).toLowerCase();

    // ----------------------------------------------------------
    // NO PAY
    // ----------------------------------------------------------

    if (leaveType == 'no_pay') {
      final double weight = _noPayWeight();

      String text;

      if (weight == 1) {
        text = 'No-Pay • Full Day';
      } else if (weight == 0.5) {
        text = 'No-Pay • Half Day';
      } else {
        final String weightText = weight == weight.roundToDouble()
            ? weight.toInt().toString()
            : weight.toString();

        text = 'No-Pay • $weightText Days';
      }

      return Container(
        margin: const EdgeInsets.only(
          top: 7,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(
            isDark ? 0.18 : 0.10,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withOpacity(
              isDark ? 0.55 : 0.40,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.red.shade300 : Colors.red.shade700,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // NORMAL
    // ----------------------------------------------------------

    if (leaveType == 'normal') {
      return Container(
        margin: const EdgeInsets.only(
          top: 7,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(
            isDark ? 0.18 : 0.10,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.withOpacity(
              isDark ? 0.55 : 0.40,
            ),
          ),
        ),
        child: Text(
          'Normal Leave',
          style: TextStyle(
            color: isDark ? Colors.green.shade300 : Colors.green.shade700,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // COVERING EMPLOYEES
  // ============================================================

  Widget _coveringBlock({
    required List<dynamic> list,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color secondarySurface,
    required Color borderColor,
  }) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: secondarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 18,
              color: textSecondary,
            ),
            const SizedBox(width: 9),
            Text(
              'No covering employees',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map(
        (dynamic item) {
          final Map<String, dynamic> employee;

          if (item is Map<String, dynamic>) {
            employee = item;
          } else if (item is Map) {
            employee = Map<String, dynamic>.from(item);
          } else {
            return const SizedBox.shrink();
          }

          final String employeeName = _safeString(
            employee['covering_employee_name'],
            fallback: 'Unknown',
          );

          final String startTime = _safeString(
            employee['start_time'],
          );

          final String endTime = _safeString(
            employee['end_time'],
          );

          final String employeeStatus = _safeString(
            employee['status'],
            fallback: 'Pending',
          );

          final Color statusColor = _statusColor(employeeStatus);

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(
              top: 7,
            ),
            decoration: BoxDecoration(
              color: secondarySurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ------------------------------------------------
                // EMPLOYEE ICON
                // ------------------------------------------------

                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary2.withOpacity(
                      isDark ? 0.18 : 0.09,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: AppColors.primary2,
                  ),
                ),

                const SizedBox(width: 11),

                // ------------------------------------------------
                // EMPLOYEE DETAILS
                // ------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (startTime.isNotEmpty || endTime.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$startTime - $endTime',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11.5,
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

                // ------------------------------------------------
                // COVERING STATUS
                // ------------------------------------------------

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(
                      isDark ? 0.17 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    employeeStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // THEME
    // ==========================================================

    final ThemeData theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    final Color surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;

    final Color secondarySurface =
        isDark ? const Color(0xFF1A2236) : const Color(0xFFF8FAFC);

    final Color textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    final Color textSecondary =
        isDark ? Colors.white70 : const Color(0xFF667085);

    final Color borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE4E7EC);

    final Color dividerColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEAECF0);

    // ==========================================================
    // DATA
    // ==========================================================

    final String status = _safeString(
      leave['approved_status_1'],
      fallback: 'Pending',
    );

    final String type = _safeString(
      leave['category_name'],
      fallback: 'Leave',
    );

    final String reason = _safeString(
      leave['reason'],
      fallback: 'No reason provided',
    );

    final String requestedDate = _safeString(
      leave['requested_date'],
    );

    final DateTime? date = DateTime.tryParse(
      requestedDate,
    );

    final dynamic coveringRaw = leave['covering_employees'];

    final List<dynamic> covering =
        coveringRaw is List ? coveringRaw : <dynamic>[];

    final Color halfDayColor = _halfColor(
      leave['is_half_day'],
    );

    final Color statusColor = _statusColor(status);

    // ==========================================================
    // CARD
    // ==========================================================

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: halfDayColor.withOpacity(
            isDark ? 0.65 : 0.75,
          ),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? 0.22 : 0.06,
            ),
            blurRadius: isDark ? 14 : 8,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------
              // LEAVE ICON
              // -------------------------------------------------

              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary2.withOpacity(
                    isDark ? 0.18 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _icon(type),
                  size: 25,
                  color: AppColors.primary2,
                ),
              ),

              const SizedBox(width: 12),

              // -------------------------------------------------
              // LEAVE INFORMATION
              // -------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // -------------------------------------------
                    // HALF / FULL DAY
                    // -------------------------------------------

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: halfDayColor.withOpacity(
                              isDark ? 0.18 : 0.11,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _halfDay(
                              leave['is_half_day'],
                            ),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: halfDayColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _leaveTypeBadge(
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // -------------------------------------------
                    // DATE
                    // -------------------------------------------

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          date == null
                              ? 'Unknown Date'
                              : DateFormat(
                                  'yyyy-MM-dd',
                                ).format(
                                  date,
                                ),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // -------------------------------------------------
              // STATUS + DELETE
              // -------------------------------------------------

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(
                        isDark ? 0.18 : 0.11,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withOpacity(
                          isDark ? 0.40 : 0.25,
                        ),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  if (status.toUpperCase() == 'NOT APPROVED') ...[
                    const SizedBox(height: 5),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete request',
                      onPressed: () {
                        controller.confirmDelete(
                          context,
                          leave['id'],
                        );
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: isDark ? Colors.red.shade300 : Colors.red,
                        size: 21,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          // =====================================================
          // REASON
          // =====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: secondarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reason',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =====================================================
          // DIVIDER
          // =====================================================

          Divider(
            color: dividerColor,
            thickness: 1,
            height: 1,
          ),

          const SizedBox(height: 15),

          // =====================================================
          // COVERING EMPLOYEES TITLE
          // =====================================================

          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary2.withOpacity(
                    isDark ? 0.17 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  size: 17,
                  color: AppColors.primary2,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Covering Employees',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (covering.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary2.withOpacity(
                      isDark ? 0.16 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${covering.length}',
                    style: const TextStyle(
                      color: AppColors.primary2,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 7),

          // =====================================================
          // COVERING EMPLOYEE LIST
          // =====================================================

          _coveringBlock(
            list: covering,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            secondarySurface: secondarySurface,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance_edit_screen.dart';

/// Six backend types. ADD/UPDATE choices are enabled using the existing
/// attendance punches so the employee cannot choose a mismatched type.
class AttendanceAdjustmentPicker {
  static Future<bool> open({
    required BuildContext context,
    required DateTime date,
    required Map<String, dynamic> attendance,
    String? employeeNo,
    String? employeeName,
  }) async {
    final bool hasCheckIn = _hasPunch(attendance, [
      'check_in_time',
      'checkIN_time',
      'checkInTime',
      'check_in',
    ]);
    final bool hasCheckOut = _hasPunch(attendance, [
      'check_out_time',
      'checkOUT_time',
      'checkOutTime',
      'check_out',
    ]);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = <_AdjustmentChoice>[
      _AdjustmentChoice('ADD_CHECK_IN', 'Add Check In',
          'Record a missing check-in time', Icons.login_rounded, !hasCheckIn),
      _AdjustmentChoice(
          'UPDATE_CHECK_IN',
          'Update Check In',
          'Correct an existing check-in time',
          Icons.edit_calendar_outlined,
          hasCheckIn),
      _AdjustmentChoice(
          'ADD_CHECK_OUT',
          'Add Check Out',
          'Record a missing check-out time',
          Icons.logout_rounded,
          !hasCheckOut),
      _AdjustmentChoice(
          'UPDATE_CHECK_OUT',
          'Update Check Out',
          'Correct an existing check-out time',
          Icons.edit_outlined,
          hasCheckOut),
      const _AdjustmentChoice(
          'UPDATE_STATUS',
          'Update Status',
          'Correct the attendance status only',
          Icons.fact_check_outlined,
          true),
      const _AdjustmentChoice(
          'FULL_DAY_CORRECTION',
          'Full Day Correction',
          'Correct multiple attendance values',
          Icons.calendar_month_outlined,
          true),
    ];
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .86),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2638) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(9))),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What would you like to adjust?',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF182237))),
                  const SizedBox(height: 5),
                  Text(DateFormat('EEEE, d MMM yyyy').format(date),
                      style: const TextStyle(
                          color: Color(0xFF89919D), fontSize: 12)),
                ],
              )),
          Flexible(
              child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 7),
            itemBuilder: (_, i) {
              final item = options[i];
              return Material(
                  color: item.available
                      ? (isDark
                          ? const Color(0xFF233148)
                          : const Color(0xFFF6F8FB))
                      : (isDark
                          ? const Color(0xFF192332)
                          : const Color(0xFFF9F9FA)),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: item.available
                        ? () => Navigator.pop(sheetContext, item.type)
                        : null,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 14),
                        child: Row(children: [
                          Icon(item.icon,
                              color: item.available
                                  ? const Color(0xFF1769E8)
                                  : const Color(0xFFABB2BE),
                              size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(item.title,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: item.available
                                            ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF182237))
                                            : const Color(0xFFABB2BE))),
                                const SizedBox(height: 3),
                                Text(
                                    item.available
                                        ? item.subtitle
                                        : 'Unavailable for this attendance record',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF89919D))),
                              ])),
                          Icon(
                              item.available
                                  ? Icons.chevron_right_rounded
                                  : Icons.lock_outline_rounded,
                              color: const Color(0xFF9CA5B3),
                              size: 19),
                        ])),
                  ));
            },
          )),
        ]),
      ),
    );
    // The parent sheet may already be disposed. Do not use its mounted state
    // to decide whether GetX is allowed to navigate to the form.
    if (type == null) return false;
    final args = <String, dynamic>{
      'date': DateFormat('yyyy-MM-dd').format(date),
      'adjustment_type': type,
      if (employeeNo != null && employeeNo.trim().isNotEmpty)
        'employee_no': employeeNo,
      if (employeeName != null && employeeName.trim().isNotEmpty)
        'employee_name': employeeName,
    };
    try {
      // GetX navigates using the app's root navigator, not the closed sheet.
      final result = await Get.to<dynamic>(
        () => const AttendanceEditScreen(),
        arguments: args,
        preventDuplicates: false,
      );
      return result is Map && result['updated'] == true;
    } catch (error, stackTrace) {
      debugPrint('Attendance adjustment navigation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      Get.snackbar(
        'Unable to open adjustment',
        'The adjustment form could not be opened. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFF991B1B),
        borderRadius: 18,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }
  }

  static bool _hasPunch(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != '--' && value.toLowerCase() != 'null')
        return true;
    }
    return false;
  }
}

class _AdjustmentChoice {
  const _AdjustmentChoice(
      this.type, this.title, this.subtitle, this.icon, this.available);
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool available;
}

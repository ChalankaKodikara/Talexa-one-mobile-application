// lib/components/leavedata.dart
import 'dart:convert';

/// ===============================
/// EMPLOYEE INFO
/// ===============================
class EmployeeInfo {
  final String employeeNo;
  final String employeeFullname;
  final String? department;
  final String? designation;

  EmployeeInfo({
    required this.employeeNo,
    required this.employeeFullname,
    this.department,
    this.designation,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      employeeNo: json['employee_no']?.toString() ?? '',
      employeeFullname: json['employee_fullname']?.toString() ?? '',
      department: json['department'] as String?,
      designation: json['designation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_no': employeeNo,
        'employee_fullname': employeeFullname,
        'department': department,
        'designation': designation,
      };
}

/// ===============================
/// LEAVE MODEL
/// ===============================
class Leave {
  final int leaveCategoryId;
  final String categoryName;

  final double leaveCount;
  final double noPayLeaveCount;
  final int actualLeaveCounts;
  final int takenLeaveCount;

  final String recurrenceType;
  final int applyBeforeDay;
  final String employeementType;
  final String eligibleGender;
  final double weight;
  final int noOfDays;

  final bool halfDayAllowed;
  final bool excludeHolidays;
  final bool encashAllowed;
  final int? maxEncashDays;
  final bool carryForwardAllowed;

  final DateTime? refreshDate;
  final DateTime? resetDate;

  Leave({
    required this.leaveCategoryId,
    required this.categoryName,
    required this.leaveCount,
    required this.noPayLeaveCount,
    required this.actualLeaveCounts,
    required this.takenLeaveCount,
    required this.recurrenceType,
    required this.applyBeforeDay,
    required this.employeementType,
    required this.eligibleGender,
    required this.weight,
    required this.noOfDays,
    required this.halfDayAllowed,
    required this.excludeHolidays,
    required this.encashAllowed,
    this.maxEncashDays,
    required this.carryForwardAllowed,
    this.refreshDate,
    this.resetDate,
  });

  /// Normalize double values (int / double / string)
  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      leaveCategoryId: json['leave_category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      leaveCount: _toDouble(json['leave_count']),
      noPayLeaveCount: _toDouble(json['noPayLeaveCount']),
      actualLeaveCounts: json['actualLeaveCounts'] ?? 0,
      takenLeaveCount: json['takenLeaveCount'] ?? 0,
      recurrenceType: json['recurrence_type'] ?? '',
      applyBeforeDay: json['apply_before_day'] ?? 0,
      employeementType: json['employeement_type'] ?? '',
      eligibleGender: json['eligible_gender'] ?? '',
      weight: _toDouble(json['weight']),
      noOfDays: json['no_of_days'] ?? 0,
      halfDayAllowed: json['half_day_allowed'] ?? false,
      excludeHolidays: json['exclude_holidays'] ?? false,
      encashAllowed: json['encash_allowed'] ?? false,
      maxEncashDays: json['max_encash_days'],
      carryForwardAllowed: json['carry_forward_allowed'] ?? false,
      refreshDate: json['refresh_date'] != null
          ? DateTime.tryParse(json['refresh_date'])
          : null,
      resetDate: json['reset_date'] != null
          ? DateTime.tryParse(json['reset_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'leave_category_id': leaveCategoryId,
        'category_name': categoryName,
        'leave_count': leaveCount,
        'noPayLeaveCount': noPayLeaveCount,
        'actualLeaveCounts': actualLeaveCounts,
        'takenLeaveCount': takenLeaveCount,
        'recurrence_type': recurrenceType,
        'apply_before_day': applyBeforeDay,
        'employeement_type': employeementType,
        'eligible_gender': eligibleGender,
        'weight': weight,
        'no_of_days': noOfDays,
        'half_day_allowed': halfDayAllowed,
        'exclude_holidays': excludeHolidays,
        'encash_allowed': encashAllowed,
        'max_encash_days': maxEncashDays,
        'carry_forward_allowed': carryForwardAllowed,
        'refresh_date': refreshDate?.toIso8601String(),
        'reset_date': resetDate?.toIso8601String(),
      };

  /// ===============================
  /// UI HELPERS
  /// ===============================
  double get remainingRaw => leaveCount - actualLeaveCounts;

  String get remainingLabel {
    final r = remainingRaw;
    if ((r - r.round()).abs() < 0.000001) {
      return r.round().toString();
    }
    return r.toStringAsFixed(1);
  }
}

/// ===============================
/// RESPONSE WRAPPER
/// ===============================
class LeaveResponse {
  final bool success;
  final EmployeeInfo employeeInfo;
  final List<Leave> leaves;
  final Map<String, int> leaveCategoryCounts;

  LeaveResponse({
    required this.success,
    required this.employeeInfo,
    required this.leaves,
    required this.leaveCategoryCounts,
  });

  factory LeaveResponse.fromJson(Map<String, dynamic> json) {
    return LeaveResponse(
      success: json['success'] ?? false,
      employeeInfo: EmployeeInfo.fromJson(
        (json['employeeInfo'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      leaves: (json['leaves'] as List? ?? [])
          .map((e) => Leave.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      leaveCategoryCounts: Map<String, int>.from(
        (json['leaveCategoryCounts'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), (v ?? 0) as int)),
      ),
    );
  }

  factory LeaveResponse.fromJsonString(String source) =>
      LeaveResponse.fromJson(jsonDecode(source));
}

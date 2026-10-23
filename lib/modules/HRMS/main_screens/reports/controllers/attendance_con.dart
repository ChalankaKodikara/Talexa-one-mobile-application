// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/auth/authservices.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceReportController extends GetxController {
  final AuthService authService = AuthService();

  final RxList<Map<String, dynamic>> attendanceData =
      <Map<String, dynamic>>[].obs;

  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString username = ''.obs;
  final RxString employeeName = ''.obs;

  final RxInt totalRecords = 0.obs;
  final RxInt presentDays = 0.obs;
  final RxInt lateDays = 0.obs;
  final RxInt absentDays = 0.obs;
  final RxInt leaveDays = 0.obs;
  final RxInt incompleteDays = 0.obs;

  bool _isDisposed = false;
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  @override
  void onClose() {
    _isDisposed = true;
    super.onClose();
  }

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      username.value = _firstValidString([
        prefs.getString('employee_no'),
        prefs.getString('employee_id'),
        prefs.getString('username'),
      ]);

      employeeName.value = _firstValidString([
        prefs.getString('emp_name'),
        prefs.getString('employee_name'),
        prefs.getString('employee_fullname'),
      ]);

      endDate.value = DateTime.now();
      startDate.value = DateTime.now().subtract(const Duration(days: 7));

      if (username.value.isEmpty) {
        hasError.value = true;
        errorMessage.value =
            'Employee number was not found. Please log in again.';
        return;
      }

      await fetchAttendance();
    } catch (error) {
      hasError.value = true;
      errorMessage.value = 'Unable to load the logged-in employee details.';
    }
  }

  Future<void> fetchAttendance() async {
    final employeeNo = username.value.trim();
    final fromDate = startDate.value;
    final toDate = endDate.value;

    if (employeeNo.isEmpty || fromDate == null || toDate == null) {
      return;
    }

    final currentRequestId = ++_requestId;

    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final List<Map<String, dynamic>> response =
          await authService.attendance.fetchAttendanceRange(
        employeeNo,
        fromDate,
        toDate,
      );

      if (_isDisposed || currentRequestId != _requestId) {
        return;
      }

      final normalizedRecords = response
          .map(_normalizeAttendanceRecord)
          .where((record) => record.isNotEmpty)
          .toList();

      normalizedRecords.sort((a, b) {
        final aDate = _parseDate(a['date']);
        final bDate = _parseDate(b['date']);

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      attendanceData.assignAll(normalizedRecords);
      _calculateSummary(normalizedRecords);
    } catch (error) {
      if (_isDisposed || currentRequestId != _requestId) {
        return;
      }

      attendanceData.clear();
      _resetSummary();

      hasError.value = true;
      errorMessage.value = _extractErrorMessage(error);
    } finally {
      if (!_isDisposed && currentRequestId == _requestId) {
        isLoading.value = false;
      }
    }
  }

  Future<void> refreshAttendance() async {
    await fetchAttendance();
  }

  Future<void> setStartDate(DateTime date) async {
    startDate.value = _dateOnly(date);

    if (endDate.value != null && endDate.value!.isBefore(startDate.value!)) {
      endDate.value = startDate.value;
    }

    await fetchAttendance();
  }

  Future<void> setEndDate(DateTime date) async {
    endDate.value = _dateOnly(date);

    if (startDate.value != null && startDate.value!.isAfter(endDate.value!)) {
      startDate.value = endDate.value;
    }

    await fetchAttendance();
  }

  Future<void> setDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    DateTime normalizedStart = _dateOnly(start);
    DateTime normalizedEnd = _dateOnly(end);

    if (normalizedStart.isAfter(normalizedEnd)) {
      final temporary = normalizedStart;
      normalizedStart = normalizedEnd;
      normalizedEnd = temporary;
    }

    startDate.value = normalizedStart;
    endDate.value = normalizedEnd;

    await fetchAttendance();
  }

  Future<void> setLastSevenDays() async {
    final today = _dateOnly(DateTime.now());

    endDate.value = today;
    startDate.value = today.subtract(const Duration(days: 7));

    await fetchAttendance();
  }

  Future<void> setCurrentMonth() async {
    final today = _dateOnly(DateTime.now());

    startDate.value = DateTime(today.year, today.month, 1);
    endDate.value = today;

    await fetchAttendance();
  }

  Map<String, dynamic> _normalizeAttendanceRecord(
    Map<String, dynamic> source,
  ) {
    final record = Map<String, dynamic>.from(source);

    final checkInAddress = _extractAddress(
      record['check_in_address'] ??
          record['checkIN_address'] ??
          _nestedValue(record, ['legacy_address', 'checkin', 'address']) ??
          _nestedValue(record, ['legacy_address', 'check_in', 'address']),
    );

    final checkOutAddress = _extractAddress(
      record['check_out_address'] ??
          record['checkOUT_address'] ??
          _nestedValue(record, ['legacy_address', 'checkout', 'address']) ??
          _nestedValue(record, ['legacy_address', 'check_out', 'address']),
    );

    final normalizedStatus = _resolveStatus(record);
    final authorizationStatus = _resolveAuthorizationStatus(record);

    return {
      ...record,
      'employee_id': record['employee_id'],
      'employee_no': _cleanValue(record['employee_no']),
      'employee_fullname': _cleanValue(record['employee_fullname']),
      'employee_active_status': _cleanValue(record['employee_active_status']),
      'organization_id': record['organization_id'],
      'organization_code': _cleanValue(record['organization_code']),
      'organization_name': _cleanValue(record['organization_name']),
      'date': _cleanValue(record['date']),
      'check_in_time': _cleanValue(
        record['check_in_time'] ?? record['checkIN_time'],
      ),
      'check_out_time': _cleanValue(
        record['check_out_time'] ?? record['checkOUT_time'],
      ),
      'check_in_type': _cleanValue(
        record['check_in_type'] ?? record['checkIN_type'],
      ),
      'check_out_type': _cleanValue(
        record['check_out_type'] ?? record['checkOUT_type'],
      ),
      'check_in_address': checkInAddress,
      'check_out_address': checkOutAddress,
      'status': normalizedStatus,
      'raw_status': _cleanValue(record['status']),
      'OT': _cleanValue(record['OT'] ?? record['ot']),
      'checkIN_source': _cleanValue(record['checkIN_source']),
      'checkOUT_source': _cleanValue(record['checkOUT_source']),
      'checkIN_mode': _cleanValue(record['checkIN_mode']),
      'checkOUT_mode': _cleanValue(record['checkOUT_mode']),
      'checkIN_authorization_status':
          _cleanValue(record['checkIN_authorization_status']),
      'checkOUT_authorization_status':
          _cleanValue(record['checkOUT_authorization_status']),
      'authorization_status': authorizationStatus,
      'is_authorized_location':
          _toNullableBool(record['is_authorized_location']),
      'authorized_location_id': record['authorized_location_id'],
      'is_mixed_source': _toNullableBool(record['is_mixed_source']),
      'worked_minutes': _toNullableInt(record['worked_minutes']),
      'late_minutes': _toNullableInt(record['late_minutes']),
      'early_departure_minutes':
          _toNullableInt(record['early_departure_minutes']),
      'overtime_minutes': _toNullableInt(record['overtime_minutes']),
      'is_missing_checkin': _toNullableBool(record['is_missing_checkin']),
      'is_missing_checkout': _toNullableBool(record['is_missing_checkout']),
      'check_in_address_authorized_status':
          _cleanValue(record['check_in_address_authorized_status']),
      'check_out_address_authorized_status':
          _cleanValue(record['check_out_address_authorized_status']),
      'has_attendance': _hasAttendance(record),
    };
  }

  String _resolveStatus(Map<String, dynamic> record) {
    final status = _cleanValue(record['status']);

    if (status.isNotEmpty) {
      return status;
    }

    final date = _cleanValue(record['date']);
    final checkIn = _cleanValue(
      record['check_in_time'] ?? record['checkIN_time'],
    );
    final checkOut = _cleanValue(
      record['check_out_time'] ?? record['checkOUT_time'],
    );

    if (date.isEmpty && checkIn.isEmpty && checkOut.isEmpty) {
      return 'No attendance';
    }

    final missingCheckIn = _toNullableBool(record['is_missing_checkin']);
    final missingCheckOut = _toNullableBool(record['is_missing_checkout']);

    if (missingCheckIn == true || missingCheckOut == true) {
      return 'Incomplete';
    }

    if (checkIn.isNotEmpty || checkOut.isNotEmpty) {
      return 'Present';
    }

    return 'No attendance';
  }

  String _resolveAuthorizationStatus(Map<String, dynamic> record) {
    final directStatus = _cleanValue(record['authorization_status']);

    if (directStatus.isNotEmpty) {
      return directStatus;
    }

    final isAuthorized = _toNullableBool(record['is_authorized_location']);

    if (isAuthorized == true) {
      return 'AUTHORIZED';
    }

    if (isAuthorized == false) {
      return 'UNAUTHORIZED';
    }

    final checkInStatus = _cleanValue(record['checkIN_authorization_status']);
    final checkOutStatus = _cleanValue(record['checkOUT_authorization_status']);

    if (checkInStatus.isNotEmpty && checkOutStatus.isNotEmpty) {
      if (checkInStatus.toUpperCase() == checkOutStatus.toUpperCase()) {
        return checkInStatus;
      }

      return 'MIXED';
    }

    if (checkInStatus.isNotEmpty) {
      return checkInStatus;
    }

    if (checkOutStatus.isNotEmpty) {
      return checkOutStatus;
    }

    return '';
  }

  bool _hasAttendance(Map<String, dynamic> record) {
    final values = [
      record['date'],
      record['check_in_time'],
      record['checkIN_time'],
      record['check_out_time'],
      record['checkOUT_time'],
      record['status'],
    ];

    return values.any((value) => _cleanValue(value).isNotEmpty);
  }

  void _calculateSummary(List<Map<String, dynamic>> records) {
    int present = 0;
    int late = 0;
    int absent = 0;
    int leave = 0;
    int incomplete = 0;

    for (final record in records) {
      final status = _cleanValue(record['status']).toLowerCase();

      if (status.contains('late')) {
        late++;
        present++;
      } else if (status.contains('absent')) {
        absent++;
      } else if (status.contains('leave')) {
        leave++;
      } else if (status.contains('incomplete') ||
          record['is_missing_checkin'] == true ||
          record['is_missing_checkout'] == true) {
        incomplete++;
      } else if (status.contains('present') ||
          status.contains('normal') ||
          status.contains('short') ||
          status.contains('half')) {
        present++;
      }
    }

    totalRecords.value = records.length;
    presentDays.value = present;
    lateDays.value = late;
    absentDays.value = absent;
    leaveDays.value = leave;
    incompleteDays.value = incomplete;
  }

  void _resetSummary() {
    totalRecords.value = 0;
    presentDays.value = 0;
    lateDays.value = 0;
    absentDays.value = 0;
    leaveDays.value = 0;
    incompleteDays.value = 0;
  }

  dynamic _nestedValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    dynamic current = map;

    for (final key in keys) {
      if (current is! Map) {
        return null;
      }

      current = current[key];
    }

    return current;
  }

  String _extractAddress(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return _cleanValue(value);
    }

    if (value is Map) {
      final preferredValues = [
        value['formatted_address'],
        value['address'],
        value['display_name'],
        value['name'],
        value['full_address'],
      ];

      for (final item in preferredValues) {
        final text = _cleanValue(item);

        if (text.isNotEmpty) {
          return text;
        }
      }

      final addressParts = [
        value['street'],
        value['route'],
        value['locality'],
        value['city'],
        value['district'],
        value['state'],
        value['country'],
      ].map(_cleanValue).where((item) => item.isNotEmpty).toList();

      if (addressParts.isNotEmpty) {
        return addressParts.join(', ');
      }
    }

    return _cleanValue(value);
  }

  DateTime? _parseDate(dynamic value) {
    final text = _cleanValue(value);

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _cleanValue(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'undefined') {
      return '';
    }

    return text;
  }

  String _firstValidString(List<String?> values) {
    for (final value in values) {
      final normalized = _cleanValue(value);

      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return '';
  }

  bool? _toNullableBool(dynamic value) {
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

    if (['true', '1', 'yes', 'y', 'authorized'].contains(normalized)) {
      return true;
    }

    if (['false', '0', 'no', 'n', 'unauthorized'].contains(normalized)) {
      return false;
    }

    return null;
  }

  int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return double.tryParse(value.toString())?.round();
  }

  String _extractErrorMessage(dynamic error) {
    final text = error.toString().trim();

    if (text.isEmpty) {
      return 'Failed to load attendance records.';
    }

    if (text.startsWith('Exception:')) {
      return text.replaceFirst('Exception:', '').trim();
    }

    return text;
  }
}

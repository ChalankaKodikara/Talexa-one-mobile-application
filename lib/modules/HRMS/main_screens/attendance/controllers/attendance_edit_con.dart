import 'package:corehris/auth/authservices.dart';
import 'package:corehris/auth/tenant/attendance_api.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceEditController extends GetxController {
  AttendanceEditController({
    AttendanceApi? attendanceApi,
  }) : attendanceApi = attendanceApi ?? AuthService.instance.attendance;

  // ============================================================
  // SERVICES
  // ============================================================

  final AttendanceApi attendanceApi;
  final AuthService authService = AuthService.instance;

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ============================================================
  // PAGE STATE
  // ============================================================

  final RxBool isInitializing = true.obs;
  final RxBool isFetchingAttendance = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool hasChanges = false.obs;
  final RxBool attendanceFound = false.obs;

  final RxString fetchMessage = ''.obs;

  // ============================================================
  // EMPLOYEE
  // ============================================================

  final RxString employeeId = ''.obs;
  final RxString employeeNo = ''.obs;
  final RxString employeeName = ''.obs;

  // ============================================================
  // DATE
  // ============================================================

  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // ============================================================
  // ACTUAL ATTENDANCE
  // ============================================================

  final RxString currentCheckIn = ''.obs;
  final RxString currentCheckOut = ''.obs;
  final RxString currentStatus = ''.obs;

  // ============================================================
  // ADJUSTED VALUES
  // ============================================================

  final TextEditingController checkInTimeController = TextEditingController();

  final TextEditingController checkOutTimeController = TextEditingController();

  final RxString selectedStatus = 'Normal day'.obs;

  // ============================================================
  // USER EDIT TYPE
  // ============================================================
  //
  // These are ONLY used by the mobile UI.
  //
  // They are NOT sent to the backend as adjustment_type.
  //
  // ============================================================

  static const String editFullDay = 'FULL_DAY';

  static const String editCheckIn = 'CHECK_IN';

  static const String editCheckOut = 'CHECK_OUT';

  static const String editStatus = 'STATUS';

  final RxString selectedEditType = ''.obs;

  // ============================================================
  // BACKEND ADJUSTMENT
  // ============================================================

  final RxString adjustmentType = ''.obs;

  String _requestedEntryType = ''; 

  static const String addCheckIn = 'ADD_CHECK_IN';

  static const String updateCheckIn = 'UPDATE_CHECK_IN';

  static const String addCheckOut = 'ADD_CHECK_OUT';

  static const String updateCheckOut = 'UPDATE_CHECK_OUT';

  static const String updateStatus = 'UPDATE_STATUS';

  static const String fullDayCorrection = 'FULL_DAY_CORRECTION';

  // ============================================================
  // REASON / ATTACHMENT
  // ============================================================

  final TextEditingController reasonController = TextEditingController();

  final TextEditingController attachmentUrlController = TextEditingController();

  // ============================================================
  // CURRENT RECORD
  // ============================================================

  Map<String, dynamic> currentAttendance = <String, dynamic>{};

  // ============================================================
  // STATUS
  // ============================================================

  final List<String> statuses = <String>[
    'Present',
    'Normal day',
    'Late in',
    'Absent',
    'Half day',
    'Short leave',
    'Leave',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    _registerListeners();

    initialize();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    isInitializing.value = true;

    try {
      await authService.initialize();

      await _loadUserFromSharedPreferences();

      _readArguments();

      if (employeeNo.value.trim().isEmpty) {
        attendanceFound.value = false;

        fetchMessage.value =
            'Employee number was not found. Please log in again.';

        return;
      }

      await fetchAttendanceForSelectedDate();

      if (attendanceFound.value && _requestedEntryType.isNotEmpty) {
        final entry = _requestedEntryType;
        if ((entry == addCheckIn && !hasCurrentCheckIn) ||
            (entry == updateCheckIn && hasCurrentCheckIn)) {
          selectEditType(editCheckIn);
        } else if ((entry == addCheckOut && !hasCurrentCheckOut) ||
                   (entry == updateCheckOut && hasCurrentCheckOut)) {
          selectEditType(editCheckOut);
        } else if (entry == updateStatus) {
          selectEditType(editStatus);
        } else if (entry == fullDayCorrection) {
          selectEditType(editFullDay);
        }
      }

      hasChanges.value = false;
    } catch (e, stackTrace) {
      debugPrint(
        'AttendanceEditController.initialize error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      attendanceFound.value = false;

      fetchMessage.value = 'Unable to load attendance details.';

      AppAlert.toast(
        title: 'Attendance',
        message: 'Unable to load attendance details.',
      );
    } finally {
      isInitializing.value = false;
    }
  }

  // ============================================================
  // USER
  // ============================================================

  Future<void> _loadUserFromSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    employeeNo.value = _firstValidString(
      <String?>[
        prefs.getString('employee_no'),
        prefs.getString('employee_id'),
        prefs.getString('username'),
      ],
    );

    employeeId.value = employeeNo.value;

    employeeName.value = _firstValidString(
      <String?>[
        prefs.getString('emp_name'),
        prefs.getString('employee_name'),
        prefs.getString('employee_fullname'),
        prefs.getString('full_name'),
      ],
    );

    debugPrint(
      '==============================================',
    );
    debugPrint('ATTENDANCE EDIT USER');
    debugPrint(
      'employee_no: ${employeeNo.value}',
    );
    debugPrint(
      'employee_name: ${employeeName.value}',
    );
    debugPrint(
      '==============================================',
    );
  }

  String _firstValidString(
    List<String?> values,
  ) {
    for (final String? value in values) {
      if (value == null) {
        continue;
      }

      final String result = value.trim();

      if (result.isNotEmpty && result.toLowerCase() != 'null') {
        return result;
      }
    }

    return '';
  }

  // ============================================================
  // ARGUMENTS
  // ============================================================

  void _readArguments() {
    final dynamic arguments = Get.arguments;

    if (arguments is! Map) {
      return;
    }

    final Map<String, dynamic> args = Map<String, dynamic>.from(
      arguments,
    );

    _requestedEntryType = _readMap(args, <String>['adjustment_type']);

    final String argumentDate = _readMap(
      args,
      <String>[
        'date',
        'work_date_local',
        'attendance_date',
      ],
    );

    final DateTime? parsedDate = _parseDate(argumentDate);

    if (parsedDate != null) {
      selectedDate.value = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );
    }

    final String argumentEmployee = _readMap(
      args,
      <String>[
        'employee_no',
        'employee_id',
      ],
    );

    if (argumentEmployee.isNotEmpty) {
      employeeNo.value = argumentEmployee;
      employeeId.value = argumentEmployee;
    }

    final String argumentEmployeeName = _readMap(
      args,
      <String>[
        'employee_name',
        'employee_fullname',
        'full_name',
      ],
    );

    if (argumentEmployeeName.isNotEmpty) {
      employeeName.value = argumentEmployeeName;
    }
  }

  // ============================================================
  // FETCH
  // ============================================================

  Future<void> fetchAttendanceForSelectedDate() async {
    if (isFetchingAttendance.value) {
      return;
    }

    final String employee = employeeNo.value.trim();

    if (employee.isEmpty) {
      attendanceFound.value = false;

      fetchMessage.value = 'Employee number was not found.';

      _clearFetchedAttendance();

      return;
    }

    isFetchingAttendance.value = true;
    fetchMessage.value = '';

    try {
      debugPrint(
        '==============================================',
      );
      debugPrint('ATTENDANCE FETCH');
      debugPrint(
        'employee_no: $employee',
      );
      debugPrint('from: $apiDate');
      debugPrint('to: $apiDate');
      debugPrint(
        '==============================================',
      );

      final List<Map<String, dynamic>> records =
          await attendanceApi.fetchAttendanceRange(
        employee,
        selectedDate.value,
        selectedDate.value,
      );

      debugPrint(
        'Attendance records received: ${records.length}',
      );

      if (records.isEmpty) {
        attendanceFound.value = false;

        currentAttendance = <String, dynamic>{};

        fetchMessage.value = 'No attendance found for $formattedDate.';

        _clearFetchedAttendance();

        return;
      }

      Map<String, dynamic>? attendance;

      for (final Map<String, dynamic> item in records) {
        final String recordDate = _readMap(
          item,
          <String>[
            'date',
            'work_date_local',
            'attendance_date',
          ],
        );

        if (_normalizeDateString(
              recordDate,
            ) ==
            apiDate) {
          attendance = item;
          break;
        }
      }

      attendance ??= records.first;

      currentAttendance = Map<String, dynamic>.from(
        attendance,
      );

      attendanceFound.value = true;

      _populateAttendance(
        currentAttendance,
      );

      fetchMessage.value = 'Attendance loaded successfully.';

      hasChanges.value = false;
    } catch (e, stackTrace) {
      debugPrint(
        'Attendance fetch error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      attendanceFound.value = false;

      currentAttendance = <String, dynamic>{};

      fetchMessage.value = _cleanError(e);

      _clearFetchedAttendance();

      AppAlert.toast(
        title: 'Attendance',
        message: _cleanError(e),
      );
    } finally {
      isFetchingAttendance.value = false;
    }
  }

  Future<void> refreshAttendance() async {
    await fetchAttendanceForSelectedDate();
  }

  // ============================================================
  // POPULATE
  // ============================================================

  void _populateAttendance(
    Map<String, dynamic> attendance,
  ) {
    final String fetchedEmployeeName = _readMap(
      attendance,
      <String>[
        'employee_fullname',
        'employee_name',
        'full_name',
        'name_with_initials',
      ],
    );

    if (fetchedEmployeeName.isNotEmpty) {
      employeeName.value = fetchedEmployeeName;
    }

    currentCheckIn.value = _extractTime(
      _readMap(
        attendance,
        <String>[
          'check_in_time',
          'checkIN_time',
          'checkInTime',
          'check_in',
          'checkIn',
        ],
      ),
    );

    currentCheckOut.value = _extractTime(
      _readMap(
        attendance,
        <String>[
          'check_out_time',
          'checkOUT_time',
          'checkOutTime',
          'check_out',
          'checkOut',
        ],
      ),
    );

    currentStatus.value = _readMap(
      attendance,
      <String>[
        'rawStatus',
        'raw_status',
        'status',
        'attendance_status',
      ],
    );

    // IMPORTANT:
    // reset edit mode BEFORE setting controllers.
    selectedEditType.value = '';

    checkInTimeController.text = currentCheckIn.value;

    checkOutTimeController.text = currentCheckOut.value;

    selectedStatus.value = _normalizeStatus(
      currentStatus.value,
    );

    reasonController.clear();
    attachmentUrlController.clear();

    adjustmentType.value = '';
    hasChanges.value = false;

    debugPrint(
      '==============================================',
    );
    debugPrint(
      'ACTUAL CHECK IN: ${currentCheckIn.value}',
    );
    debugPrint(
      'ACTUAL CHECK OUT: ${currentCheckOut.value}',
    );
    debugPrint(
      'ACTUAL STATUS: ${currentStatus.value}',
    );
    debugPrint(
      '==============================================',
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void _clearFetchedAttendance() {
    selectedEditType.value = '';

    currentCheckIn.value = '';
    currentCheckOut.value = '';
    currentStatus.value = '';

    checkInTimeController.clear();
    checkOutTimeController.clear();

    selectedStatus.value = 'Normal day';

    reasonController.clear();
    attachmentUrlController.clear();

    adjustmentType.value = '';

    hasChanges.value = false;
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> selectDate(
    BuildContext context,
  ) async {
    if (isSaving.value || isFetchingAttendance.value) {
      return;
    }

    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(
        2020,
        1,
        1,
      ),
      lastDate: DateTime.now(),
    );

    if (result == null) {
      return;
    }

    selectedDate.value = DateTime(
      result.year,
      result.month,
      result.day,
    );

    selectedEditType.value = '';

    await fetchAttendanceForSelectedDate();
  }

  String get formattedDate => DateFormat(
        'dd MMM yyyy',
      ).format(
        selectedDate.value,
      );

  String get apiDate => DateFormat(
        'yyyy-MM-dd',
      ).format(
        selectedDate.value,
      );

  // ============================================================
  // EDIT TYPE
  // ============================================================

  bool get hasSelectedEditType => selectedEditType.value.isNotEmpty;

  bool get isFullDayEdit => selectedEditType.value == editFullDay;

  bool get isCheckInEdit => selectedEditType.value == editCheckIn;

  bool get isCheckOutEdit => selectedEditType.value == editCheckOut;

  bool get isStatusEdit => selectedEditType.value == editStatus;

  bool get canEditCheckIn => isFullDayEdit || isCheckInEdit;

  bool get canEditCheckOut => isFullDayEdit || isCheckOutEdit;

  void selectEditType(
    String type,
  ) {
    if (isSaving.value) {
      return;
    }

    if (type != editFullDay && type != editCheckIn && type != editCheckOut && type != editStatus) {
      return;
    }

    // IMPORTANT:
    // select first before changing controller values.
    //
    // The TextEditingControllers have listeners.
    selectedEditType.value = type;

    // Reset edited values to actual values.
    checkInTimeController.text = currentCheckIn.value;

    checkOutTimeController.text = currentCheckOut.value;

    // Do NOT call setStatus() here.
    selectedStatus.value = _normalizeStatus(
      currentStatus.value,
    );

    reasonController.clear();
    attachmentUrlController.clear();

    adjustmentType.value = '';
    hasChanges.value = false;

    debugPrint(
      '==============================================',
    );
    debugPrint(
      'SELECTED EDIT TYPE: $type',
    );
    debugPrint(
      '==============================================',
    );
  }

  // ============================================================
  // CHECK IN
  // ============================================================

  Future<void> selectCheckInTime(
    BuildContext context,
  ) async {
    if (isSaving.value) {
      return;
    }

    if (!hasSelectedEditType) {
      AppAlert.toast(
        title: 'Attendance',
        message: 'Please select what you want to edit first.',
      );

      return;
    }

    if (!canEditCheckIn) {
      return;
    }

    final TimeOfDay initialTime = _parseTime(
          checkInTimeController.text,
        ) ??
        TimeOfDay.now();

    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (result == null) {
      return;
    }

    checkInTimeController.text = _formatTime(result);
  }

  // ============================================================
  // CHECK OUT
  // ============================================================

  Future<void> selectCheckOutTime(
    BuildContext context,
  ) async {
    if (isSaving.value) {
      return;
    }

    if (!hasSelectedEditType) {
      AppAlert.toast(
        title: 'Attendance',
        message: 'Please select what you want to edit first.',
      );

      return;
    }

    if (!canEditCheckOut) {
      return;
    }

    final TimeOfDay initialTime = _parseTime(
          checkOutTimeController.text,
        ) ??
        TimeOfDay.now();

    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (result == null) {
      return;
    }

    checkOutTimeController.text = _formatTime(result);
  }

  // ============================================================
  // CLEAR TIME
  // ============================================================

  void clearCheckInTime() {
    if (isSaving.value) {
      return;
    }

    if (!canEditCheckIn) {
      return;
    }

    checkInTimeController.clear();
  }

  void clearCheckOutTime() {
    if (isSaving.value) {
      return;
    }

    if (!canEditCheckOut) {
      return;
    }

    checkOutTimeController.clear();
  }

  // ============================================================
  // STATUS
  // ============================================================

  void setStatus(
    String? value,
  ) {
    if (value == null || isSaving.value) {
      return;
    }

    if (!hasSelectedEditType) {
      AppAlert.toast(
        title: 'Attendance',
        message: 'Please select what you want to edit first.',
      );

      return;
    }

    selectedStatus.value = value;

    _updateInstantAdjustmentType();
  }

  // ============================================================
  // ORIGINAL VALUES
  // ============================================================

  bool get hasCurrentCheckIn => currentCheckIn.value.trim().isNotEmpty;

  bool get hasCurrentCheckOut => currentCheckOut.value.trim().isNotEmpty;

  bool get hasCurrentStatus => currentStatus.value.trim().isNotEmpty;

  // ============================================================
  // CHANGES
  // ============================================================

  bool get checkInChanged {
    final String original = _normalizeTimeForCompare(
      currentCheckIn.value,
    );

    final String edited = _normalizeTimeForCompare(
      checkInTimeController.text,
    );

    return original != edited;
  }

  bool get checkOutChanged {
    final String original = _normalizeTimeForCompare(
      currentCheckOut.value,
    );

    final String edited = _normalizeTimeForCompare(
      checkOutTimeController.text,
    );

    return original != edited;
  }

  bool get statusChanged {
    final String original = _canonicalStatus(
      currentStatus.value,
    );

    final String edited = _canonicalStatus(
      selectedStatus.value,
    );

    return original != edited;
  }

  bool get hasAttendanceChanges {
    if (!hasSelectedEditType) {
      return false;
    }

    if (isCheckInEdit) {
      return checkInChanged || statusChanged;
    }

    if (isCheckOutEdit) {
      return checkOutChanged || statusChanged;
    }

    if (isFullDayEdit) {
      return checkInChanged || checkOutChanged || statusChanged;
    }

    if (isStatusEdit) {
      return statusChanged;
    }

    return false;
  }

  // ============================================================
  // AUTO DETECTION
  // ============================================================

  void _updateInstantAdjustmentType() {
    if (isInitializing.value || isFetchingAttendance.value) {
      return;
    }

    // IMPORTANT:
    // NEVER show a toast here.
    //
    // This function is triggered automatically
    // by TextEditingController listeners.
    if (!hasSelectedEditType) {
      adjustmentType.value = '';
      hasChanges.value = false;
      return;
    }

    adjustmentType.value = _determineAdjustmentType();

    hasChanges.value = hasAttendanceChanges ||
        reasonController.text.trim().isNotEmpty ||
        attachmentUrlController.text.trim().isNotEmpty;

    debugPrint(
      'EDIT TYPE: ${selectedEditType.value}',
    );

    debugPrint(
      'BACKEND TYPE: ${adjustmentType.value}',
    );
  }

  // ============================================================
  // BACKEND TYPE
  // ============================================================

  String _determineAdjustmentType() {
    if (!hasSelectedEditType) {
      return '';
    }

    final bool inChanged = canEditCheckIn && checkInChanged;

    final bool outChanged = canEditCheckOut && checkOutChanged;

    final bool statChanged = statusChanged;

    final int changedFields =
        (inChanged ? 1 : 0) + (outChanged ? 1 : 0) + (statChanged ? 1 : 0);

    if (changedFields == 0) {
      return '';
    }

    if (isFullDayEdit && changedFields > 0) {
      return fullDayCorrection;
    }

    if (changedFields > 1) {
      return fullDayCorrection;
    }

    if (inChanged) {
      final String original = _normalizeTimeForCompare(
        currentCheckIn.value,
      );

      final String edited = _normalizeTimeForCompare(
        checkInTimeController.text,
      );

      if (original.isEmpty && edited.isNotEmpty) {
        return addCheckIn;
      }

      if (original.isNotEmpty && edited.isNotEmpty) {
        return updateCheckIn;
      }

      return fullDayCorrection;
    }

    if (outChanged) {
      final String original = _normalizeTimeForCompare(
        currentCheckOut.value,
      );

      final String edited = _normalizeTimeForCompare(
        checkOutTimeController.text,
      );

      if (original.isEmpty && edited.isNotEmpty) {
        return addCheckOut;
      }

      if (original.isNotEmpty && edited.isNotEmpty) {
        return updateCheckOut;
      }

      return fullDayCorrection;
    }

    if (statChanged) {
      return updateStatus;
    }

    return '';
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? validateTime(
    String? value,
  ) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final RegExp hhmm = RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)$',
    );

    final RegExp hhmmss = RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d)$',
    );

    if (!hhmm.hasMatch(text) && !hhmmss.hasMatch(text)) {
      return 'Enter a valid time';
    }

    return null;
  }

  String? validateReason(
    String? value,
  ) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter a reason';
    }

    if (text.length < 5) {
      return 'Reason is too short';
    }

    return null;
  }

  // ============================================================
  // REQUEST DATETIME
  // ============================================================

  DateTime? _buildRequestedDateTime(
    String timeValue,
  ) {
    final String value = _normalizeTimeForCompare(
      timeValue,
    );

    if (value.isEmpty) {
      return null;
    }

    final List<String> parts = value.split(':');

    if (parts.length < 2) {
      return null;
    }

    final int? hour = int.tryParse(parts[0]);

    final int? minute = int.tryParse(parts[1]);

    final int second = parts.length >= 3
        ? int.tryParse(
              parts[2],
            ) ??
            0
        : 0;

    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return null;
    }

    return DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
      hour,
      minute,
      second,
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> updateAttendance() async {
    if (isSaving.value) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    // ----------------------------------------------------------
    // EDIT TYPE
    // ----------------------------------------------------------

    if (!hasSelectedEditType) {
      AppAlert.toast(
        title: 'Attendance',
        message: 'Please select what you want to edit.',
      );

      return;
    }

    // ----------------------------------------------------------
    // FORM
    // ----------------------------------------------------------

    if (!(formKey.currentState?.validate() ?? false)) {
      AppAlert.toast(
        title: 'Validation',
        message: 'Please correct the highlighted fields.',
      );

      return;
    }

    // ----------------------------------------------------------
    // EMPLOYEE
    // ----------------------------------------------------------

    final String employee = employeeNo.value.trim();

    if (employee.isEmpty) {
      AppAlert.toast(
        title: 'Attendance',
        message: 'Employee number was not found.',
      );

      return;
    }

    // ----------------------------------------------------------
    // ATTENDANCE
    // ----------------------------------------------------------

    if (!attendanceFound.value) {
      AppAlert.toast(
        title: 'Attendance',
        message: 'No attendance record exists for $formattedDate.',
      );

      return;
    }

    // ----------------------------------------------------------
    // REASON
    // ----------------------------------------------------------

    final String reason = reasonController.text.trim();

    if (reason.isEmpty) {
      AppAlert.toast(
        title: 'Validation',
        message: 'Please enter a reason for the attendance adjustment.',
      );

      return;
    }

    if (reason.length < 5) {
      AppAlert.toast(
        title: 'Validation',
        message: 'Reason must contain at least 5 characters.',
      );

      return;
    }

    // ----------------------------------------------------------
    // DETECT CHANGE
    // ----------------------------------------------------------

    final String detectedType = _determineAdjustmentType();

    if (detectedType.isEmpty) {
      AppAlert.toast(
        title: 'Attendance',
        message: 'No attendance changes were detected.',
      );

      return;
    }

    adjustmentType.value = detectedType;

    // ----------------------------------------------------------
    // REQUEST CHECK IN
    // ----------------------------------------------------------

    DateTime? requestedCheckIn;

    if (canEditCheckIn &&
        checkInChanged &&
        checkInTimeController.text.trim().isNotEmpty) {
      requestedCheckIn = _buildRequestedDateTime(
        checkInTimeController.text,
      );

      if (requestedCheckIn == null) {
        AppAlert.toast(
          title: 'Validation',
          message: 'Invalid check-in time.',
        );

        return;
      }
    }

    // ----------------------------------------------------------
    // REQUEST CHECK OUT
    // ----------------------------------------------------------

    DateTime? requestedCheckOut;

    if (canEditCheckOut &&
        checkOutChanged &&
        checkOutTimeController.text.trim().isNotEmpty) {
      requestedCheckOut = _buildRequestedDateTime(
        checkOutTimeController.text,
      );

      if (requestedCheckOut == null) {
        AppAlert.toast(
          title: 'Validation',
          message: 'Invalid check-out time.',
        );

        return;
      }
    }

    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    final String requestedStatus = selectedStatus.value.trim();

    if (requestedStatus.isEmpty) {
      AppAlert.toast(
        title: 'Validation',
        message: 'Please select attendance status.',
      );

      return;
    }

    // ----------------------------------------------------------
    // EFFECTIVE TIMES
    // ----------------------------------------------------------

    final String effectiveCheckInText = canEditCheckIn
        ? checkInTimeController.text.trim()
        : currentCheckIn.value.trim();

    final String effectiveCheckOutText = canEditCheckOut
        ? checkOutTimeController.text.trim()
        : currentCheckOut.value.trim();

    final DateTime? effectiveCheckIn = effectiveCheckInText.isEmpty
        ? null
        : _buildRequestedDateTime(
            effectiveCheckInText,
          );

    final DateTime? effectiveCheckOut = effectiveCheckOutText.isEmpty
        ? null
        : _buildRequestedDateTime(
            effectiveCheckOutText,
          );

    if (effectiveCheckIn != null &&
        effectiveCheckOut != null &&
        !effectiveCheckOut.isAfter(
          effectiveCheckIn,
        )) {
      AppAlert.toast(
        title: 'Validation',
        message: 'Check-out time must be after check-in time.',
      );

      return;
    }

    // ----------------------------------------------------------
    // CONFIRM
    // ----------------------------------------------------------

    String correctionName = 'Attendance Correction';

    if (isFullDayEdit) {
      correctionName = 'Full Day Correction';
    } else if (isCheckInEdit) {
      correctionName = 'Check In Correction';
    } else if (isCheckOutEdit) {
      correctionName = 'Check Out Correction';
    } else if (isStatusEdit) {
      correctionName = 'Status Correction';
    }

    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(
          'Submit Attendance Correction?',
        ),
        content: Text(
          'Employee: '
          '${employeeName.value.trim().isNotEmpty ? employeeName.value : employee}\n\n'
          'Date: $formattedDate\n'
          'Correction: $correctionName',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Get.back(
                result: false,
              );
            },
            child: const Text(
              'Cancel',
            ),
          ),
          FilledButton(
            onPressed: () {
              Get.back(
                result: true,
              );
            },
            child: const Text(
              'Submit',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // ----------------------------------------------------------
    // SEND
    // ----------------------------------------------------------

    isSaving.value = true;

    try {
      final String? attachmentUrl = attachmentUrlController.text.trim().isEmpty
          ? null
          : attachmentUrlController.text.trim();

      debugPrint(
        '==============================================',
      );
      debugPrint(
        'ATTENDANCE CORRECTION REQUEST',
      );
      debugPrint(
        'employee_id: $employee',
      );
      debugPrint(
        'work_date_local: $apiDate',
      );
      debugPrint(
        'selected_edit_type: ${selectedEditType.value}',
      );
      debugPrint(
        'adjustment_type: $detectedType',
      );
      debugPrint(
        'requested_check_in: $requestedCheckIn',
      );
      debugPrint(
        'requested_check_out: $requestedCheckOut',
      );
      debugPrint(
        'requested_status: $requestedStatus',
      );
      debugPrint(
        'reason: $reason',
      );
      debugPrint(
        '==============================================',
      );

      final Map<String, dynamic> response =
          await attendanceApi.updateAttendanceEdit(
        employeeId: employee,
        workDate: selectedDate.value,
        adjustmentType: detectedType,
        requestedCheckIn: requestedCheckIn,
        requestedCheckOut: requestedCheckOut,
        requestedStatus: requestedStatus,
        reason: reason,
        attachmentUrl: attachmentUrl,
      );

      if (response['success'] == false) {
        throw Exception(
          response['message']?.toString() ??
              'Unable to submit attendance adjustment.',
        );
      }

      hasChanges.value = false;

      final String message = response['message']?.toString() ??
          'Attendance adjustment submitted successfully.';

      Get.back(
        result: <String, dynamic>{
          'updated': true,
          'employee_id': employee,
          'employee_no': employee,
          'date': apiDate,
          'edit_type': selectedEditType.value,
          'adjustment_type': detectedType,
          'response': response,
        },
      );

      Future<void>.delayed(
        const Duration(
          milliseconds: 150,
        ),
        () {
          AppAlert.toast(
            title: 'Success',
            message: message,
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Attendance adjustment failed: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      AppAlert.toast(
        title: 'Request Failed',
        message: _cleanError(e),
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // DISCARD
  // ============================================================

  Future<bool> confirmDiscard() async {
    if (isSaving.value) {
      return false;
    }

    if (!hasChanges.value) {
      return true;
    }

    final bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(
          'Discard Changes?',
        ),
        content: const Text(
          'You have unsaved attendance changes.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Get.back(
                result: false,
              );
            },
            child: const Text(
              'Continue Editing',
            ),
          ),
          FilledButton(
            onPressed: () {
              Get.back(
                result: true,
              );
            },
            child: const Text(
              'Discard',
            ),
          ),
        ],
      ),
    );

    return result == true;
  }

  // ============================================================
  // LISTENERS
  // ============================================================

  void _registerListeners() {
    checkInTimeController.addListener(
      _updateInstantAdjustmentType,
    );

    checkOutTimeController.addListener(
      _updateInstantAdjustmentType,
    );

    reasonController.addListener(
      _markChanged,
    );

    attachmentUrlController.addListener(
      _markChanged,
    );
  }

  void _markChanged() {
    if (isInitializing.value ||
        isFetchingAttendance.value ||
        !hasSelectedEditType) {
      return;
    }

    hasChanges.value = hasAttendanceChanges ||
        reasonController.text.trim().isNotEmpty ||
        attachmentUrlController.text.trim().isNotEmpty;
  }

  // ============================================================
  // STATUS NORMALIZATION
  // ============================================================

  String _canonicalStatus(
    String value,
  ) {
    final String status = value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        );

    if (status.isEmpty) {
      return 'normal day';
    }

    if (status.contains('absent')) {
      return 'absent';
    }

    if (status.contains('half')) {
      return 'half day';
    }

    if (status.contains('short')) {
      return 'short leave';
    }

    if (status.contains('leave')) {
      return 'leave';
    }

    if (status.contains('late')) {
      return 'late in';
    }

    if (status.contains('normal')) {
      return 'normal day';
    }

    if (status.contains('present')) {
      return 'present';
    }

    return status;
  }

  String _normalizeStatus(
    String value,
  ) {
    switch (_canonicalStatus(value)) {
      case 'present':
        return 'Present';

      case 'normal day':
        return 'Normal day';

      case 'late in':
        return 'Late in';

      case 'absent':
        return 'Absent';

      case 'half day':
        return 'Half day';

      case 'short leave':
        return 'Short leave';

      case 'leave':
        return 'Leave';

      default:
        return 'Normal day';
    }
  }

  // ============================================================
  // MAP
  // ============================================================

  String _readMap(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = source[key];

      if (value == null) {
        continue;
      }

      final String text = value.toString().trim();

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return '';
  }

  // ============================================================
  // DATE
  // ============================================================

  String _normalizeDateString(
    String value,
  ) {
    final DateTime? date = _parseDate(value);

    if (date == null) {
      return value.trim();
    }

    return DateFormat(
      'yyyy-MM-dd',
    ).format(date);
  }

  DateTime? _parseDate(
    String value,
  ) {
    final String raw = value.trim();

    if (raw.isEmpty) {
      return null;
    }

    final DateTime? direct = DateTime.tryParse(raw);

    if (direct != null) {
      return direct;
    }

    const List<String> formats = <String>[
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
    ];

    for (final String format in formats) {
      try {
        return DateFormat(
          format,
        ).parseStrict(raw);
      } catch (_) {}
    }

    return null;
  }

  // ============================================================
  // TIME
  // ============================================================

  String _extractTime(
    String value,
  ) {
    final String raw = value.trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return '';
    }

    if (RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d)$',
    ).hasMatch(raw)) {
      return raw;
    }

    if (RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)$',
    ).hasMatch(raw)) {
      return '$raw:00';
    }

    if (raw.contains(' ')) {
      final String time = raw.split(' ').last.trim();

      if (RegExp(
        r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d)$',
      ).hasMatch(time)) {
        return time;
      }

      if (RegExp(
        r'^([01]\d|2[0-3]):([0-5]\d)$',
      ).hasMatch(time)) {
        return '$time:00';
      }
    }

    final DateTime? parsed = DateTime.tryParse(raw);

    if (parsed != null) {
      return DateFormat(
        'HH:mm:ss',
      ).format(parsed);
    }

    return raw;
  }

  String _normalizeTimeForCompare(
    String value,
  ) {
    final String raw = value.trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return '';
    }

    if (RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d)$',
    ).hasMatch(raw)) {
      return raw;
    }

    if (RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)$',
    ).hasMatch(raw)) {
      return '$raw:00';
    }

    return _extractTime(raw);
  }

  TimeOfDay? _parseTime(
    String value,
  ) {
    final String normalized = _normalizeTimeForCompare(
      value,
    );

    if (normalized.isEmpty) {
      return null;
    }

    final List<String> parts = normalized.split(':');

    if (parts.length < 2) {
      return null;
    }

    final int? hour = int.tryParse(parts[0]);

    final int? minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String _formatTime(
    TimeOfDay value,
  ) {
    final String hour = value.hour.toString().padLeft(
          2,
          '0',
        );

    final String minute = value.minute.toString().padLeft(
          2,
          '0',
        );

    return '$hour:$minute:00';
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .replaceFirst(
          'DioException: ',
          '',
        );
  }

  // ============================================================
  // CLOSE
  // ============================================================

  @override
  void onClose() {
    checkInTimeController.dispose();
    checkOutTimeController.dispose();

    reasonController.dispose();
    attachmentUrlController.dispose();

    super.onClose();
  }
}

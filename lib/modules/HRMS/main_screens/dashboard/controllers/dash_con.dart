import 'dart:async';

import 'package:get/get.dart';
import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardController extends GetxController {
  // -------------------- Identity --------------------
  final username = ''.obs;
  final employeeName = ''.obs;
  final supervisor = 0.obs;
  final organizationId = 0.obs;
  final organizationName = ''.obs;
  final departmentId = 0.obs;
  final isSupervisor = false.obs;

  // -------------------- Attendance --------------------
  final checkINTime = '--:--'.obs;
  final checkOutTime = '--:--'.obs;
  final checkINType = 'Not Yet'.obs;
  final checkOutType = 'Not Yet'.obs;
  final isLoadingAttendance = false.obs;
  final attendanceError = ''.obs;

  // -------------------- Leave --------------------
  final latestLeave = <Map<String, dynamic>>[].obs;
  final todayApprovedLeave = Rxn<Map<String, dynamic>>();
  final isOnLeaveToday = false.obs;

  // -------------------- Notices & Birthdays --------------------
  final todayNotices = <Map<String, dynamic>>[].obs;
  final upcomingBirthdays = <Map<String, dynamic>>[].obs;
  final birthdaysError = ''.obs;

  // -------------------- Profile --------------------
  final profileImageUrl = RxnString();
  final isProfileImageLoading = false.obs;

  // -------------------- My Team Presence --------------------
  final RxList<Map<String, dynamic>> teamPresence = <Map<String, dynamic>>[].obs;
  final isLoadingTeamPresence = false.obs;
  final teamPresenceError = ''.obs;

  // -------------------- Department Presence --------------------
  final RxList<Map<String, dynamic>> departmentPresence = <Map<String, dynamic>>[].obs;
  final isLoadingDepartmentPresence = false.obs;
  final departmentPresenceError = ''.obs;

  final AuthService _authService = Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    unawaited(getIdentityFromCache());
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(loadDashboardData());
  }

  Future<bool> ensureLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) return true;
    final result = await Permission.location.request();
    return result.isGranted;
  }

  Future<void> getIdentityFromCache() async {
    final prefs = await SharedPreferences.getInstance();

    username.value = prefs.getString('employee_no') ?? '';
    employeeName.value = prefs.getString('employee_calling_name') ?? '';
    organizationId.value = _readInt(prefs, 'organization_id');
    organizationName.value = prefs.getString('organization_name') ?? '';

    // Same supervisor identifier used by TeamPageController.
    final ownSupervisorId = _readInt(prefs, 'own_supervisor_id');
    supervisor.value = ownSupervisorId > 0
        ? ownSupervisorId
        : _readInt(prefs, 'supervisor_id');

    isSupervisor.value = ownSupervisorId > 0;

    departmentId.value = _readInt(prefs, 'department_id');
    if (departmentId.value <= 0) {
      departmentId.value = _readInt(prefs, 'employee_department_id');
    }
    if (departmentId.value <= 0) {
      departmentId.value = _readInt(prefs, 'emp_department_id');
    }

    final cachedImg = prefs.getString('profileImageUrl');
    if (cachedImg != null && cachedImg.isNotEmpty) {
      profileImageUrl.value = cachedImg;
    }

    print('================ DASHBOARD IDENTITY ================');
    print('Employee No     : ${username.value}');
    print('Organization ID : ${organizationId.value}');
    print('Supervisor ID   : ${supervisor.value}');
    print('Department ID   : ${departmentId.value}');
    print('Is Supervisor   : ${isSupervisor.value}');
    print('====================================================');
  }

  int _readInt(SharedPreferences prefs, String key) {
    final value = prefs.get(key);
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  Future<void> fetchProfileImage() async {
    if (username.value.isEmpty) return;

    try {
      isProfileImageLoading.value = true;
      final img = await _authService.profile.fetchProfileImage(username.value);
      if (img != null && img.isNotEmpty) {
        profileImageUrl.value = img;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageUrl', img);
      }
    } catch (e) {
      print('Profile image error: $e');
    } finally {
      isProfileImageLoading.value = false;
    }
  }

  Future<void> fetchTodayAttendance() async {
    if (isOnLeaveToday.value) return;
    await fetchAttendanceForDate(DateTime.now());
  }

  Future<void> fetchAttendanceForDate(DateTime date) async {
    if (username.value.isEmpty) {
      attendanceError.value = 'Attendance not available';
      return;
    }

    isLoadingAttendance.value = true;
    attendanceError.value = '';
    checkINTime.value = '--:--';
    checkOutTime.value = '--:--';
    checkINType.value = 'Not Yet';
    checkOutType.value = 'Not Yet';

    try {
      final records = await _authService.attendance.fetchAttendanceData(
        username.value,
        date,
      );

      if (records.isEmpty) throw Exception('No attendance found');

      final r = records.first;
      final respDate = r['date'];
      final cin = r['checkIN_time'];
      final cout = r['checkOUT_time'];

      if (_hasValidTime(cin)) {
        checkINTime.value = _formatApiTime(respDate, cin);
        checkINType.value = (r['checkIN_type'] ?? 'Normal').toString();
      }

      if (_hasValidTime(cout)) {
        checkOutTime.value = _formatApiTime(respDate, cout);
        checkOutType.value = (r['checkOUT_type'] ?? 'Normal').toString();
      }
    } catch (e) {
      attendanceError.value = 'Attendance not available';
      print('Attendance error: $e');
    } finally {
      isLoadingAttendance.value = false;
    }
  }

  String _formatApiTime(dynamic date, dynamic time) {
    try {
      final dateText = date?.toString().trim() ?? '';
      final timeText = time?.toString().trim() ?? '';
      if (dateText.isEmpty || timeText.isEmpty) return '--:--';
      final parsed = DateTime.parse('$dateText $timeText');
      return DateFormat('hh:mm a').format(parsed);
    } catch (_) {
      return time?.toString().trim() ?? '--:--';
    }
  }

  Future<List<Map<String, dynamic>>> _loadApprovedLeaves(DateTime date) async {
    try {
      return await _authService.leave.fetchTodayApprovedLeaves(date: date);
    } catch (e) {
      print('Approved leave load failed: $e');
      return [];
    }
  }

  // ============================================================
  // MY TEAM: directly supervised employees
  // ============================================================
  Future<void> loadTeamPresence() async {
    if (organizationId.value <= 0 || supervisor.value <= 0) {
      await getIdentityFromCache();
    }

    if (organizationId.value <= 0 || supervisor.value <= 0) {
      teamPresence.clear();
      teamPresenceError.value = 'Supervisor team information is not available';
      return;
    }

    try {
      isLoadingTeamPresence.value = true;
      teamPresenceError.value = '';

      final today = DateTime.now();
      final attendanceRecords =
          await _authService.attendance.fetchAllAttendanceToday(
        today,
        organizationId.value,
        supervisor.value,
      );
      final approvedLeaves = await _loadApprovedLeaves(today);

      teamPresence.assignAll(
        _mergePresenceData(attendanceRecords, approvedLeaves),
      );

      print('MY TEAM => total=$teamTotalCount present=$teamPresentCount absent=$teamAbsentCount leave=$teamLeaveCount late=$teamLateCount');
    } catch (e) {
      teamPresence.clear();
      teamPresenceError.value = 'Unable to load my team attendance';
      print('Team Presence error: $e');
    } finally {
      isLoadingTeamPresence.value = false;
    }
  }

  // ============================================================
  // MY DEPARTMENT: all employees in logged-in employee department
  // ============================================================
  Future<void> loadDepartmentPresence() async {
    if (organizationId.value <= 0 || departmentId.value <= 0) {
      await getIdentityFromCache();
    }

    if (organizationId.value <= 0 || departmentId.value <= 0) {
      departmentPresence.clear();
      departmentPresenceError.value = 'Department information is not available';
      return;
    }

    try {
      isLoadingDepartmentPresence.value = true;
      departmentPresenceError.value = '';

      final today = DateTime.now();

      // This method needs to exist in AttendanceApi.
      // Using dynamic keeps this DashboardController compiling before that
      // method is added to the typed API class.
      final dynamic attendanceApi = _authService.attendance;
      final dynamic response = await attendanceApi.fetchDepartmentAttendanceToday(
        today,
        organizationId.value,
        departmentId.value,
      );

      final attendanceRecords = _toMapList(response);
      final approvedLeaves = await _loadApprovedLeaves(today);

      departmentPresence.assignAll(
        _mergePresenceData(attendanceRecords, approvedLeaves),
      );

      print('DEPARTMENT => total=$departmentTotalCount present=$departmentPresentCount absent=$departmentAbsentCount leave=$departmentLeaveCount late=$departmentLateCount');
    } catch (e) {
      departmentPresence.clear();
      departmentPresenceError.value =
          'Department attendance API is not available';
      print('Department Presence error: $e');
    } finally {
      isLoadingDepartmentPresence.value = false;
    }
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (value is Map && value['data'] is List) {
      return (value['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _mergePresenceData(
    List<Map<String, dynamic>> attendanceRecords,
    List<Map<String, dynamic>> approvedLeaves,
  ) {
    final Map<String, Map<String, dynamic>> leaveMap = {};

    for (final rawLeave in approvedLeaves) {
      final leave = Map<String, dynamic>.from(rawLeave);
      final employeeNo = _normalizeEmployeeNo(leave['employee_no']);
      if (employeeNo.isEmpty) continue;

      final approval = (leave['approved_status_1'] ?? '')
          .toString()
          .trim()
          .toUpperCase();

      if (approval.isNotEmpty && approval != 'APPROVED') continue;
      leaveMap[employeeNo] = leave;
    }

    final result = <Map<String, dynamic>>[];

    for (final raw in attendanceRecords) {
      final attendance = Map<String, dynamic>.from(raw);
      final employeeNo = _normalizeEmployeeNo(attendance['employee_no']);
      if (employeeNo.isEmpty) continue;

      final leave = leaveMap[employeeNo];
      final hasCheckIn = _hasValidTime(attendance['checkIN_time']);
      final hasCheckOut = _hasValidTime(attendance['checkOUT_time']);
      final checkInType = (attendance['checkIN_type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      String status;
      if (leave != null) {
        status = 'Leave';
      } else if (hasCheckIn || hasCheckOut) {
        status = 'Present';
      } else {
        status = 'Absent';
      }

      final isLate = status == 'Present' &&
          hasCheckIn &&
          checkInType.contains('late');

      result.add({
        ...attendance,
        'employee_no': employeeNo,
        'status': status,
        'is_present': status == 'Present',
        'is_absent': status == 'Absent',
        'is_on_leave': status == 'Leave',
        'is_late': isLate,
        'leave_id': leave?['id'],
        'leave_type': _firstNonEmpty([
          leave?['leave_type'],
          leave?['leave_category'],
          leave?['leave_category_name'],
          leave?['leave_name'],
        ]),
        'leave_category_id': leave?['leave_category_id'],
        'leave_weight': leave?['weight'],
        'leave_reason': _firstNonEmpty([
          leave?['reason'],
          leave?['leave_reason'],
          leave?['remarks'],
        ]),
        'approved_status_1': leave?['approved_status_1'],
        'leave_requested_date': leave?['requested_date'],
      });
    }

    return result;
  }

  String _normalizeEmployeeNo(dynamic value) {
    if (value == null) return '';
    return value.toString().trim().toUpperCase();
  }

  bool _hasValidTime(dynamic value) {
    if (value == null) return false;
    final time = value.toString().trim().toLowerCase();
    return time.isNotEmpty &&
        time != '--' &&
        time != '--:--' &&
        time != 'null' &&
        time != '00:00' &&
        time != '00:00:00';
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null' && text != '--') {
        return text;
      }
    }
    return null;
  }

  // -------------------- My Team getters --------------------
  int get teamTotalCount => teamPresence.length;
  int get teamPresentCount =>
      teamPresence.where((e) => e['status'] == 'Present').length;
  int get teamAbsentCount =>
      teamPresence.where((e) => e['status'] == 'Absent').length;
  int get teamLeaveCount =>
      teamPresence.where((e) => e['status'] == 'Leave').length;
  int get teamLateCount =>
      teamPresence.where((e) => e['is_late'] == true).length;
  List<Map<String, dynamic>> get presentTeamMembers =>
      teamPresence.where((e) => e['status'] == 'Present').toList();

  // -------------------- Department getters --------------------
  int get departmentTotalCount => departmentPresence.length;
  int get departmentPresentCount =>
      departmentPresence.where((e) => e['status'] == 'Present').length;
  int get departmentAbsentCount =>
      departmentPresence.where((e) => e['status'] == 'Absent').length;
  int get departmentLeaveCount =>
      departmentPresence.where((e) => e['status'] == 'Leave').length;
  int get departmentLateCount =>
      departmentPresence.where((e) => e['is_late'] == true).length;
  List<Map<String, dynamic>> get presentDepartmentMembers =>
      departmentPresence.where((e) => e['status'] == 'Present').toList();

  Future<void> fetchUpcomingBirthdays() async {
    if (organizationId.value <= 0) {
      upcomingBirthdays.clear();
      return;
    }

    try {
      birthdaysError.value = '';
      final res = await _authService.employee.fetchUpcomingBirthdays(
        organizationId.value.toString(),
      );
      upcomingBirthdays.assignAll(res);
    } catch (e) {
      birthdaysError.value = 'Unable to load birthdays';
      print('Birthday load error: $e');
    }
  }

  Future<void> loadDashboardData() async {
    await getIdentityFromCache();

    final tasks = <Future<void>>[
      _runSafeLoad(fetchProfileImage),
      _runSafeLoad(fetchTodayAttendance),
      _runSafeLoad(fetchUpcomingBirthdays),
      if (isSupervisor.value) _runSafeLoad(loadTeamPresence),
      if (departmentId.value > 0) _runSafeLoad(loadDepartmentPresence),
    ];

    await Future.wait(tasks);
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  Future<void> _runSafeLoad(Future<void> Function() loader) async {
    try {
      await loader().timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Dashboard loader error: $e');
    }
  }

  Future<void> confirmLogout() async {
    Get.defaultDialog(
      title: 'Confirm Logout',
      middleText: 'Are you sure?',
      onConfirm: () async {
        Get.deleteAll(force: true);
        Get.offAll(() => LoginScreen());
      },
    );
  }

  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

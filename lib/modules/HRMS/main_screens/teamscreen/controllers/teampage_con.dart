import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:corehris/auth/authservices.dart';

/// ------------------------------------------------------------
/// ATTENDANCE STATUS
/// ------------------------------------------------------------
enum AttendanceStatus {
  absent,
  checkedIn,
  checkedOut,
  checkoutOnly,
}

/// ------------------------------------------------------------
/// TAB
/// ------------------------------------------------------------
enum TeamPresenceTab {
  present,
  absent,
  onLeave,
}

/// ------------------------------------------------------------
/// TEAM MEMBER MODEL
/// ------------------------------------------------------------
class TeamMember {
  final String employeeNo;
  final String employeeName;

  final DateTime? checkIn;
  final DateTime? checkOut;

  /// Leave information
  final bool isOnLeave;
  final int? leaveId;
  final String? leaveType;
  final String? leaveStatus;
  final String? leaveReason;
  final double? leaveWeight;

  TeamMember({
    required this.employeeNo,
    required String employeeName,
    this.checkIn,
    this.checkOut,
    this.isOnLeave = false,
    this.leaveId,
    this.leaveType,
    this.leaveStatus,
    this.leaveReason,
    this.leaveWeight,
  }) : employeeName = employeeName.trim();

  TeamMember copyWith({
    String? employeeNo,
    String? employeeName,
    DateTime? checkIn,
    DateTime? checkOut,
    bool? isOnLeave,
    int? leaveId,
    String? leaveType,
    String? leaveStatus,
    String? leaveReason,
    double? leaveWeight,
  }) {
    return TeamMember(
      employeeNo: employeeNo ?? this.employeeNo,
      employeeName: employeeName ?? this.employeeName,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      isOnLeave: isOnLeave ?? this.isOnLeave,
      leaveId: leaveId ?? this.leaveId,
      leaveType: leaveType ?? this.leaveType,
      leaveStatus: leaveStatus ?? this.leaveStatus,
      leaveReason: leaveReason ?? this.leaveReason,
      leaveWeight: leaveWeight ?? this.leaveWeight,
    );
  }
}

/// ------------------------------------------------------------
/// CONTROLLER
/// ------------------------------------------------------------
class TeamPageController extends GetxController {
  late final AuthService _authService;

  /// ----------------------------------------------------------
  /// DATA
  /// ----------------------------------------------------------

  final RxList<TeamMember> members = <TeamMember>[].obs;

  /// ----------------------------------------------------------
  /// UI STATE
  /// ----------------------------------------------------------

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// ----------------------------------------------------------
  /// SEARCH
  /// ----------------------------------------------------------

  final RxString searchQuery = ''.obs;

  /// ----------------------------------------------------------
  /// SELECTED TAB
  /// ----------------------------------------------------------

  final Rx<TeamPresenceTab> selectedTab = TeamPresenceTab.present.obs;

  /// ----------------------------------------------------------
  /// IDENTITY
  /// ----------------------------------------------------------

  final RxInt organizationId = 0.obs;
  final RxInt supervisorId = 0.obs;

  /// ----------------------------------------------------------
  /// SELECTED DATE
  /// ----------------------------------------------------------

  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void onInit() {
    super.onInit();

    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(
        AuthService(),
        permanent: true,
      );
    }

    _authService = Get.find<AuthService>();

    _initialize();
  }

  Future<void> _initialize() async {
    await _loadIdentityFromCache();

    await loadTeamPresence(
      selectedDate.value,
    );
  }

  // ==========================================================
  // SHARED PREFS
  // ==========================================================

  Future<void> _loadIdentityFromCache() async {
    final prefs = await SharedPreferences.getInstance();

    organizationId.value = _readInt(prefs, 'organization_id');

    supervisorId.value = _readInt(prefs, 'own_supervisor_id');

    debugPrint(
      '🆔 Loaded -> '
      'OrgID: ${organizationId.value}, '
      'SupervisorID: ${supervisorId.value}',
    );
  }

  int _readInt(
    SharedPreferences prefs,
    String key,
  ) {
    final value = prefs.get(key);

    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  // ==========================================================
  // LOAD TEAM PRESENCE
  // ==========================================================

  Future<void> loadTeamPresence(
    DateTime date,
  ) async {
    if (organizationId.value == 0 || supervisorId.value == 0) {
      errorMessage.value = 'Invalid organization or supervisor';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      selectedDate.value = date;

      /// ------------------------------------------------------
      /// 1. LOAD SUPERVISOR TEAM ATTENDANCE
      /// ------------------------------------------------------

      final attendanceRecords =
          await _authService.attendance.fetchAllAttendanceToday(
        date,
        organizationId.value,
        supervisorId.value,
      );

      debugPrint(
        '👥 Attendance records: ${attendanceRecords.length}',
      );

      /// ------------------------------------------------------
      /// 2. LOAD TODAY APPROVED LEAVES
      /// ------------------------------------------------------

      final approvedLeaves = await _authService.leave.fetchTodayApprovedLeaves(
        date: date,
      );

      debugPrint(
        '🏖 Approved leaves: ${approvedLeaves.length}',
      );

      /// ------------------------------------------------------
      /// 3. CREATE APPROVED LEAVE MAP
      ///
      /// employee_no -> leave
      /// ------------------------------------------------------

      final Map<String, Map<String, dynamic>> approvedLeaveMap = {};

      for (final leave in approvedLeaves) {
        final employeeNo = _normalizeEmployeeNo(
          leave['employee_no'],
        );

        if (employeeNo.isEmpty) {
          continue;
        }

        approvedLeaveMap[employeeNo] = leave;
      }

      /// ------------------------------------------------------
      /// 4. CREATE TEAM MEMBERS
      /// ------------------------------------------------------

      final List<TeamMember> parsedMembers = [];

      for (final record in attendanceRecords) {
        final employeeNo = _normalizeEmployeeNo(
          record['employee_no'],
        );

        final employeeName =
            (record['employee_fullname'] ?? '').toString().trim();

        /// Approved leave belonging to this team member
        final leave = approvedLeaveMap[employeeNo];

        parsedMembers.add(
          TeamMember(
            employeeNo: employeeNo,
            employeeName: employeeName,
            checkIn: _safeParseTime(
              date,
              record['checkIN_time'],
            ),
            checkOut: _safeParseTime(
              date,
              record['checkOUT_time'],
            ),

            /// Leave
            isOnLeave: leave != null,

            leaveId: _safeInt(
              leave?['id'],
            ),

            leaveType: _firstNonEmpty([
              leave?['leave_type'],
              leave?['leave_category'],
              leave?['leave_category_name'],
              leave?['leave_name'],
            ]),

            leaveStatus: leave?['approved_status_1']?.toString(),

            leaveReason: _firstNonEmpty([
              leave?['reason'],
              leave?['remarks'],
              leave?['leave_reason'],
            ]),

            leaveWeight: _safeDouble(
              leave?['weight'],
            ),
          ),
        );
      }

      members.assignAll(parsedMembers);

      debugPrint(
        '✅ Total team members: ${members.length}',
      );

      debugPrint(
        '✅ Present: ${presentMembers.length}',
      );

      debugPrint(
        '❌ Absent: ${absentMembers.length}',
      );

      debugPrint(
        '🏖 Leave: ${leaveMembers.length}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Team presence load failed: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      errorMessage.value = 'Failed to load team presence';
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================================================
  // EMPLOYEE NUMBER NORMALIZATION
  // ==========================================================

  String _normalizeEmployeeNo(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim().toUpperCase();
  }

  // ==========================================================
  // SAFE PARSERS
  // ==========================================================

  int? _safeInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  double? _safeDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  String? _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final value in values) {
      if (value == null) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return null;
  }

  // ==========================================================
  // TIME
  // ==========================================================

  DateTime? _safeParseTime(
    DateTime date,
    dynamic time,
  ) {
    if (time == null) {
      return null;
    }

    final raw = time.toString().trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }

    try {
      /// Handles:
      ///
      /// 08:30
      /// 08:30:00

      final parts = raw.split(':');

      if (parts.length < 2) {
        return null;
      }

      final hour = int.tryParse(parts[0]);

      final minute = int.tryParse(parts[1]);

      final second = parts.length > 2
          ? int.tryParse(
                parts[2].split('.').first,
              ) ??
              0
          : 0;

      if (hour == null || minute == null) {
        return null;
      }

      return DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
        second,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  void updateSearch(
    String value,
  ) {
    searchQuery.value = value;
  }

  bool _matchesSearch(
    TeamMember member,
  ) {
    final query = searchQuery.value.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    return member.employeeName.toLowerCase().contains(query) ||
        member.employeeNo.toLowerCase().contains(query);
  }

  // ==========================================================
  // TAB
  // ==========================================================

  void changeTab(
    TeamPresenceTab tab,
  ) {
    selectedTab.value = tab;
  }

  // ==========================================================
  // PRESENT
  // ==========================================================

  List<TeamMember> get presentMembers {
    return members.where((member) {
      /// Employee on approved leave should not
      /// appear under Present.
      if (member.isOnLeave) {
        return false;
      }

      final hasAttendance = member.checkIn != null || member.checkOut != null;

      return hasAttendance && _matchesSearch(member);
    }).toList();
  }

  // ==========================================================
  // ABSENT
  // ==========================================================

  List<TeamMember> get absentMembers {
    return members.where((member) {
      /// Important:
      ///
      /// Approved leave is NOT treated as absent.
      if (member.isOnLeave) {
        return false;
      }

      final noAttendance = member.checkIn == null && member.checkOut == null;

      return noAttendance && _matchesSearch(member);
    }).toList();
  }

  // ==========================================================
  // LEAVE
  // ==========================================================

  List<TeamMember> get leaveMembers {
    return members.where((member) {
      return member.isOnLeave && _matchesSearch(member);
    }).toList();
  }

  // ==========================================================
  // CURRENT LIST
  // ==========================================================

  List<TeamMember> get currentMembers {
    switch (selectedTab.value) {
      case TeamPresenceTab.present:
        return presentMembers;

      case TeamPresenceTab.absent:
        return absentMembers;

      case TeamPresenceTab.onLeave:
        return leaveMembers;
    }
  }

  // ==========================================================
  // COUNTERS
  // ==========================================================

  int get presentCount {
    return members.where((member) {
      return !member.isOnLeave &&
          (member.checkIn != null || member.checkOut != null);
    }).length;
  }

  int get absentCount {
    return members.where((member) {
      return !member.isOnLeave &&
          member.checkIn == null &&
          member.checkOut == null;
    }).length;
  }

  int get leaveCount {
    return members.where((member) {
      return member.isOnLeave;
    }).length;
  }

  // ==========================================================
  // ATTENDANCE STATUS
  // ==========================================================

  AttendanceStatus getStatus(
    TeamMember member,
  ) {
    final hasIn = member.checkIn != null;

    final hasOut = member.checkOut != null;

    if (hasIn && hasOut) {
      return AttendanceStatus.checkedOut;
    }

    if (hasIn && !hasOut) {
      return AttendanceStatus.checkedIn;
    }

    if (!hasIn && hasOut) {
      return AttendanceStatus.checkoutOnly;
    }

    return AttendanceStatus.absent;
  }

  // ==========================================================
  // UI HELPERS
  // ==========================================================

  String formatTime(
    DateTime? time,
  ) {
    if (time == null) {
      return '--';
    }

    return DateFormat(
      'hh:mm a',
    ).format(time);
  }

  String statusText(
    AttendanceStatus status,
  ) {
    switch (status) {
      case AttendanceStatus.checkedIn:
        return 'Checked In';

      case AttendanceStatus.checkedOut:
        return 'Checked Out';

      case AttendanceStatus.checkoutOnly:
        return 'Checkout Only';

      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  Color statusColor(
    AttendanceStatus status,
  ) {
    switch (status) {
      case AttendanceStatus.checkedIn:
        return Colors.orange;

      case AttendanceStatus.checkedOut:
        return Colors.green;

      case AttendanceStatus.checkoutOnly:
        return Colors.blue;

      case AttendanceStatus.absent:
        return Colors.red;
    }
  }

  String get emptyMessage {
    switch (selectedTab.value) {
      case TeamPresenceTab.present:
        return 'No present employees';

      case TeamPresenceTab.absent:
        return 'No absent employees';

      case TeamPresenceTab.onLeave:
        return 'No employees on approved leave';
    }
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> refresh() async {
    await loadTeamPresence(
      selectedDate.value,
    );
  }
}

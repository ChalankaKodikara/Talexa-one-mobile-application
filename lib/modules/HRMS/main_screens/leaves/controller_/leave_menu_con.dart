// ignore_for_file: avoid_print

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/components/leavedata.dart' as model;
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class LeaveMenuController extends GetxController {
  final AuthService _auth = AuthService();

  /// ============================================================
  /// EMPLOYEE
  /// ============================================================

  final RxString employeeId = ''.obs;

  /// ============================================================
  /// LEAVE BALANCES
  /// ============================================================

  final RxList<model.Leave> leaveList = <model.Leave>[].obs;

  /// ============================================================
  /// LEAVE REQUESTS
  /// ============================================================

  /// All leave requests returned from API.
  final RxList<Map<String, dynamic>> allLeaveRequests =
      <Map<String, dynamic>>[].obs;

  /// Only APPROVED leave requests.
  ///
  /// Used by Leave Recall screen.
  final RxList<Map<String, dynamic>> approvedLeaveRequests =
      <Map<String, dynamic>>[].obs;

  /// Latest 5 requests displayed on Leave Menu.
  final RxList<Map<String, dynamic>> leaveRequests =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoadingRequests = false.obs;

  /// ============================================================
  /// INIT
  /// ============================================================

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    await _loadEmployee();

    if (employeeId.value.isNotEmpty) {
      await refreshAll();
    } else {
      AppAlert.toast(
        title: "Error",
        message: "Employee not found. Please login again.",
      );
    }
  }

  Future<void> _loadEmployee() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      employeeId.value = prefs.getString("employee_no")?.trim() ?? "";
    } catch (e) {
      print("❌ Failed to load employee number: $e");

      employeeId.value = "";
    }
  }

  /// ============================================================
  /// REFRESH ALL
  /// ============================================================

  Future<void> refreshAll() async {
    if (employeeId.value.isEmpty) {
      return;
    }

    await Future.wait([
      fetchLeaveBalances(),
      fetchLatestLeaveRequests(),
    ]);
  }

  /// ============================================================
  /// FETCH LEAVE BALANCES
  /// ============================================================

  Future<void> fetchLeaveBalances() async {
    if (employeeId.value.isEmpty) return;

    try {
      final model.LeaveResponse response = await _auth.leave.countLeaveData(
        employeeId.value,
      );

      leaveList.assignAll(response.leaves);
    } catch (e) {
      print("❌ Leave balance error: $e");

      AppAlert.toast(
        title: "Error",
        message: "Failed to fetch leave balances",
      );
    }
  }

  /// ============================================================
  /// FETCH LEAVE REQUESTS
  /// ============================================================

  Future<void> fetchLatestLeaveRequests() async {
    if (employeeId.value.isEmpty) return;

    try {
      isLoadingRequests.value = true;

      final List<Map<String, dynamic>> data = await _auth.leave.fetchLeaveData(
        employeeId.value,
      );

      /// --------------------------------------------------------
      /// SORT NEWEST FIRST
      /// --------------------------------------------------------

      data.sort((a, b) {
        final da = getRequestDate(a) ?? DateTime(1900);
        final db = getRequestDate(b) ?? DateTime(1900);

        return db.compareTo(da);
      });

      /// --------------------------------------------------------
      /// SAVE ALL
      /// --------------------------------------------------------

      allLeaveRequests.assignAll(data);

      /// --------------------------------------------------------
      /// APPROVED ONLY
      /// --------------------------------------------------------

      approvedLeaveRequests.assignAll(
        data.where(isApprovedLeave).toList(),
      );

      /// --------------------------------------------------------
      /// LATEST 5 FOR HOME / LEAVE MENU
      /// --------------------------------------------------------

      leaveRequests.assignAll(
        data.take(5).toList(),
      );

      print(
        "✅ Total leave requests: "
        "${allLeaveRequests.length}",
      );

      print(
        "✅ Approved leave requests: "
        "${approvedLeaveRequests.length}",
      );
    } catch (e) {
      print("❌ Leave requests error: $e");

      AppAlert.toast(
        title: "Error",
        message: "Failed to load leave requests",
      );
    } finally {
      isLoadingRequests.value = false;
    }
  }

  /// ============================================================
  /// APPROVED CHECK
  /// ============================================================

  bool isApprovedLeave(Map<String, dynamic> leave) {
    /// Your API uses approved_status_1.
    ///
    /// Fallback fields are retained for compatibility.
    final status = (leave["approved_status_1"] ??
            leave["status"] ??
            leave["leave_status"] ??
            "")
        .toString()
        .trim()
        .toUpperCase();

    return status == "APPROVED";
  }

  /// ============================================================
  /// REQUEST DATE
  /// ============================================================

  DateTime? getRequestDate(
    Map<String, dynamic> leave,
  ) {
    final value = leave["requested_date"] ??
        leave["leave_date"] ??
        leave["start_date"] ??
        leave["from_date"];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  /// ============================================================
  /// HELPERS
  /// ============================================================

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case "APPROVED":
        return Colors.green;

      case "REJECTED":
        return Colors.red;

      case "PENDING":
      case "NOT APPROVED":
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  IconData leaveIcon(String type) {
    switch (type.toLowerCase()) {
      case "annual leave":
        return Icons.beach_access;

      case "sick leave":
        return Icons.sick;

      default:
        return Icons.event_note;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      return "-";
    }

    final parsed = DateTime.tryParse(date);

    return parsed == null ? "-" : DateFormat("yyyy-MM-dd").format(parsed);
  }

  String halfDayText(dynamic value) =>
      (value == 1 || value == "1") ? "Half Day" : "Full Day";

  Color halfDayColor(dynamic value) =>
      (value == 1 || value == "1") ? Colors.orange : AppColors.primary2;
}

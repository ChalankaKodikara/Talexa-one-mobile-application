// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/utils/api_error_handler.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:corehris/utils/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveReportController extends GetxController {
  final AuthService authService = AuthService();

  RxList<Map<String, dynamic>> leaveData = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredLeaveData = <Map<String, dynamic>>[].obs;

  Rx<DateTime?> startDate = Rx<DateTime?>(null);
  Rx<DateTime?> endDate = Rx<DateTime?>(null);

  RxBool isLoading = false.obs;

  String? username;

  @override
  void onInit() {
    super.onInit();
    loadUsername();
  }

  /// Load username from SharedPreferences
  Future<void> loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      username = prefs.getString("employee_no");

      if (username != null) {
        fetchLeaveData();
      } else {
        AppSnackbar.error("Username not found");
      }
    } catch (e) {
      AppSnackbar.error("Failed to load user session");
    }
  }

  /// Fetch leave data
  Future<void> fetchLeaveData() async {
    if (username == null) return;

    isLoading.value = true;

    try {
      final List<Map<String, dynamic>> data =
          await authService.leave.fetchLeaveData(username!);

      leaveData.value = data;
      applyDateFilter();
    } catch (e) {
      AppSnackbar.error(ApiErrorHandler.getMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete leave request
  Future<void> deleteLeave(int leaveId) async {
    try {
      isLoading.value = true;

      await authService.leave.deleteLeaveRequest(leaveId);

      leaveData.removeWhere((e) => e["id"] == leaveId);

      applyDateFilter();

      AppSnackbar.success("Deleted", "Leave request removed");
    } catch (e) {
      AppSnackbar.error(ApiErrorHandler.getMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Confirm delete dialog
  Future<void> confirmDelete(BuildContext context, int leaveId) async {
    final confirmed = await AppAlert.confirm(
      context: context,
      title: "Confirm Delete",
      message: "Are you sure you want to delete this request?",
      confirmText: "Delete",
      isDestructive: true,
    );

    if (confirmed == true) {
      await deleteLeave(leaveId);
    }
  }

  /// Apply date filter
  void applyDateFilter() {
    List<Map<String, dynamic>> result = List.from(leaveData);

    if (startDate.value != null && endDate.value != null) {
      result = result.where((item) {
        final d = DateTime.tryParse(item['requested_date'] ?? "");
        if (d == null) return false;

        return (d.isAfter(startDate.value!) ||
                d.isAtSameMomentAs(startDate.value!)) &&
            (d.isBefore(endDate.value!) || d.isAtSameMomentAs(endDate.value!));
      }).toList();
    } else {
      final now = DateTime.now();
      final first = DateTime(now.year, now.month, 1);
      final last = DateTime(now.year, now.month + 1, 0);

      result = result.where((item) {
        final d = DateTime.tryParse(item['requested_date'] ?? "");
        if (d == null) return false;

        return d.isAfter(first.subtract(const Duration(days: 1))) &&
            d.isBefore(last.add(const Duration(days: 1)));
      }).toList();
    }

    filteredLeaveData.value = result;
  }

  /// Pick start or end date
  Future<void> pickDate(BuildContext ctx, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      if (isStart) {
        startDate.value = pickedDate;
      } else {
        endDate.value = pickedDate;
      }

      applyDateFilter();
    }
  }
}

// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'dart:convert';
import 'dart:async';
import 'package:corehris/auth/authservices.dart';
import 'package:corehris/components/leavedata.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:corehris/utils/app_alert.dart';

class LeaveRequestController extends GetxController {
  final AuthService authService = AuthService();

  // ================== STATE ==================
  var requestedDates = <Map<String, dynamic>>[].obs;
  var leaveCategories = <Leave>[].obs;

  var reason = ''.obs;
  var username = ''.obs;
  var organizationId = 0.obs;

  // 🔍 Backend Search
  var searchQuery = ''.obs;
  var searchResults = <Map<String, dynamic>>[].obs;
  var isSearchingEmployees = false.obs;

  // Covering employees (max 2)
  var selectedCoveringEmployees = <Map<String, dynamic>>[].obs;

  var attachedFiles = <String>[].obs;
  var isSubmitting = false.obs;

  Timer? _debounce;

  // ================== INIT ==================
  @override
  void onInit() {
    super.onInit();
    getEmployeeCodeFromCache();
    fetchLeaveCategories();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> getEmployeeCodeFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    username.value = prefs.getString('employee_no') ?? '';
  }

  Future<void> fetchLeaveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employee_no') ?? '';
      organizationId.value = prefs.getInt('organization_id') ?? 0;
      final LeaveResponse response =
          await authService.leave.countLeaveData(employeeId);
      leaveCategories.value = response.leaves;
    } catch (_) {
      AppAlert.toast(
        title: "Error",
        message: "Failed to load leave categories",
      );
    }
  }

  // ================== SEARCH ==================
  void onSearchChanged(String query) {
    searchQuery.value = query;
    _debounce?.cancel();

    if (query.trim().length < 2) {
      searchResults.clear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchEmployeesFromApi(query, organizationId.value);
    });
  }

  Future<void> searchEmployeesFromApi(String query, int organizationId) async {
    try {
      isSearchingEmployees.value = true;

      final results = await authService.employee.searchEmployees(
        search: query,
        organizationId: organizationId,
      );

      searchResults.assignAll(results);
    } catch (e) {
      searchResults.clear();
    } finally {
      isSearchingEmployees.value = false;
    }
  }

  // ================== ADD / REMOVE COVERING EMPLOYEES ==================
  void addCoveringEmployee(Map<String, dynamic> emp) {
    if (selectedCoveringEmployees.length >= 2) {
      AppAlert.toast(
        title: "Limit Reached",
        message: "Maximum 2 covering employees allowed",
      );
      return;
    }

    final empNo = emp['employee_no'];
    if (empNo == null) return;

    if (selectedCoveringEmployees.any((e) => e['employee_no'] == empNo)) {
      AppAlert.toast(
        title: "Duplicate",
        message: "Employee already added",
      );
      return;
    }

    selectedCoveringEmployees.add({
      "employee_no": empNo,
      "employee_fullname": emp['employee_fullname'] ?? '',
      "designation_name": emp['designation_name'] ?? '',
      "start_time": "",
      "end_time": "",
    });

    searchQuery.value = "";
    searchResults.clear();
  }

  void removeCoveringEmployee(String empNo) {
    selectedCoveringEmployees.removeWhere((e) => e['employee_no'] == empNo);
  }

  void setTime(String empNo, {required bool isStart, required String time}) {
    final index =
        selectedCoveringEmployees.indexWhere((e) => e['employee_no'] == empNo);
    if (index != -1) {
      selectedCoveringEmployees[index][isStart ? "start_time" : "end_time"] =
          time;
      selectedCoveringEmployees.refresh();
    }
  }

  // ================== INIT DATES ==================
  void initializeRequestedDates(List selectedDateMaps) {
    requestedDates.clear();

    for (var item in selectedDateMaps) {
      DateTime? date;

      if (item is DateTime) {
        date = item;
      } else if (item is String) {
        date = DateTime.tryParse(item);
      } else if (item is Map && item["date"] != null) {
        date = item["date"] is DateTime
            ? item["date"]
            : DateTime.tryParse(item["date"].toString());
      }

      if (date != null) {
        requestedDates.add({
          "request_day": DateFormat('yyyy-MM-dd').format(date),
          "leave_category": item is Map ? item["leave_category"] ?? "" : "",
          "leave_type": item is Map ? item["leave_type"] ?? "" : "",
          "is_half_day": item is Map ? item["is_half_day"] ?? 0 : 0,
          "covering_employees": [],
        });
      }
    }

    requestedDates.refresh();
  }

  // ================== FILE PICKER ==================
  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true);
      if (result != null) {
        attachedFiles.addAll(result.paths.whereType<String>());
      }
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: "File selection failed",
      );
    }
  }

  // ================== VALIDATION ==================
  bool validateBeforeSubmit() {
    if (requestedDates.isEmpty) {
      AppAlert.toast(
        title: "Error",
        message: "No leave dates selected",
      );
      return false;
    }

    if (reason.value.isEmpty) {
      AppAlert.toast(
        title: "Error",
        message: "Reason is required",
      );
      return false;
    }

    if (selectedCoveringEmployees.isEmpty) {
      AppAlert.toast(
        title: "Error",
        message: "Add at least one covering employee",
      );
      return false;
    }

    return true;
  }

  // ================== SUBMIT ==================
  Future<void> submitLeaveRequest(String employeeNo) async {
    if (!validateBeforeSubmit() || isSubmitting.value) return;
    isSubmitting.value = true;

    final cleanedDates = requestedDates.map((d) {
      return {
        "request_day": d["request_day"],
        "leave_category": d["leave_category"],
        "is_half_day": d["is_half_day"],
        "covering_employees": selectedCoveringEmployees.map((e) {
          return {
            "employee_no": e["employee_no"],
            "start_time": e["start_time"],
            "end_time": e["end_time"],
          };
        }).toList(),
      };
    }).toList();

    final formData = FormData.fromMap({
      "employee_no": employeeNo,
      "reason": reason.value,
      "requested_dates": jsonEncode(cleanedDates),
      if (attachedFiles.isNotEmpty)
        "file":
            attachedFiles.map((p) => MultipartFile.fromFileSync(p)).toList(),
    });

    try {
      final response = await authService.leave.leaveRequest(formData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        AppAlert.toast(
          title: "Success",
          message: response.data['message'],
        );

        requestedDates.clear();
        selectedCoveringEmployees.clear();
        attachedFiles.clear();
        reason.value = '';

        Get.offAll(() => DashboardScreen());
      } else {
        AppAlert.toast(
          title: "Error",
          message: response.data['message'] ?? "Request failed",
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? "Network error";
      AppAlert.toast(
        title: "Error",
        message: msg,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}

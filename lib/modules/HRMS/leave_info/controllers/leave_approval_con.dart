// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio; // ✅ alias to avoid name conflict
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class LeaveApprovalController extends GetxController {
  final AuthService _authService = AuthService();

  final int leaveId;
  final bool isSupervisor;

  LeaveApprovalController({
    required this.leaveId,
    required this.isSupervisor,
  });

  // ------------------- Observables -------------------
  RxBool isLoading = false.obs;
  RxMap<String, dynamic> leaveData = <String, dynamic>{}.obs;
  RxString decision = ''.obs;
  RxString reason = ''.obs;

  // ------------------- Init -------------------
  @override
  void onInit() {
    super.onInit();
    fetchLeaveDetails();
  }

  // ------------------- Get username -------------------
  Future<String?> getUsername() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('employee_no');
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: "Failed to retrieve username from cache: $e",
      );
      return null;
    }
  }

  // ------------------- Fetch Leave Details -------------------
  Future<void> fetchLeaveDetails() async {
    isLoading.value = true;
    try {
      final data = await _authService.leave.getLeaveDataById(leaveId);
      if (data != null) {
        leaveData.value = data;
      } else {
        AppAlert.toast(
          title: "Error",
          message: "No data found for leave ID $leaveId",
        );
      }
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: "Failed to load leave details: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ------------------- Supervisor Approval -------------------
  Future<void> supervisorSubmitDecision() async {
    if (decision.value.isEmpty) {
      AppAlert.toast(
        title: "Error",
        message: "Please select approve or reject",
      );
      return;
    }

    if (decision.value == "REJECTED" && reason.value.trim().isEmpty) {
      AppAlert.toast(
        title: "Error",
        message: "Please provide a reason for rejection",
      );
      return;
    }

    isLoading.value = true;
    try {
      final dio.Response? response =
          await _authService.leave.supervisorApproval(
        leaveId: leaveId,
        approvalStatus: decision.value,
        remarks: reason.value.trim(),
        emails: [],
      );

      if (response != null && response.statusCode == 200) {
        final message =
            response.data?['message'] ?? "Decision submitted successfully!";
        AppAlert.toast(
          title: "Success",
          message: message,
        );
        await Future.delayed(const Duration(seconds: 1));
        Get.offAll(() => DashboardScreen());
      } else {
        final msg = response?.data?['message'] ??
            "Failed to submit decision (Code: ${response?.statusCode ?? 'N/A'})";
        AppAlert.toast(
          title: "Error",
          message: msg,
        );
      }
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: "Failed to submit decision: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ------------------- Covering Approval -------------------
  Future<void> coveringSubmitDecision() async {
    if (decision.value.isEmpty) {
      AppAlert.toast(
        title: "Error",
        message: "Please select approve or reject",
      );
      return;
    }

    isLoading.value = true;
    try {
      final username = await getUsername() ?? '';
      final dio.Response? response = await _authService.leave.coveringApproval(
        leaveId: leaveId,
        approvalStatus: decision.value,
        coveringEmployeeNo: username,
      );

      if (response != null && response.statusCode == 200) {
        final message =
            response.data?['message'] ?? "Decision submitted successfully!";
        AppAlert.toast(
          title: "Success",
          message: message,
        );
        await Future.delayed(const Duration(seconds: 1));
        Get.offAll(() => DashboardScreen());
      } else {
        final msg = response?.data?['message'] ??
            "Failed to submit decision (Code: ${response?.statusCode ?? 'N/A'})";
        AppAlert.toast(
          title: "Error",
          message: msg,
        );
      }
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: "Failed to submit decision: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }
}

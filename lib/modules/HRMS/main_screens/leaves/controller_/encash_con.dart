// ignore_for_file: avoid_print

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/components/leavedata.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

/// ===============================
/// 🔹 MODEL: Encashable Leave
/// ===============================
class EncashableLeave {
  final int leaveCategoryId;
  final String categoryName;
  final int availableDays;
  final int maxEncashDays;

  EncashableLeave({
    required this.leaveCategoryId,
    required this.categoryName,
    required this.availableDays,
    required this.maxEncashDays,
  });
}

/// ===============================
/// 🔹 CONTROLLER
/// ===============================
class LeaveEncashController extends GetxController {
  final AuthService _auth = AuthService();

  /// ===============================
  /// 🔹 STATE
  /// ===============================
  final RxString employeeId = ''.obs;
  final RxBool isLoading = false.obs;

  /// 🔹 Encashable leave types
  final RxList<EncashableLeave> encashableLeaves = <EncashableLeave>[].obs;

  /// 🔹 Encash history
  final RxList<Map<String, dynamic>> encashHistory =
      <Map<String, dynamic>>[].obs;

  /// ===============================
  /// 🔹 FORM STATE
  /// ===============================
  final RxInt selectedLeaveCategoryId = 0.obs;
  final RxString selectedLeaveName = ''.obs;
  final RxInt requestedDays = 1.obs;

  final TextEditingController remarksCtrl = TextEditingController();

  /// ===============================
  /// 🔹 INIT
  /// ===============================
  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _loadEmployee();

    if (employeeId.value.isNotEmpty) {
      await fetchEncashableLeaves();
      await fetchEncashHistory();
    }
  }

  Future<void> _loadEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    employeeId.value = prefs.getString("username") ?? "";
  }

  /// ===============================
  /// 🔹 FETCH ENCASHABLE LEAVE TYPES
  /// ===============================
  Future<void> fetchEncashableLeaves() async {
    try {
      isLoading.value = true;

      final LeaveResponse response =
          await _auth.leave.countLeaveData(employeeId.value);

      final List<EncashableLeave> list = [];

      for (final leave in response.leaves) {
        /// 1️⃣ Only encash-enabled types
        if (!leave.encashAllowed) continue;

        /// 2️⃣ max encash must be defined
        final int maxEncash = leave.maxEncashDays ?? 0;
        if (maxEncash <= 0) continue;

        /// 3️⃣ Use ENTITLEMENT (NOT remaining)
        final int entitlement =
            leave.noOfDays > 0 ? leave.noOfDays : leave.leaveCount.floor();

        /// 4️⃣ Final encashable days
        final int encashableDays =
            entitlement > maxEncash ? maxEncash : entitlement;

        if (encashableDays <= 0) continue;

        list.add(
          EncashableLeave(
            leaveCategoryId: leave.leaveCategoryId,
            categoryName: leave.categoryName,
            availableDays: encashableDays,
            maxEncashDays: maxEncash,
          ),
        );
      }

      encashableLeaves.assignAll(list);
    } catch (e) {
      print("Encash fetch error: $e");
      AppAlert.toast(
        title: "Error",
        message: "Failed to load encashable leave categories",
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// 🔹 FETCH ENCASH HISTORY
  /// ===============================
  Future<void> fetchEncashHistory() async {
    try {
      final data = await _auth.leave.getEncashedLeaves(
        employeeNo: employeeId.value,
      );
      encashHistory.assignAll(data);
    } catch (e) {
      print("Encash history error: $e");
      AppAlert.toast(
        title: "Error",
        message: "Failed to load encash history",
      );
    }
  }

  /// ===============================
  /// 🔹 SELECT LEAVE
  /// ===============================
  void selectLeave(EncashableLeave leave) {
    selectedLeaveCategoryId.value = leave.leaveCategoryId;
    selectedLeaveName.value = leave.categoryName;
    requestedDays.value = 1;
  }

  /// ===============================
  /// 🔹 SUBMIT ENCASH REQUEST
  /// ===============================
  Future<void> submitEncashRequest() async {
    final selected = encashableLeaves.firstWhereOrNull(
      (e) => e.leaveCategoryId == selectedLeaveCategoryId.value,
    );

    if (selected == null) {
      AppAlert.toast(
        title: "Validation",
        message: "Please select a leave category",
      );
      return;
    }

    if (requestedDays.value <= 0 ||
        requestedDays.value > selected.availableDays) {
      AppAlert.toast(
        title: "Validation",
        message: "Requested days exceed encashable limit",
      );
      return;
    }

    try {
      isLoading.value = true;

      await _auth.leave.encashLeave(
        employeeNo: employeeId.value,
        leaveCategoryId: selected.leaveCategoryId,
        requestedDays: requestedDays.value,
      );

      Get.back();

      AppAlert.toast(
        title: "Success",
        message: "Leave encash request submitted successfully",
      );

      /// Refresh data
      await fetchEncashableLeaves();
      await fetchEncashHistory();
    } catch (e) {
      print("Encash submit error: $e");
      AppAlert.toast(
        title: "Error",
        message: "Failed to submit encash request",
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// 🔹 STATUS COLOR
  /// ===============================
  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case "APPROVED":
        return Colors.green;
      case "REJECTED":
        return Colors.red;
      case "PENDING":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

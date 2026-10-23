import 'package:corehris/auth/authservices.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class OvertimeController extends GetxController {
  // ------------------ UI STATES ------------------
  final isLoading = false.obs;
  final isDetailsLoading = false.obs;
  final isSubmitting = false.obs;

  // ------------------ DATA ------------------
  final overtimeList = <Map<String, dynamic>>[].obs;
  final overtimeAssignmentDetails = Rxn<Map<String, dynamic>>();
  final pagination = Rxn<Map<String, dynamic>>();

  final employeeNo = ''.obs;

  // ------------------ SERVICE ------------------
  final AuthService _service = AuthService();

  // =================================================
  // INIT
  // =================================================
  @override
  void onInit() {
    super.onInit();
    _loadEmployeeNoAndFetchOT();
  }

  // =================================================
  // LOAD EMPLOYEE NO FROM SHARED PREFS
  // =================================================
  Future<void> _loadEmployeeNoAndFetchOT() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final empNo = prefs.getString('username'); // 🔑 same key you use at login

      if (empNo == null || empNo.isEmpty) {
        AppAlert.toast(
          title: 'Error',
          message: 'Employee number not found',
        );
        return;
      }

      employeeNo.value = empNo;

      // 🔄 auto load OT list
      await loadOvertimeByEmployee(empNo);
    } catch (e) {
      AppAlert.toast(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  // =================================================
  // LOAD OVERTIME LIST BY EMPLOYEE
  // =================================================
  Future<void> loadOvertimeByEmployee(String employeeNo) async {
    try {
      isLoading.value = true;

      final response = await _service.overtime.fetchOvertimeData(employeeNo);

      overtimeList.value =
          List<Map<String, dynamic>>.from(response['data'] ?? []);

      pagination.value =
          Map<String, dynamic>.from(response['pagination'] ?? {});
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =================================================
  // LOAD OVERTIME ASSIGNMENT DETAILS (GET)
  // =================================================
  Future<void> loadOvertimeAssignmentDetails(int overtimeAssignmentId) async {
    try {
      isDetailsLoading.value = true;

      final response = await _service.overtime
          .getOvertimeAssignmentById(overtimeAssignmentId);

      overtimeAssignmentDetails.value =
          Map<String, dynamic>.from(response['data']);
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: e.toString(),
      );
    } finally {
      isDetailsLoading.value = false;
    }
  }

  // =================================================
  // HELPERS
  // =================================================
  bool isOvertimeSubmitted(Map<String, dynamic> ot) {
    return ot['overtime_actual_id'] != null;
  }

  void clearDetails() {
    overtimeAssignmentDetails.value = null;
  }
}

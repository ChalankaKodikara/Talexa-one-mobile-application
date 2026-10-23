// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/auth/authservices.dart';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class LoanStatusController extends GetxController {
  final AuthService authService = AuthService();

  /// ===============================
  /// STATE
  /// ===============================
  final RxString employeeNo = ''.obs;
  final RxInt organizationId = 0.obs;

  final RxList<Map<String, dynamic>> loanRequests =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;

  /// Filters
  final RxString approvalStatus =
      'PENDING'.obs; // PENDING / APPROVED / REJECTED
  final RxInt page = 1.obs;
  final RxInt limit = 10.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserFromCache();
  }

  /// ===============================
  /// LOAD USER DATA
  /// ===============================
  Future<void> _loadUserFromCache() async {
    final prefs = await SharedPreferences.getInstance();

    employeeNo.value = prefs.getString('username') ?? '';
    organizationId.value = prefs.getInt('organization_id') ?? 0;

    if (employeeNo.value.isNotEmpty && organizationId.value != 0) {
      fetchLoanRequests();
    } else {
      _showError('Employee or Organization not found');
    }
  }

  /// ===============================
  /// FETCH LOAN REQUESTS
  /// ===============================
  Future<void> fetchLoanRequests() async {
    if (employeeNo.value.isEmpty) return;

    try {
      isLoading.value = true;

      final response = await authService.loan.getLoanRequests(
        employeeNo: employeeNo.value,
        organizationId: organizationId.value,
        page: page.value,
        limit: limit.value,
      );

      /// Directly store backend response
      loanRequests.assignAll(response);
    } catch (e) {
      _showError('Failed to fetch loan requests');
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// FILTER HANDLERS
  /// ===============================
  void changeStatus(String status) {
    approvalStatus.value = status;
    page.value = 1;
    fetchLoanRequests();
  }

  void loadNextPage() {
    page.value++;
    fetchLoanRequests();
  }

  /// ===============================
  /// UI ERROR
  /// ===============================
  void _showError(String message) {
    AppAlert.toast(
      title: 'Error',
      message: message,
    );
  }
}

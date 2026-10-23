// ignore_for_file: avoid_print

import 'package:corehris/auth/authservices.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class LoanRequestController extends GetxController {
  final AuthService authService = AuthService();

  /// ===============================
  /// 🔹 FORM CONTROLLERS
  /// ===============================
  final TextEditingController purposeController = TextEditingController();

  final TextEditingController guarantor1NameCtrl = TextEditingController();
  final TextEditingController guarantor1ContactCtrl = TextEditingController();
  final TextEditingController guarantor2NameCtrl = TextEditingController();
  final TextEditingController guarantor2ContactCtrl = TextEditingController();

  /// ===============================
  /// 🔹 STATE
  /// ===============================
  final RxnInt selectedLoanTypeId = RxnInt();
  final RxList<Map<String, dynamic>> loanTypes = <Map<String, dynamic>>[].obs;

  final RxString amountType = ''.obs;
  final RxString loanAmount = ''.obs;
  final RxString timePeriod = ''.obs;
  final RxString loanInterest = ''.obs;

  final RxInt pendingCount = 0.obs;
  final RxString employment = ''.obs;

  final RxString employeeId = ''.obs;
  final RxInt organizationId = 0.obs;
  final RxBool isLoading = false.obs;

  /// ===============================
  /// 🔹 INIT
  /// ===============================
  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _loadFromCache();
    await fetchLoanTypes();
    ever(selectedLoanTypeId, (_) => updateLoanDetails());
  }

  /// ===============================
  /// 🔹 CACHE
  /// ===============================
  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    employeeId.value = prefs.getString('username') ?? '';
    organizationId.value = prefs.getInt('organization_id') ?? 0;
  }

  /// ===============================
  /// 🔹 FETCH LOAN TYPES
  /// ===============================
  Future<void> fetchLoanTypes() async {
    try {
      isLoading.value = true;

      final response = await authService.loan.getLoanTypes(
        organizationId: organizationId.value,
      );

      loanTypes.assignAll(response);

      if (loanTypes.isNotEmpty) {
        selectedLoanTypeId.value = loanTypes.first['id'];
      }
    } catch (e) {
      AppAlert.toast(
        title: 'Error',
        message: 'Failed to fetch loan types',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// 🔹 UPDATE DETAILS
  /// ===============================
  void updateLoanDetails() {
    final loan = loanTypes.firstWhere(
      (e) => e['id'] == selectedLoanTypeId.value,
      orElse: () => {},
    );

    amountType.value = loan['amount_type']?.toString() ?? '';
    loanAmount.value = loan['amount_value']?.toString() ?? '';
    timePeriod.value = loan['duration_months']?.toString() ?? '';
    loanInterest.value = loan['interest_rate']?.toString() ?? '';
    pendingCount.value = loan['pendingCount'] ?? 0;
    employment.value = loan['employment']?.toString() ?? '';
  }

  /// ===============================
  /// 🔹 CHECK IF GUARANTOR REQUIRED
  /// ===============================
  bool get isGuarantorRequired {
    return selectedLoanTypeId.value == 1 ||
        selectedLoanTypeId.value == 4 ||
        selectedLoanTypeId.value == 5;
  }

  /// ===============================
  /// 🔹 SUBMIT REQUEST
  /// ===============================
  Future<void> submitLoanRequest() async {
    if (selectedLoanTypeId.value == null) {
      AppAlert.toast(
        title: 'Error',
        message: 'Select loan type',
      );
      return;
    }

    if (isGuarantorRequired &&
        (guarantor1NameCtrl.text.isEmpty ||
            guarantor1ContactCtrl.text.isEmpty ||
            guarantor2NameCtrl.text.isEmpty ||
            guarantor2ContactCtrl.text.isEmpty)) {
      AppAlert.toast(
        title: 'Error',
        message: 'Guarantor details are required',
      );
      return;
    }

    final payload = {
      "organization_id": organizationId.value,
      "employee_no": employeeId.value,
      "loan_type_id": selectedLoanTypeId.value,
      if (isGuarantorRequired) ...{
        "guarantee1_name": guarantor1NameCtrl.text.trim(),
        "guarantee1_contact": guarantor1ContactCtrl.text.trim(),
        "guarantee2_name": guarantor2NameCtrl.text.trim(),
        "guarantee2_contact": guarantor2ContactCtrl.text.trim(),
      }
    };

    try {
      isLoading.value = true;
      await authService.loan.submitLoanRequest(payload);

      AppAlert.toast(
        title: 'Success',
        message: 'Loan request submitted',
      );

      clearForm();
    } catch (e) {
      AppAlert.toast(
        title: 'Error',
        message: 'Submission failed',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// 🔹 CLEAR
  /// ===============================
  void clearForm() {
    purposeController.clear();
    guarantor1NameCtrl.clear();
    guarantor1ContactCtrl.clear();
    guarantor2NameCtrl.clear();
    guarantor2ContactCtrl.clear();
  }

  @override
  void onClose() {
    purposeController.dispose();
    guarantor1NameCtrl.dispose();
    guarantor1ContactCtrl.dispose();
    guarantor2NameCtrl.dispose();
    guarantor2ContactCtrl.dispose();
    super.onClose();
  }
}

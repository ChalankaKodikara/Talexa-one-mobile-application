import 'dart:io';
import 'package:corehris/auth/authservices.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class ClaimApplyController extends GetxController {
  final AuthService authService = Get.put(AuthService());

  final RxBool isSubmitting = false.obs;
  final RxString error = ''.obs;

  final RxString employeeNo = ''.obs;
  final RxDouble claimAmount = 0.0.obs;

  late int claimConfigurationId;

  final RxList<File> documents = <File>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadEmployeeNo();
  }

  Future<void> _loadEmployeeNo() async {
    final prefs = await SharedPreferences.getInstance();
    employeeNo.value = prefs.getString('username') ?? '';
  }

  Future<void> pickDocuments() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();

    if (files.isNotEmpty) {
      documents.addAll(files.map((e) => File(e.path)));
    }
  }

  void removeDocument(int index) {
    documents.removeAt(index);
  }

  Future<void> submit() async {
    if (claimAmount.value <= 0) {
      error.value = 'Please enter claim amount';
      return;
    }

    try {
      isSubmitting.value = true;
      error.value = '';

      await authService.claims.submitClaim(
        employeeNo: employeeNo.value,
        claimConfigurationId: claimConfigurationId,
        claimAmount: claimAmount.value,
        documents: documents,
      );

      Get.back();
      AppAlert.toast(
        title: 'Success',
        message: 'Claim submitted successfully',
      );
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSubmitting.value = false;
    }
  }
}

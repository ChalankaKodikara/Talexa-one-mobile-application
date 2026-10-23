import 'package:corehris/modules/HRMS/lock_screen/screens/pinlogin_page.dart';
import 'package:corehris/auth/authservices.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinSetupController extends GetxController {
  final AuthService _authService = AuthService();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxString username = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    username.value = prefs.getString('username') ?? '';
  }

  Future<void> setupPin() async {
    if (isLoading.value) return;
    final pin = pinController.text.trim();
    final confirm = confirmPinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      AppAlert.toast(title: 'Invalid PIN', message: 'Enter exactly 4 digits.');
      return;
    }
    if (pin != confirm) {
      AppAlert.toast(title: 'PIN mismatch', message: 'Both PINs must match.');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authService.setupPin(pin);
      if (response == null) {
        AppAlert.toast(title: 'Error', message: 'No response from server.');
        return;
      }
      if (response['success'] != true) {
        AppAlert.toast(title: 'PIN setup failed',
          message: response['message']?.toString() ?? 'Please try again.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      // Preserve existing login-flow keys; don't save PIN in new keys.
      await prefs.setString('saved_pin', pin);
      await prefs.setString('saved_username_for_pin', username.value);
      AppAlert.toast(title: 'Success',
        message: response['message']?.toString() ?? 'PIN saved successfully.');
      Get.offAll(() => PinLoginScreen());
    } catch (error) {
      debugPrint('PIN setup error: $error');
      AppAlert.toast(title: 'Error', message: 'Unable to save your PIN. Try again.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    pinController.dispose();
    confirmPinController.dispose();
    super.onClose();
  }
}

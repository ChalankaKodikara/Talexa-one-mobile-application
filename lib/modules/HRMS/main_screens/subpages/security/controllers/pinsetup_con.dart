// ignore_for_file: depend_on_referenced_packages, unnecessary_null_comparison, invalid_use_of_protected_member

import 'package:corehris/modules/HRMS/lock_screen/screens/pinlogin_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corehris/auth/authservices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class PinSetupController extends GetxController {
  final AuthService _authService = AuthService();

  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();

  RxBool isLoading = false.obs;
  RxString username = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();
  }

  /// 🔹 Load saved username from SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    username.value = prefs.getString('username') ?? '';
  }

  /// 🔹 Setup PIN and navigate to PIN Login
  Future<void> setupPin() async {
    final pin = pinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (pin.isEmpty || confirmPin.isEmpty) {
      _showSnackbar("Error", "Please enter both PIN fields", Colors.red);
      return;
    }

    if (pin != confirmPin) {
      _showSnackbar("Error", "PINs do not match", Colors.red);
      return;
    }

    try {
      isLoading.value = true;

      /// 🔹 Call backend API to register PIN
      final response = await _authService.setupPin(pin);

      if (response == null) {
        _showSnackbar("Error", "No response from server", Colors.red);
        return;
      }

      final bool success = response['success'] ?? false;
      final String message =
          response['message'] ?? 'Unexpected response from server';

      if (!success) {
        _showSnackbar("Failed", message, Colors.red);
        return;
      }

      /// ✅ Save PIN and username locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_pin', pin);
      await prefs.setString('saved_username_for_pin', username.value);
      await prefs.reload();

      _showSnackbar("Success", message, Colors.green);

      /// ✅ Safe navigation (avoid disposed TextEditingController errors)
      Future.delayed(const Duration(milliseconds: 400), () async {
        Get.offAll(() => PinLoginScreen());

        // Delay controller deletion until after navigation rebuild
        await Future.delayed(const Duration(milliseconds: 300));
        if (Get.isRegistered<PinSetupController>()) {
          Get.delete<PinSetupController>(force: true);
        }
      });
    } catch (e) {
      debugPrint("❌ SetupPin Error: $e");
      _showSnackbar(
        "Error",
        e.toString().replaceAll("Exception:", "").trim(),
        Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Snackbar helper
  void _showSnackbar(String title, String message, Color color) {
    AppAlert.toast(
      title: title,
      message: message,
    );
  }

  @override
  void onClose() {
    // Protect against controller disposal race conditions
    Future.delayed(const Duration(milliseconds: 200), () {
      if (pinController.hasListeners) pinController.dispose();
      if (confirmPinController.hasListeners) confirmPinController.dispose();
    });
    super.onClose();
  }
}

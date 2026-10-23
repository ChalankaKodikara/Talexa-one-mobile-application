import 'package:corehris/auth/authservices.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corehris/utils/app_alert.dart';

class TwoFaController extends GetxController {
  final AuthService _authService = AuthService();

  final isEnabled = false.obs;
  final isProcessing = false.obs;
  final isSettingUp = false.obs;

  final otpController = TextEditingController();

  // ==========================================
  // INIT - CHECK STATUS WHEN PAGE OPENS
  // ==========================================
  @override
  void onInit() {
    super.onInit();
    refreshStatus();
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }

  // ==========================================
  // GET STATUS FROM BACKEND
  // ==========================================
  Future<void> refreshStatus() async {
    try {
      isProcessing.value = true;
      final status = await _authService.get2FAStatus();
      isEnabled.value = status;
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: "Failed to fetch 2FA status: $e",
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // ==========================================
  // TOGGLE SWITCH HANDLER
  // ==========================================
  void toggleSwitch(bool value) {
    if (value) {
      startSetup();
    } else {
      startDisableFlow();
    }
  }

  // ==========================================
  // ENABLE FLOW
  // ==========================================
  void startSetup() {
    _showPasswordDialog();
  }

  void _showPasswordDialog() {
    final passwordController = TextEditingController();

    Get.defaultDialog(
      title: "Enable 2FA",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter your password to continue."),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: "Continue",
      textCancel: "Cancel",
      onConfirm: () async {
        final password = passwordController.text.trim();

        if (password.isEmpty) {
          AppAlert.toast(
            title: "Error",
            message: "Password is required",
          );
          return;
        }

        Get.back();
        await _enableWithPassword(password);
        passwordController.dispose();
      },
      onCancel: () => passwordController.dispose(),
    );
  }

  Future<void> _enableWithPassword(String password) async {
    try {
      isProcessing.value = true;

      await _authService.enableTwoFactorAuth(password);

      isSettingUp.value = true;
      otpController.clear();

      AppAlert.toast(
        title: "OTP Sent",
        message: "Verification code sent to your email.",
      );
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: e.toString(),
      );
      isEnabled.value = false;
    } finally {
      isProcessing.value = false;
    }
  }

  // ==========================================
  // CONFIRM ENABLE (OTP)
  // ==========================================
  Future<void> confirmEnable() async {
    final code = otpController.text.trim();

    if (code.length != 6) {
      AppAlert.toast(
        title: "Error",
        message: "Enter valid 6 digit OTP",
      );
      return;
    }

    try {
      isProcessing.value = true;

      await _authService.confirmEnableTwoFactorAuth(code);

      isSettingUp.value = false;
      isEnabled.value = true;
      otpController.clear();

      AppAlert.toast(
        title: "2FA Enabled",
        message: "Two-factor authentication enabled successfully.",
      );
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: e.toString(),
      );
      isEnabled.value = false;
    } finally {
      isProcessing.value = false;
    }
  }

  // ==========================================
  // DISABLE FLOW
  // ==========================================
  void startDisableFlow() {
    final passwordController = TextEditingController();

    Get.defaultDialog(
      title: "Disable 2FA",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter your password to disable 2FA."),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: "Disable",
      textCancel: "Cancel",
      onConfirm: () async {
        final password = passwordController.text.trim();

        if (password.isEmpty) {
          AppAlert.toast(
            title: "Error",
            message: "Password is required",
          );
          return;
        }

        Get.back();
        await _disableWithPassword(password);
        passwordController.dispose();
      },
      onCancel: () => passwordController.dispose(),
    );
  }

  Future<void> _disableWithPassword(String password) async {
    try {
      isProcessing.value = true;

      await _authService.disableTwoFactorAuth(password);

      isEnabled.value = false;

      AppAlert.toast(
        title: "2FA Disabled",
        message: "Two-factor authentication disabled.",
      );
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: e.toString(),
      );
      isEnabled.value = true;
    } finally {
      isProcessing.value = false;
    }
  }

  void cancelSetup() {
    isSettingUp.value = false;
    otpController.clear();
  }
}

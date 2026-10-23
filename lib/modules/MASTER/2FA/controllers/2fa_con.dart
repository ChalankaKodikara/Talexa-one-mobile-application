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
    if (isProcessing.value) return;
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
    if (isProcessing.value || isSettingUp.value) return;
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

  void _showPasswordDialog() async {
    if (isProcessing.value) return;
    final password = await _askPassword(enabling: true);
    if (password != null && password.trim().isNotEmpty) {
      await _enableWithPassword(password);
    }
  }

  Future<String?> _askPassword({required bool enabling}) async {
    final passwordCtrl = TextEditingController();
    bool visible = false;
    final result = await Get.dialog<String>(
      StatefulBuilder(builder: (context, update) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final ink = dark ? Colors.white : const Color(0xFF182237);
        final muted = dark ? Colors.white60 : const Color(0xFF89919D);
        final surface = dark ? const Color(0xFF1B2638) : Colors.white;
        return Dialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(enabling ? Icons.shield_outlined : Icons.lock_outline_rounded,
                size: 38, color: const Color(0xFF1769E8)),
              const SizedBox(height: 16),
              Text(enabling ? 'Enable 2FA' : 'Disable 2FA',
                style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(enabling
                  ? 'Enter your password to enable two-factor authentication.'
                  : 'Enter your password to disable two-factor authentication.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12.5, height: 1.5)),
              const SizedBox(height: 22),
              Align(alignment: Alignment.centerLeft,
                child: Text('Password', style: TextStyle(color: ink,
                  fontWeight: FontWeight.w600, fontSize: 13))),
              const SizedBox(height: 9),
              TextField(
                controller: passwordCtrl,
                autofocus: true,
                obscureText: !visible,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  filled: true,
                  fillColor: dark ? const Color(0xFF263449) : const Color(0xFFF7FAFF),
                  suffixIcon: IconButton(
                    tooltip: visible ? 'Hide password' : 'Show password',
                    onPressed: () => update(() => visible = !visible),
                    icon: Icon(visible ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined, color: muted),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none),
                ),
                onSubmitted: (_) {
                  if (passwordCtrl.text.trim().isNotEmpty) {
                    Navigator.of(context).pop(passwordCtrl.text);
                  }
                },
              ),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(47),
                    foregroundColor: ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (passwordCtrl.text.trim().isEmpty) {
                      AppAlert.toast(title: 'Required', message: 'Enter your password');
                      return;
                    }
                    Navigator.of(context).pop(passwordCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1769E8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(47), elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: Text(enabling ? 'Continue' : 'Disable'),
                )),
              ]),
            ]),
          ),
        );
      }),
    );
    // The dialog is no longer on screen before this controller is released.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    passwordCtrl.dispose();
    return result;
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
    if (isProcessing.value) return;
    final code = otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
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
  void startDisableFlow() async {
    if (isProcessing.value) return;
    final password = await _askPassword(enabling: false);
    if (password != null && password.trim().isNotEmpty) {
      await _disableWithPassword(password);
    }
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
    if (isProcessing.value) return;
    isSettingUp.value = false;
    otpController.clear();
  }
}

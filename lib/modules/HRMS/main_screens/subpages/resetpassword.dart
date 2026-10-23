// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:corehris/utils/app_alert.dart';

class ResetpasswordPageController extends GetxController {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final AuthService authService = AuthService();
  final isLoading = false.obs;

  // 👁️ Visibility toggles
  final isCurrentPasswordVisible = false.obs;
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> resetPassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      AppAlert.toast(
        title: 'Error',
        message: 'All fields are required.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppAlert.toast(
        title: 'Error',
        message: 'New password and confirm password do not match.',
      );
      return;
    }

    try {
      isLoading.value = true;

      await authService.resetPassword(
        currentPassword,
        confirmPassword,
      );

      Get.defaultDialog(
        title: 'Success',
        titleStyle: const TextStyle(fontWeight: FontWeight.w800),
        middleText: 'Password changed successfully.',
        confirmTextColor: Colors.white,
        buttonColor: HexColor('#10A957'),
        textConfirm: 'OK',
        onConfirm: () {
          Get.offAll(() => const LoginScreen());
        },
      );
    } catch (e) {
      debugPrint("❌ Reset password error: $e");
      AppAlert.toast(
        title: 'Error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class ResetpasswordPage extends StatelessWidget {
  final String username;
  final ResetpasswordPageController controller =
      Get.put(ResetpasswordPageController());

  ResetpasswordPage({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final card = cs.surface;
    final onCard = cs.onSurface;
    final subText = cs.onSurface.withOpacity(0.70);
    final border = isDark ? Colors.white12 : Colors.black12;

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => DashboardScreen());
        return false;
      },
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: card,
          foregroundColor: onCard,
          elevation: 0,
          title: const Text(
            'Password Change',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary2.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary2.withOpacity(0.22),
                            ),
                          ),
                          child: const Icon(Icons.lock_reset,
                              color: AppColors.primary2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Change your password",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: onCard,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Employee: $username",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subText,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Form card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildPasswordField(
                          controller: controller.currentPasswordController,
                          label: 'Current Password',
                          isVisible: controller.isCurrentPasswordVisible,
                          onToggle: () =>
                              controller.isCurrentPasswordVisible.value =
                                  !controller.isCurrentPasswordVisible.value,
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: controller.newPasswordController,
                          label: 'Create New Password',
                          isVisible: controller.isNewPasswordVisible,
                          onToggle: () => controller.isNewPasswordVisible
                              .value = !controller.isNewPasswordVisible.value,
                          icon: Icons.password,
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: controller.confirmPasswordController,
                          label: 'Confirm New Password',
                          isVisible: controller.isConfirmPasswordVisible,
                          onToggle: () =>
                              controller.isConfirmPasswordVisible.value =
                                  !controller.isConfirmPasswordVisible.value,
                          icon: Icons.verified_outlined,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.primary2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.resetPassword,
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text(
                                    'Reset Password',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Tip: Use a strong password you don’t reuse elsewhere.",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: subText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // 🔹 Password field with eye icon (dark theme friendly)
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required RxBool isVisible,
    required VoidCallback onToggle,
    required IconData icon,
  }) {
    return Obx(() {
      final theme = Theme.of(Get.context!);
      final cs = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      return TextField(
        controller: controller,
        obscureText: !isVisible.value,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary2),
          filled: true,
          fillColor: isDark ? const Color(0xFF1A2236) : Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: isDark ? Colors.white24 : Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary2, width: 1.6),
          ),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withOpacity(0.60),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible.value ? Icons.visibility : Icons.visibility_off,
              color: cs.onSurface.withOpacity(0.55),
            ),
            onPressed: onToggle,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      );
    });
  }
}

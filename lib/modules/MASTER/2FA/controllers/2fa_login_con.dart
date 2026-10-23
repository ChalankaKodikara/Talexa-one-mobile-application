// twofa_login_controller.dart

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:corehris/utils/app_alert.dart';

class TwoFaLoginController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final otpController = TextEditingController();

  final isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args != null && args is Map) {
      emailController.text = args["email"] ?? "";
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    super.onClose();
  }

  // =========================================================
  // ✅ VERIFY OTP
  // =========================================================
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    final email = emailController.text.trim();

    if (otp.length != 6) {
      AppAlert.toast(
        title: "Error",
        message: "Enter valid 6 digit OTP",
      );
      return;
    }

    isProcessing.value = true;

    try {
      final response = await _authService.login2FAOtp(email, otp);

      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        if (data["success"] == true) {
          Get.offAll(() => DashboardScreen());
          return;
        }

        AppAlert.toast(
          title: "Verification Failed",
          message: data["message"] ?? "Invalid OTP",
        );
        return;
      }

      AppAlert.toast(
        title: "Error",
        message: "Unexpected server response",
      );
    } on DioException catch (e) {
      final backendMessage = e.response?.data?["message"];

      AppAlert.toast(
        title: "Error",
        message: backendMessage ?? "OTP verification failed",
      );
    } catch (_) {
      AppAlert.toast(
        title: "Error",
        message: "Something went wrong. Please try again.",
      );
    } finally {
      isProcessing.value = false;
    }
  }
}

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:corehris/utils/api_error_handler.dart';
import 'package:corehris/utils/app_snackbar.dart';
import 'package:get/get.dart';

enum ForgotPasswordStep {
  email,
  otp,
  password,
}

class ForgotPasswordController extends GetxController {
  final AuthService _authService = AuthService();

  final Rx<ForgotPasswordStep> currentStep = ForgotPasswordStep.email.obs;

  final RxString email = ''.obs;
  final RxString otp = ''.obs;
  final RxString newPassword = ''.obs;
  final RxString confirmPassword = ''.obs;

  final RxString emailError = ''.obs;
  final RxString otpError = ''.obs;
  final RxString newPasswordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;
  final RxString generalError = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isNewPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;
  final RxBool otpVerified = false.obs;

  int get stepNumber {
    switch (currentStep.value) {
      case ForgotPasswordStep.email:
        return 1;
      case ForgotPasswordStep.otp:
        return 2;
      case ForgotPasswordStep.password:
        return 3;
    }
  }

  String get title {
    switch (currentStep.value) {
      case ForgotPasswordStep.email:
        return 'Forgot Password';
      case ForgotPasswordStep.otp:
        return 'Verify OTP';
      case ForgotPasswordStep.password:
        return 'Create New Password';
    }
  }

  String get description {
    switch (currentStep.value) {
      case ForgotPasswordStep.email:
        return 'Enter your registered email address and we will send you a verification code.';

      case ForgotPasswordStep.otp:
        final currentEmail = email.value.trim();

        if (currentEmail.isEmpty) {
          return 'Enter the verification code sent to your email address.';
        }

        return 'Enter the verification code sent to $currentEmail.';

      case ForgotPasswordStep.password:
        return 'Enter your new password to complete the password reset.';
    }
  }

  void clearAllErrors() {
    emailError.value = '';
    otpError.value = '';
    newPasswordError.value = '';
    confirmPasswordError.value = '';
    generalError.value = '';
  }

  void clearEmailError() {
    emailError.value = '';
    generalError.value = '';
  }

  void clearOtpError() {
    otpError.value = '';
    generalError.value = '';
  }

  void clearNewPasswordError() {
    newPasswordError.value = '';
    generalError.value = '';
  }

  void clearConfirmPasswordError() {
    confirmPasswordError.value = '';
    generalError.value = '';
  }

  bool validateEmail() {
    emailError.value = '';
    generalError.value = '';

    final value = email.value.trim();

    if (value.isEmpty) {
      emailError.value = 'Email address is required';
      return false;
    }

    if (!GetUtils.isEmail(value)) {
      emailError.value = 'Enter a valid email address';
      return false;
    }

    return true;
  }

  bool validateOtp() {
    otpError.value = '';
    generalError.value = '';

    final value = otp.value.trim();

    if (value.isEmpty) {
      otpError.value = 'OTP is required';
      return false;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      otpError.value = 'Enter the 6-digit OTP';
      return false;
    }

    return true;
  }

  bool validatePasswords() {
    newPasswordError.value = '';
    confirmPasswordError.value = '';
    generalError.value = '';

    bool valid = true;

    final passwordValue = newPassword.value;
    final confirmValue = confirmPassword.value;

    if (passwordValue.trim().isEmpty) {
      newPasswordError.value = 'New password is required';
      valid = false;
    } else if (passwordValue.length < 6) {
      newPasswordError.value = 'Password must contain at least 6 characters';
      valid = false;
    }

    if (confirmValue.trim().isEmpty) {
      confirmPasswordError.value = 'Confirm password is required';
      valid = false;
    } else if (passwordValue != confirmValue) {
      confirmPasswordError.value = 'Passwords do not match';
      valid = false;
    }

    return valid;
  }

  Future<void> sendOtp() async {
    if (isLoading.value) return;

    if (!validateEmail()) return;

    isLoading.value = true;
    generalError.value = '';

    try {
      final currentEmail = email.value.trim();

      final response = await _authService.forgotPasswordGetOtp(
        currentEmail,
      );

      final data = _toMap(response.data);

      if (!_isSuccessful(
        response.statusCode,
        data,
      )) {
        final message = _extractMessage(data['message']) ??
            _extractMessage(data['error']) ??
            'Failed to send verification code.';

        generalError.value = message;
        AppSnackbar.error(message);

        return;
      }

      otp.value = '';
      otpVerified.value = false;

      newPassword.value = '';
      confirmPassword.value = '';

      clearAllErrors();

      currentStep.value = ForgotPasswordStep.otp;

      final message = _extractMessage(data['message']) ??
          'Verification code sent successfully.';

      AppSnackbar.success('Success', message);
    } catch (e) {
      final message = ApiErrorHandler.getMessage(e);

      generalError.value = message;
      AppSnackbar.error(message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (isLoading.value) return;

    if (email.value.trim().isEmpty) {
      generalError.value =
          'Email address is missing. Please enter your email again.';

      currentStep.value = ForgotPasswordStep.email;

      return;
    }

    if (!validateOtp()) return;

    isLoading.value = true;
    generalError.value = '';

    try {
      final response = await _authService.forgotPasswordVerifyOtp(
        email.value.trim(),
        otp.value.trim(),
      );

      final data = _toMap(response.data);

      if (!_isSuccessful(
        response.statusCode,
        data,
      )) {
        final message = _extractMessage(data['message']) ??
            _extractMessage(data['error']) ??
            'Invalid or expired OTP.';

        otpVerified.value = false;
        generalError.value = message;

        AppSnackbar.error(message);

        return;
      }

      otpVerified.value = true;

      newPassword.value = '';
      confirmPassword.value = '';

      clearAllErrors();

      currentStep.value = ForgotPasswordStep.password;

      final message =
          _extractMessage(data['message']) ?? 'OTP verified successfully.';

      AppSnackbar.success('Success', message);
    } catch (e) {
      otpVerified.value = false;

      final message = ApiErrorHandler.getMessage(e);

      generalError.value = message;
      AppSnackbar.error(message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (isLoading.value) return;

    final currentEmail = email.value.trim();

    if (currentEmail.isEmpty) {
      generalError.value =
          'Email address is missing. Please enter your email again.';

      currentStep.value = ForgotPasswordStep.email;

      return;
    }

    if (!GetUtils.isEmail(currentEmail)) {
      emailError.value = 'Enter a valid email address';

      currentStep.value = ForgotPasswordStep.email;

      return;
    }

    isLoading.value = true;
    generalError.value = '';

    try {
      final response = await _authService.forgotPasswordGetOtp(
        currentEmail,
      );

      final data = _toMap(response.data);

      if (!_isSuccessful(
        response.statusCode,
        data,
      )) {
        final message = _extractMessage(data['message']) ??
            _extractMessage(data['error']) ??
            'Unable to resend OTP.';

        generalError.value = message;

        AppSnackbar.error(message);

        return;
      }

      otp.value = '';
      otpVerified.value = false;

      newPassword.value = '';
      confirmPassword.value = '';

      clearAllErrors();

      currentStep.value = ForgotPasswordStep.otp;

      final message = _extractMessage(data['message']) ??
          'A new verification code has been sent.';

      AppSnackbar.success('Success', message);
    } catch (e) {
      final message = ApiErrorHandler.getMessage(e);

      generalError.value = message;
      AppSnackbar.error(message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setNewPassword() async {
    if (isLoading.value) return;

    final currentEmail = email.value.trim();

    if (currentEmail.isEmpty) {
      generalError.value =
          'Email address is missing. Please restart the password reset process.';

      currentStep.value = ForgotPasswordStep.email;

      return;
    }

    if (!otpVerified.value) {
      generalError.value = 'Please verify the OTP first.';

      currentStep.value = ForgotPasswordStep.otp;

      return;
    }

    if (!validatePasswords()) return;

    isLoading.value = true;
    generalError.value = '';

    try {
      final response = await _authService.forgotPasswordSetNew(
        currentEmail,
        newPassword.value,
      );

      final data = _toMap(response.data);

      if (!_isSuccessful(
        response.statusCode,
        data,
      )) {
        final message = _extractMessage(data['message']) ??
            _extractMessage(data['error']) ??
            'Unable to update password.';

        generalError.value = message;

        AppSnackbar.error(message);

        return;
      }

      final message =
          _extractMessage(data['message']) ?? 'Password changed successfully.';

      clearResetState();

      AppSnackbar.success('Success', message);

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      Get.offAll(
        () => const LoginScreen(),
      );
    } catch (e) {
      final message = ApiErrorHandler.getMessage(e);

      generalError.value = message;

      AppSnackbar.error(message);
    } finally {
      isLoading.value = false;
    }
  }

  void goBack() {
    if (isLoading.value) return;

    generalError.value = '';

    switch (currentStep.value) {
      case ForgotPasswordStep.email:
        clearResetState();
        Get.back();
        break;

      case ForgotPasswordStep.otp:
        otp.value = '';
        otpError.value = '';
        otpVerified.value = false;

        currentStep.value = ForgotPasswordStep.email;
        break;

      case ForgotPasswordStep.password:
        newPassword.value = '';
        confirmPassword.value = '';

        newPasswordError.value = '';
        confirmPasswordError.value = '';

        currentStep.value = ForgotPasswordStep.otp;
        break;
    }
  }

  void goToLogin() {
    if (isLoading.value) return;

    clearResetState();

    Get.offAll(
      () => const LoginScreen(),
    );
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordHidden.value = !isNewPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  void clearResetState() {
    currentStep.value = ForgotPasswordStep.email;

    email.value = '';
    otp.value = '';
    newPassword.value = '';
    confirmPassword.value = '';

    emailError.value = '';
    otpError.value = '';
    newPasswordError.value = '';
    confirmPasswordError.value = '';
    generalError.value = '';

    otpVerified.value = false;

    isNewPasswordHidden.value = true;
    isConfirmPasswordHidden.value = true;
  }

  Map<String, dynamic> _toMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (_) {
        return {};
      }
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return {};
  }

  bool _isSuccessful(
    int? statusCode,
    Map<String, dynamic> data,
  ) {
    if (statusCode == null) {
      return false;
    }

    if (statusCode < 200 || statusCode >= 300) {
      return false;
    }

    if (!data.containsKey('success')) {
      return true;
    }

    final success = data['success'];

    if (success is bool) {
      return success;
    }

    if (success is String) {
      return success.toLowerCase() == 'true';
    }

    if (success is num) {
      return success == 1;
    }

    return false;
  }

  String? _extractMessage(
    dynamic message,
  ) {
    if (message == null) {
      return null;
    }

    if (message is String) {
      final value = message.trim();

      return value.isEmpty ? null : value;
    }

    if (message is List) {
      if (message.isEmpty) {
        return null;
      }

      return message
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .join('\n');
    }

    if (message is Map) {
      if (message.isEmpty) {
        return null;
      }

      try {
        return const JsonEncoder.withIndent(
          '  ',
        ).convert(message);
      } catch (_) {
        return message.toString();
      }
    }

    final value = message.toString().trim();

    return value.isEmpty ? null : value;
  }
}

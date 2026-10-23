// lib/modules/screens/main_screens/subpages/security/controllers/security_controller.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:corehris/utils/app_alert.dart';

class SecurityController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();

  var isBiometricEnabled = false.obs;
  var availableBiometrics = <BiometricType>[].obs;
  var username = ''.obs;
  var canUseBiometrics =
      false.obs; // ✅ to disable switch if device not supported

  @override
  void onInit() {
    super.onInit();
    loadUsername();
    loadBiometricPreference();
    checkAvailableBiometrics();
  }

  /// Enable/disable biometrics with authentication
  Future<void> toggleBiometric(bool value) async {
    if (value) {
      try {
        final canCheck = await auth.canCheckBiometrics;
        final isSupported = await auth.isDeviceSupported();

        if (!canCheck || !isSupported) {
          canUseBiometrics.value = false;
          AppAlert.toast(
            title: "Error",
            message: "Biometric authentication not available",
          );
          return;
        }

        final didAuthenticate = await auth.authenticate(
          localizedReason: "Enable biometric login",
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );

        if (didAuthenticate) {
          isBiometricEnabled.value = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('biometric_enabled', true);
          await checkAvailableBiometrics();

          AppAlert.toast(
            title: "Success",
            message: "Biometric login enabled",
          );
        } else {
          isBiometricEnabled.value = false;
          AppAlert.toast(
            title: "Cancelled",
            message: "Biometric setup cancelled",
          );
        }
      } catch (e) {
        isBiometricEnabled.value = false;
        AppAlert.toast(
          title: "Error",
          message: "Biometric setup failed: $e",
        );
      }
    } else {
      isBiometricEnabled.value = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);

      AppAlert.toast(
        title: "Disabled",
        message: "Biometric login disabled",
      );
    }
  }

  /// Check device biometric capabilities
  Future<void> checkAvailableBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      canUseBiometrics.value = canCheck && isSupported;

      if (canUseBiometrics.value) {
        final biometrics = await auth.getAvailableBiometrics();
        availableBiometrics.assignAll(biometrics);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'available_biometrics',
          biometrics.map((b) => b.toString()).toList(),
        );
      }
    } catch (e) {
      canUseBiometrics.value = false;
      print("Error checking biometrics: $e");
    }
  }

  /// Load saved biometric preference
  Future<void> loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    isBiometricEnabled.value = prefs.getBool('biometric_enabled') ?? false;

    final savedBiometrics = prefs.getStringList('available_biometrics') ?? [];
    availableBiometrics.assignAll(
      savedBiometrics.map((b) {
        switch (b) {
          case 'BiometricType.face':
            return BiometricType.face;
          case 'BiometricType.fingerprint':
            return BiometricType.fingerprint;
          case 'BiometricType.iris':
            return BiometricType.iris;
          default:
            return BiometricType.weak;
        }
      }).toList(),
    );
  }

  /// Fetch username from SharedPreferences
  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    username.value = prefs.getString('saved_username_for_pin') ??
        prefs.getString('saved_username') ??
        '';
  }

  /// Logout from all devices
  void logoutAllDevices() {
    // TODO: Call your backend API to invalidate sessions globally
    AppAlert.toast(
      title: "Logged Out",
      message: "All sessions have been terminated",
    );
  }
}

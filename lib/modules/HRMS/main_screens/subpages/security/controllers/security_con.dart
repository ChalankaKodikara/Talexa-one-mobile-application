import 'package:corehris/utils/app_alert.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();
  final isBiometricEnabled = false.obs;
  final availableBiometrics = <BiometricType>[].obs;
  final username = ''.obs;
  final canUseBiometrics = false.obs;
  final isUpdatingBiometrics = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsername();
    loadBiometricPreference();
    checkAvailableBiometrics();
  }

  Future<void> toggleBiometric(bool enabled) async {
    if (isUpdatingBiometrics.value) return;
    isUpdatingBiometrics.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!enabled) {
        await prefs.setBool('biometric_enabled', false);
        isBiometricEnabled.value = false;
        AppAlert.toast(title: 'Disabled', message: 'Biometric login disabled');
        return;
      }
      final available =
          await auth.canCheckBiometrics && await auth.isDeviceSupported();
      canUseBiometrics.value = available;
      if (!available) {
        AppAlert.toast(
            title: 'Unavailable',
            message:
                'Biometric authentication is not available on this device.');
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: 'Enable biometric login',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated) {
        AppAlert.toast(
            title: 'Cancelled', message: 'Biometric setup cancelled');
        return;
      }
      await prefs.setBool('biometric_enabled', true);
      isBiometricEnabled.value = true;
      await checkAvailableBiometrics();
      AppAlert.toast(title: 'Success', message: 'Biometric login enabled');
    } catch (error) {
      AppAlert.toast(
          title: 'Error',
          message: 'Biometric configuration failed. Please try again.');
    } finally {
      isUpdatingBiometrics.value = false;
    }
  }

  Future<void> checkAvailableBiometrics() async {
    try {
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      canUseBiometrics.value = supported && canCheck;
      if (!canUseBiometrics.value) {
        availableBiometrics.clear();
        return;
      }
      final list = await auth.getAvailableBiometrics();
      availableBiometrics.assignAll(list);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'available_biometrics', list.map((item) => item.toString()).toList());
    } catch (_) {
      canUseBiometrics.value = false;
      availableBiometrics.clear();
    }
  }

  Future<void> loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    isBiometricEnabled.value = prefs.getBool('biometric_enabled') ?? false;
    final saved = prefs.getStringList('available_biometrics') ?? <String>[];
    availableBiometrics.assignAll(saved.map((item) {
      switch (item) {
        case 'BiometricType.face':
          return BiometricType.face;
        case 'BiometricType.fingerprint':
          return BiometricType.fingerprint;
        case 'BiometricType.iris':
          return BiometricType.iris;
        default:
          return BiometricType.weak;
      }
    }));
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    username.value = prefs.getString('saved_username_for_pin') ??
        prefs.getString('saved_username') ??
        prefs.getString('username') ??
        '';
  }

  // Retained for API compatibility; no success claim without a backend call.
  void logoutAllDevices() {
    AppAlert.toast(
        title: 'Not available',
        message: 'Sign out of all devices requires a server endpoint.');
  }
}

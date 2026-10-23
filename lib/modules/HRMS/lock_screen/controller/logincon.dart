// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:convert';

import 'dart:io';

import 'package:corehris/auth/authservices.dart';

import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';

import 'package:corehris/modules/HRMS/lock_screen/screens/pinlogin_page.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/resetpassword.dart';

import 'package:corehris/modules/MASTER/2FA/screens/2fa_login_confirm_screen.dart';

import 'package:corehris/modules/MASTER/start_page/startpage.dart';

import 'package:corehris/utils/api_error_handler.dart';

import 'package:corehris/utils/app_alert.dart';

import 'package:corehris/utils/app_snackbar.dart';

import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:local_auth/local_auth.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  final LocalAuthentication auth = LocalAuthentication();

  // ============================================================

  // SHARED PREFERENCE KEYS

  // ============================================================

  static const String _keyRememberMe = 'remember_me';

  static const String _keySavedUsername = 'saved_username';

  static const String _keySavedPassword = 'saved_password';

  static const String _keyLoginEmail = 'login_email';

  static const String _keySavedUsernameForPin = 'saved_username_for_pin';

  static const String _keySavedPin = 'saved_pin';

  static const String _keyBiometricEnabled = 'biometric_enabled';

  static const String _keyAccessToken = 'access_token';

  static const String _keyRefreshToken = 'refresh_token';

  static const String _keyTenantId = 'tenant_id';

  static const String _keyTenantUserId = 'tenant_user_id';

  static const String _keyUserData = 'user_data';

  // ============================================================

  // LOGIN STATE

  // ============================================================

  final RxString username = ''.obs;

  final RxString password = ''.obs;

  final RxString usernameError = ''.obs;

  final RxString passwordError = ''.obs;

  final RxString loginError = ''.obs;

  final RxBool isLoading = false.obs;

  final RxBool rememberMe = false.obs;

  final RxBool isPasswordHidden = true.obs;

  final RxBool isBiometricEnabled = false.obs;

  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;

  // ============================================================

  // DEVICE HEADER VALUES

  // ============================================================

  final RxString clientType = 'MOBILE'.obs;

  final RxString deviceId = ''.obs;

  final RxString deviceName = ''.obs;

  final RxString devicePlatform = ''.obs;

  final RxString deviceModel = ''.obs;

  final RxString osVersion = ''.obs;

  final RxString appVersion = ''.obs;

  // ============================================================

  // INIT

  // ============================================================

  @override
  void onInit() {
    super.onInit();

    _initializeController();
  }

  Future<void> _initializeController() async {
    await Future.wait([
      loadSavedCredentials(),
      loadBiometricPreference(),
      checkAvailableBiometrics(),
      _initDeviceInfo(),
    ]);
  }

  // ============================================================

  // DEVICE INFO

  // ============================================================

  Future<void> _initDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      String id = '';

      String name = '';

      String platform = '';

      String model = '';

      String version = '';

      // ========================================================

      // ANDROID

      // ========================================================

      if (Platform.isAndroid) {
        final AndroidDeviceInfo android = await deviceInfo.androidInfo;

        id = android.id.trim();

        final String manufacturer = android.manufacturer.trim();

        final String brand = android.brand.trim();

        final String androidModel = android.model.trim();

        if (brand.isNotEmpty && androidModel.isNotEmpty) {
          name = '$brand $androidModel';
        } else if (manufacturer.isNotEmpty && androidModel.isNotEmpty) {
          name = '$manufacturer $androidModel';
        } else if (androidModel.isNotEmpty) {
          name = androidModel;
        } else {
          name = 'Android Device';
        }

        platform = 'ANDROID';

        model = androidModel.isNotEmpty ? androidModel : name;

        version = android.version.release.trim();
      }

      // ========================================================

      // IOS

      // ========================================================

      else if (Platform.isIOS) {
        final IosDeviceInfo ios = await deviceInfo.iosInfo;

        id = ios.identifierForVendor?.trim() ?? '';

        name = ios.name.trim();

        platform = 'IOS';

        final String hardwareModel = ios.utsname.machine.trim();

        if (hardwareModel.isNotEmpty) {
          model = hardwareModel;
        } else {
          model = ios.model.trim();
        }

        version = ios.systemVersion.trim();
      }

      // ========================================================

      // MAC OS

      // ========================================================

      else if (Platform.isMacOS) {
        final MacOsDeviceInfo mac = await deviceInfo.macOsInfo;

        id = mac.systemGUID?.trim() ?? '';

        name = mac.computerName.trim();

        platform = 'MACOS';

        model = mac.model.trim();

        version = mac.osRelease.trim();
      }

      // ========================================================

      // WINDOWS

      // ========================================================

      else if (Platform.isWindows) {
        final WindowsDeviceInfo windows = await deviceInfo.windowsInfo;

        id = windows.deviceId.trim();

        name = windows.computerName.trim();

        platform = 'WINDOWS';

        model = windows.productName.trim();

        version = windows.displayVersion.trim();
      }

      // ========================================================

      // LINUX

      // ========================================================

      else if (Platform.isLinux) {
        final LinuxDeviceInfo linux = await deviceInfo.linuxInfo;

        id = linux.machineId?.trim() ?? '';

        name = linux.prettyName.trim();

        platform = 'LINUX';

        model = linux.name.trim();

        version = linux.versionId?.trim() ?? '';
      }

      // ========================================================

      // OTHER

      // ========================================================

      else {
        id = '${Platform.operatingSystem}-${Platform.localHostname}';

        name = Platform.localHostname;

        platform = Platform.operatingSystem.toUpperCase();

        model = Platform.operatingSystem;

        version = Platform.operatingSystemVersion;
      }

      // ========================================================

      // FALLBACKS

      // ========================================================

      if (id.trim().isEmpty) {
        id = '${Platform.operatingSystem}-${Platform.localHostname}';
      }

      if (name.trim().isEmpty) {
        name = 'Unknown Device';
      }

      if (platform.trim().isEmpty) {
        platform = Platform.operatingSystem.toUpperCase();
      }

      if (model.trim().isEmpty) {
        model = name;
      }

      if (version.trim().isEmpty) {
        version = Platform.operatingSystemVersion;
      }

      // ========================================================

      // APP VERSION

      // ========================================================

      String currentAppVersion = packageInfo.version.trim();

      final String buildNumber = packageInfo.buildNumber.trim();

      if (buildNumber.isNotEmpty) {
        currentAppVersion = '$currentAppVersion+$buildNumber';
      }

      // ========================================================

      // SAVE VALUES

      // ========================================================

      clientType.value = 'MOBILE';

      deviceId.value = id.trim();

      deviceName.value = name.trim();

      devicePlatform.value = platform.trim();

      deviceModel.value = model.trim();

      osVersion.value = version.trim();

      appVersion.value = currentAppVersion.trim();

      // ========================================================

      // DEBUG

      // ========================================================

      print(
        '==================================================',
      );

      print(
        'LOGIN DEVICE HEADERS',
      );

      print(
        'x-client-type: ${clientType.value}',
      );

      print(
        'x-device-id: ${deviceId.value}',
      );

      print(
        'x-device-name: ${deviceName.value}',
      );

      print(
        'x-device-platform: ${devicePlatform.value}',
      );

      print(
        'x-device-model: ${deviceModel.value}',
      );

      print(
        'x-os-version: ${osVersion.value}',
      );

      print(
        'x-app-version: ${appVersion.value}',
      );

      print(
        '==================================================',
      );
    } catch (e) {
      print(
        'Device information initialization error: $e',
      );

      clientType.value = 'MOBILE';

      deviceId.value = '${Platform.operatingSystem}-${Platform.localHostname}';

      deviceName.value = 'Unknown Device';

      devicePlatform.value = Platform.operatingSystem.toUpperCase();

      deviceModel.value = 'Unknown Device';

      osVersion.value = Platform.operatingSystemVersion;

      try {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();

        final String version = packageInfo.version.trim();

        final String build = packageInfo.buildNumber.trim();

        appVersion.value = build.isNotEmpty ? '$version+$build' : version;
      } catch (_) {
        appVersion.value = 'unknown';
      }
    }
  }

  // ============================================================

  // ENSURE DEVICE INFO EXISTS

  // ============================================================

  Future<void> _ensureDeviceInfo() async {
    if (deviceId.value.trim().isEmpty ||
        deviceName.value.trim().isEmpty ||
        devicePlatform.value.trim().isEmpty ||
        deviceModel.value.trim().isEmpty ||
        osVersion.value.trim().isEmpty ||
        appVersion.value.trim().isEmpty) {
      await _initDeviceInfo();
    }
  }

  // ============================================================

  // VALIDATION

  // ============================================================

  void clearAllErrors() {
    usernameError.value = '';

    passwordError.value = '';

    loginError.value = '';
  }

  void clearUsernameError() {
    usernameError.value = '';

    loginError.value = '';
  }

  void clearPasswordError() {
    passwordError.value = '';

    loginError.value = '';
  }

  bool validateLoginForm() {
    bool isValid = true;

    clearAllErrors();

    final String email = username.value.trim();

    final String pass = password.value;

    if (email.isEmpty) {
      usernameError.value = 'Email is required';

      isValid = false;
    } else if (!GetUtils.isEmail(email)) {
      usernameError.value = 'Enter a valid email address';

      isValid = false;
    }

    if (pass.trim().isEmpty) {
      passwordError.value = 'Password is required';

      isValid = false;
    } else if (pass.length < 4) {
      passwordError.value = 'Password is too short';

      isValid = false;
    }

    return isValid;
  }

  // ============================================================

  // PASSWORD LOGIN

  // ============================================================

  Future<void> login() async {
    if (isLoading.value) {
      return;
    }

    if (!validateLoginForm()) {
      return;
    }

    isLoading.value = true;

    loginError.value = '';

    try {
      await _ensureDeviceInfo();

      final String email = username.value.trim();

      final response = await _authService.login(
        email,
        password.value,
        clientType: clientType.value,
        deviceId: deviceId.value,
        deviceName: deviceName.value,
        devicePlatform: devicePlatform.value,
        deviceModel: deviceModel.value,
        osVersion: osVersion.value,
        appVersion: appVersion.value,
      );

      if (response.data is! Map) {
        loginError.value = 'Unexpected server response. Please try again.';

        AppSnackbar.error(
          loginError.value,
        );

        return;
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );

      // ========================================================

      // API ERROR

      // ========================================================

      if (response.statusCode != 200 || data['success'] != true) {
        final String message = _extractApiMessage(
              data['message'],
            ) ??
            'Login failed. Please try again.';

        loginError.value = message;

        AppSnackbar.error(
          message,
        );

        return;
      }

      // ========================================================

      // 2FA REQUIRED

      // ========================================================

      if (data['require2FA'] == true) {
        Get.to(
          () => const TwoFaLoginVerificationScreen(),
          arguments: {
            'email': email,
            'response': data,
          },
        );

        return;
      }

      // ========================================================

      // PASSWORD CHANGE REQUIRED

      // ========================================================

      if (data['requirePasswordChange'] == true) {
        final String message = _extractApiMessage(
              data['message'],
            ) ??
            'Password change required.';

        loginError.value = message;

        AppAlert.toast(
          title: 'Password Change Required',
          message: message,
        );

        return;
      }

      // ========================================================

      // SUCCESS

      // ========================================================

      final dynamic accessToken = data['accessToken'];

      if (accessToken != null && accessToken.toString().trim().isNotEmpty) {
        username.value = email;

        await _handleSuccessfulLogin(
          data,
          loginEmail: email,
        );

        return;
      }

      loginError.value = _extractApiMessage(
            data['message'],
          ) ??
          'Unexpected login response.';

      AppSnackbar.error(
        loginError.value,
      );
    } catch (e) {
      loginError.value = ApiErrorHandler.getMessage(
        e,
      );

      AppSnackbar.error(
        loginError.value,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================

  // HANDLE SUCCESSFUL LOGIN

  // ============================================================

  Future<void> _handleSuccessfulLogin(
    Map<String, dynamic> data, {
    String? loginEmail,
    bool checkDefaultPassword = true,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String email = loginEmail?.trim() ?? '';
    if (email.isEmpty) email = username.value.trim();
    if (email.isEmpty) email = prefs.getString(_keyLoginEmail)?.trim() ?? '';
    if (email.isEmpty)
      email = prefs.getString(_keySavedUsernameForPin)?.trim() ?? '';
    if (email.isEmpty) {
      final dynamic responseUser = data['user'];
      if (responseUser is Map)
        email = responseUser['email']?.toString().trim() ?? '';
    }

    if (email.isNotEmpty) {
      username.value = email;
      await prefs.setString(_keyLoginEmail, email);
      await prefs.setString(_keySavedUsernameForPin, email);
    }

    if (rememberMe.value) {
      if (email.isNotEmpty) await prefs.setString(_keySavedUsername, email);
      await prefs.setString(_keySavedPassword, password.value);
      await prefs.setBool(_keyRememberMe, true);
    } else {
      await prefs.remove(_keySavedUsername);
      await prefs.remove(_keySavedPassword);
      await prefs.setBool(_keyRememberMe, false);
    }

    final dynamic accessToken = data['accessToken'];
    if (accessToken != null && accessToken.toString().trim().isNotEmpty) {
      await prefs.setString(_keyAccessToken, accessToken.toString());
    }

    final dynamic refreshToken = data['refreshToken'];
    if (refreshToken != null && refreshToken.toString().trim().isNotEmpty) {
      await prefs.setString(_keyRefreshToken, refreshToken.toString());
    }

    if (data['tenant_id'] != null) {
      await prefs.setString(_keyTenantId, data['tenant_id'].toString());
    }
    if (data['tenant_user_id'] != null) {
      await prefs.setString(
          _keyTenantUserId, data['tenant_user_id'].toString());
    }
    if (data['user'] != null) {
      await prefs.setString(_keyUserData, jsonEncode(data['user']));
    }

    final bool isDefaultPassword = _parseBool(data['isDefaultPassword']);
    if (checkDefaultPassword && isDefaultPassword) {
      await _showDefaultPasswordDialog(data: data, email: email);
      return;
    }

    _continueAfterLogin(data);
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;
    final String normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'y';
  }

  Future<void> _showDefaultPasswordDialog({
    required Map<String, dynamic> data,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await Get.dialog<void>(
      PopScope(
        canPop: false,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2495FE).withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      size: 38, color: Color(0xFF2495FE)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Update Your Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'You are currently using the default password. For better account security, we recommend changing your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, height: 1.5, color: Color(0xFF6B7280)),
                ),
                if (email.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 20, color: Color(0xFF6B7280)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151))),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _goToResetPassword(data: data, email: email);
                    },
                    icon: const Icon(Icons.lock_reset_rounded, size: 21),
                    label: const Text('Reset Password',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2495FE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Get.back();
                      _continueAfterLogin(data);
                    },
                    child: const Text('Skip for Now',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _goToResetPassword({
    required Map<String, dynamic> data,
    required String email,
  }) {
    Get.to(
      () => ResetpasswordPage(
        username: username.value.trim(),
      ),
      arguments: {
        'email': email,
        'fromDefaultPassword': true,
        'isDefaultPassword': true,
        'loginResponse': data,
      },
    );
  }

  void _continueAfterLogin(Map<String, dynamic> data) {
    final dynamic rawUserData = data['user'];
    Map<String, dynamic> userData = <String, dynamic>{};
    if (rawUserData is Map<String, dynamic>) {
      userData = rawUserData;
    } else if (rawUserData is Map) {
      userData = Map<String, dynamic>.from(rawUserData);
    }
    final String firstLoginValue =
        userData['first_login']?.toString().trim().toLowerCase() ?? '';
    final bool isFirstLogin = firstLoginValue == 'yes' ||
        firstLoginValue == 'true' ||
        firstLoginValue == '1';
    if (isFirstLogin) {
      goToPinSetup();
    } else {
      Get.offAll(() => LandingPage());
    }
  }

  // ============================================================
  // PIN LOGIN

  // ============================================================

  Future<void> loginWithPin(
    String pin,
  ) async {
    if (isLoading.value) {
      return;
    }

    loginError.value = '';

    final String enteredPin = pin.trim();

    if (enteredPin.isEmpty) {
      loginError.value = 'PIN is required';

      AppSnackbar.error(
        loginError.value,
      );

      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? savedUser = await _getSavedLoginEmail(
      prefs,
    );

    if (savedUser == null || savedUser.trim().isEmpty) {
      loginError.value =
          'PIN login information was not found. Please login with email and password once.';

      AppSnackbar.error(
        loginError.value,
      );

      return;
    }

    final String email = savedUser.trim();

    await prefs.setString(
      _keyLoginEmail,
      email,
    );

    await prefs.setString(
      _keySavedUsernameForPin,
      email,
    );

    username.value = email;

    isLoading.value = true;

    try {
      await _ensureDeviceInfo();

      final response = await _authService.loginWithPinApi(
        email,
        enteredPin,
        clientType: clientType.value,
        deviceId: deviceId.value,
        deviceName: deviceName.value,
        devicePlatform: devicePlatform.value,
        deviceModel: deviceModel.value,
        osVersion: osVersion.value,
        appVersion: appVersion.value,
      );

      if (response.data is! Map) {
        loginError.value = 'Unexpected server response.';

        AppSnackbar.error(
          loginError.value,
        );

        return;
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );

      // ========================================================

      // API ERROR

      // ========================================================

      if (response.statusCode != 200 || data['success'] != true) {
        final String message = _extractApiMessage(
              data['message'],
            ) ??
            'PIN login failed';

        loginError.value = message;

        AppSnackbar.error(
          message,
        );

        return;
      }

      // ========================================================

      // PASSWORD CHANGE

      // ========================================================

      if (data['requirePasswordChange'] == true) {
        final String message = _extractApiMessage(
              data['message'],
            ) ??
            'Password change required';

        loginError.value = message;

        AppSnackbar.error(
          message,
        );

        return;
      }

      // ========================================================

      // 2FA

      // ========================================================

      if (data['require2FA'] == true) {
        Get.to(
          () => const TwoFaLoginVerificationScreen(),
          arguments: {
            'email': email,
            'response': data,
          },
        );

        return;
      }

      // ========================================================

      // SUCCESS

      // ========================================================

      final dynamic accessToken = data['accessToken'];

      if (accessToken != null && accessToken.toString().trim().isNotEmpty) {
        await _handleSuccessfulLogin(
          data,
          loginEmail: email,
          checkDefaultPassword: false,
        );

        return;
      }

      loginError.value = _extractApiMessage(
            data['message'],
          ) ??
          'Unexpected PIN login response.';

      AppSnackbar.error(
        loginError.value,
      );
    } catch (e) {
      loginError.value = ApiErrorHandler.getMessage(
        e,
      );

      AppSnackbar.error(
        loginError.value,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================

  // SAVED LOGIN EMAIL

  // ============================================================

  Future<String?> _getSavedLoginEmail(
    SharedPreferences prefs,
  ) async {
    String? email;

    email = prefs.getString(
      _keyLoginEmail,
    );

    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }

    email = prefs.getString(
      _keySavedUsernameForPin,
    );

    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }

    email = prefs.getString(
      _keySavedUsername,
    );

    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }

    final String? rawUserData = prefs.getString(
      _keyUserData,
    );

    if (rawUserData != null && rawUserData.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(
          rawUserData,
        );

        if (decoded is Map) {
          email = decoded['email']?.toString().trim();

          if (email != null && email.isNotEmpty) {
            return email;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  // ============================================================

  // BIOMETRIC LOGIN

  // ============================================================

  Future<void> loginWithBiometric() async {
    if (isLoading.value) {
      return;
    }

    loginError.value = '';

    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;

      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        loginError.value = 'Biometric authentication is not available';

        AppSnackbar.error(
          loginError.value,
        );

        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to login',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!didAuthenticate) {
        loginError.value = 'Biometric authentication was cancelled';

        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? savedPin = prefs.getString(
        _keySavedPin,
      );

      if (savedPin == null || savedPin.trim().isEmpty) {
        loginError.value = 'No saved PIN found';

        AppSnackbar.error(
          loginError.value,
        );

        return;
      }

      await loginWithPin(
        savedPin,
      );
    } catch (e) {
      loginError.value = ApiErrorHandler.getMessage(
        e,
      );

      AppSnackbar.error(
        loginError.value,
      );
    }
  }

  // ============================================================

  // PASSWORD VISIBILITY

  // ============================================================

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  // ============================================================

  // REMEMBER ME

  // ============================================================

  void setRememberMe(
    bool value,
  ) {
    rememberMe.value = value;
  }

  // ============================================================

  // LOAD SAVED CREDENTIALS

  // ============================================================

  Future<void> loadSavedCredentials() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final bool savedRemember = prefs.getBool(
            _keyRememberMe,
          ) ??
          false;

      rememberMe.value = savedRemember;

      if (savedRemember) {
        username.value = prefs.getString(
              _keySavedUsername,
            ) ??
            '';

        password.value = prefs.getString(
              _keySavedPassword,
            ) ??
            '';

        return;
      }

      final String? storedLoginEmail = await _getSavedLoginEmail(
        prefs,
      );

      if (storedLoginEmail != null && storedLoginEmail.isNotEmpty) {
        username.value = storedLoginEmail;
      }
    } catch (_) {}
  }

  // ============================================================

  // LOAD BIOMETRIC PREFERENCE

  // ============================================================

  Future<void> loadBiometricPreference() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      isBiometricEnabled.value = prefs.getBool(
            _keyBiometricEnabled,
          ) ??
          false;
    } catch (_) {
      isBiometricEnabled.value = false;
    }
  }

  // ============================================================

  // CHECK AVAILABLE BIOMETRICS

  // ============================================================

  Future<void> checkAvailableBiometrics() async {
    try {
      final List<BiometricType> biometrics =
          await auth.getAvailableBiometrics();

      availableBiometrics.assignAll(
        biometrics,
      );
    } catch (_) {
      availableBiometrics.clear();
    }
  }

  // ============================================================

  // CAN USE PIN LOGIN

  // ============================================================

  Future<bool> canUsePinLogin() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? email = await _getSavedLoginEmail(
        prefs,
      );

      return email != null && email.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================

  // CLEAR SESSION TOKENS

  // ============================================================

  Future<void> clearSessionTokens() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _keyAccessToken,
    );

    await prefs.remove(
      _keyRefreshToken,
    );

    await prefs.remove(
      _keyTenantId,
    );

    await prefs.remove(
      _keyTenantUserId,
    );

    // PIN and biometric information stays.
  }

  // ============================================================

  // FULL DEVICE LOGOUT

  // ============================================================

  Future<void> clearDeviceLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _keyAccessToken,
    );

    await prefs.remove(
      _keyRefreshToken,
    );

    await prefs.remove(
      _keyTenantId,
    );

    await prefs.remove(
      _keyTenantUserId,
    );

    await prefs.remove(
      _keyUserData,
    );

    await prefs.remove(
      _keySavedUsername,
    );

    await prefs.remove(
      _keySavedPassword,
    );

    await prefs.setBool(
      _keyRememberMe,
      false,
    );

    await prefs.remove(
      _keyLoginEmail,
    );

    await prefs.remove(
      _keySavedUsernameForPin,
    );

    await prefs.remove(
      _keySavedPin,
    );

    await prefs.remove(
      _keyBiometricEnabled,
    );

    username.value = '';

    password.value = '';

    rememberMe.value = false;

    isBiometricEnabled.value = false;

    clearAllErrors();
  }

  // ============================================================

  // NAVIGATION

  // ============================================================

  void goToPinLogin() {
    Get.offAll(
      () => PinLoginScreen(),
    );
  }

  void goToPasswordLogin() {
    Get.offAll(
      () => const LoginScreen(),
    );
  }

  void goToPinSetup() {
    Get.toNamed(
      '/pin-setup',
    );
  }

  // ============================================================

  // EXTRACT API MESSAGE

  // ============================================================

  String? _extractApiMessage(
    dynamic message,
  ) {
    if (message == null) {
      return null;
    }

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    if (message is List && message.isNotEmpty) {
      return message
          .map(
            (dynamic item) => item.toString(),
          )
          .join(
            '\n',
          );
    }

    if (message is Map) {
      try {
        return const JsonEncoder.withIndent(
          '  ',
        ).convert(
          message,
        );
      } catch (_) {
        return message.toString();
      }
    }

    return message.toString();
  }
}

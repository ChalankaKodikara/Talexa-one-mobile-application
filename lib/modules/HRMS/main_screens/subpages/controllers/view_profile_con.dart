// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/model/employee.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewProfileController extends GetxController {
  final AuthService _authService = AuthService();

  // ============================================================
  // EMPLOYEE OBSERVABLES
  // ============================================================

  final employee = Rxn<Employee>();
  final employeeHistory = <EmploymentHistory>[].obs;

  final isLoading = false.obs;
  final profileImageUrl = RxnString();

  // ============================================================
  // DEVICE OBSERVABLES
  // ============================================================

  final deviceUser = <String, dynamic>{}.obs;

  final registeredDevices = <Map<String, dynamic>>[].obs;

  final deviceHistory = <Map<String, dynamic>>[].obs;

  final loginSessions = <Map<String, dynamic>>[].obs;

  final isDeviceLoading = false.obs;

  final deviceError = RxnString();

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final nameController = TextEditingController();

  final emailController = TextEditingController();

  final phoneController = TextEditingController();

  final addressController = TextEditingController();

  bool _isClosed = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    fetchEmployeeDetails();
  }

  // ============================================================
  // FETCH EMPLOYEE DETAILS
  // ============================================================

  Future<void> fetchEmployeeDetails() async {
    if (_isClosed) return;

    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();

      final String employeeId = prefs.getString('employee_no')?.trim() ?? '';

      if (employeeId.isEmpty) {
        throw Exception(
          'Employee ID missing',
        );
      }

      final response = await _authService.employee.getEmployeePersonalDetails(
        employeeId,
      );

      if (response['data'] == null) {
        throw Exception(
          'Invalid employee response',
        );
      }

      final emp = Employee.fromJson(
        response['data'],
      );

      employee.value = emp;

      employeeHistory.assignAll(
        emp.employmentHistory,
      );

      nameController.text = emp.employeeFullName;

      emailController.text = emp.employeeEmail;

      phoneController.text = emp.employeeContactNo;

      addressController.text = emp.employeePermanentAddress ?? '';

      // ========================================================
      // PROFILE IMAGE
      // ========================================================

      try {
        final imageUrl = await _authService.profile.fetchProfileImage(
          employeeId,
        );

        if (imageUrl != null && imageUrl.trim().isNotEmpty) {
          profileImageUrl.value = imageUrl;
        }
      } catch (e) {
        debugPrint(
          '⚠️ Profile image load failed: $e',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Error fetching employee details: $e',
      );

      AppAlert.toast(
        title: 'Error',
        message: 'Unable to load profile details. '
            'Please try again later.',
      );
    } finally {
      if (!_isClosed) {
        isLoading.value = false;
      }
    }
  }

  // ============================================================
  // REFRESH PROFILE
  // ============================================================

  Future<void> refreshProfile() async {
    if (_isClosed) return;

    await fetchEmployeeDetails();
  }

  // ============================================================
  // UPDATE PROFILE PICTURE
  // ============================================================

  Future<void> updateProfilePicture(
    String filePath,
  ) async {
    if (_isClosed) return;

    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();

      final String employeeId = prefs.getString('employee_no')?.trim() ?? '';

      if (employeeId.isEmpty) {
        throw Exception(
          'Employee ID missing',
        );
      }

      final res = await _authService.profile.saveProfileImage(
        filePath,
        employeeId,
      );

      final String newUrl = res['file_url']?.toString().trim() ?? '';

      if (newUrl.isEmpty) {
        throw Exception(
          'Invalid image upload response',
        );
      }

      profileImageUrl.value = newUrl;

      AppAlert.toast(
        title: 'Success',
        message: 'Profile picture updated successfully',
      );
    } catch (e) {
      debugPrint(
        '❌ Error updating profile picture: $e',
      );

      AppAlert.toast(
        title: 'Error',
        message: 'Failed to update profile picture. '
            'Please try again.',
      );
    } finally {
      if (!_isClosed) {
        isLoading.value = false;
      }
    }
  }

  // ============================================================
  // FETCH REGISTERED DEVICE INFORMATION
  //
  // MASTER API:
  //
  // GET /api/mobile-devices/username/{username}
  // ============================================================

  Future<void> fetchRegisteredDeviceInfo() async {
    if (_isClosed) return;

    // Prevent duplicate requests.
    if (isDeviceLoading.value) {
      return;
    }

    try {
      isDeviceLoading.value = true;
      deviceError.value = null;

      // ========================================================
      // GET USERNAME
      // ========================================================

      final prefs = await SharedPreferences.getInstance();

      String username = prefs.getString('username')?.trim() ?? '';

      debugPrint(
        '════════════════════════════════════════',
      );

      debugPrint(
        '📱 DEVICE INFORMATION REQUEST',
      );

      debugPrint(
        'Stored username: $username',
      );

      debugPrint(
        'Stored employee_no: '
        '${prefs.getString('employee_no')}',
      );

      // ========================================================
      // FALLBACK 1 - PROFILE EMAIL
      // ========================================================

      if (username.isEmpty) {
        username = emailController.text.trim();

        debugPrint(
          'Username fallback -> '
          'emailController: $username',
        );
      }

      // ========================================================
      // FALLBACK 2 - EMPLOYEE EMAIL
      // ========================================================

      if (username.isEmpty && employee.value != null) {
        username = employee.value!.employeeEmail.trim();

        debugPrint(
          'Username fallback -> '
          'employee email: $username',
        );
      }

      if (username.isEmpty) {
        throw Exception(
          'Master username is missing.',
        );
      }

      debugPrint(
        '👤 Device username: $username',
      );

      // ========================================================
      // MASTER API REQUEST
      // ========================================================

      final Map<String, dynamic>? response = await _authService.fetchDeviceLogs(
        username,
      );

      debugPrint(
        '════════════════════════════════════════',
      );

      debugPrint(
        '📦 RAW DEVICE API RESPONSE',
      );

      debugPrint(
        response.toString(),
      );

      debugPrint(
        '════════════════════════════════════════',
      );

      if (response == null) {
        clearDeviceData();

        deviceError.value = 'No device information found.';

        return;
      }

      // ========================================================
      // NORMALIZE RESPONSE
      // ========================================================
      //
      // Supports:
      //
      // {
      //   "success": true,
      //   "message": "...",
      //   "data": {
      //       "user": {},
      //       "devices": [],
      //       "device_history": {},
      //       "login_sessions": []
      //   }
      // }
      //
      // AND:
      //
      // {
      //    "user": {},
      //    "devices": [],
      //    ...
      // }
      //
      // ========================================================

      Map<String, dynamic> data = Map<String, dynamic>.from(
        response,
      );

      final dynamic rawResponseData = response['data'];

      if (rawResponseData is Map) {
        data = Map<String, dynamic>.from(
          rawResponseData,
        );
      }

      debugPrint(
        '📦 NORMALIZED DEVICE DATA',
      );

      debugPrint(
        data.toString(),
      );

      // ========================================================
      // CLEAR OLD DATA
      // ========================================================

      deviceUser.clear();
      registeredDevices.clear();
      deviceHistory.clear();
      loginSessions.clear();

      // ========================================================
      // USER
      // ========================================================

      final dynamic rawUser =
          data['user'] ?? data['account'] ?? data['employee'];

      if (rawUser is Map) {
        deviceUser.assignAll(
          Map<String, dynamic>.from(
            rawUser,
          ),
        );
      }

      // ========================================================
      // REGISTERED DEVICES
      // ========================================================

      final dynamic rawDevices = data['devices'] ??
          data['registered_devices'] ??
          data['registeredDevices'] ??
          data['mobile_devices'] ??
          data['mobileDevices'] ??
          data['device'];

      _assignMapList(
        source: rawDevices,
        target: registeredDevices,
      );

      // ========================================================
      // DEVICE HISTORY
      // ========================================================

      final dynamic rawHistory = data['device_history'] ??
          data['deviceHistory'] ??
          data['history'] ??
          data['device_logs'] ??
          data['deviceLogs'];

      _assignMapList(
        source: rawHistory,
        target: deviceHistory,
      );

      // ========================================================
      // LOGIN SESSIONS
      // ========================================================

      final dynamic rawSessions = data['login_sessions'] ??
          data['loginSessions'] ??
          data['sessions'] ??
          data['login_history'] ??
          data['loginHistory'];

      _assignMapList(
        source: rawSessions,
        target: loginSessions,
      );

      // ========================================================
      // FALLBACK:
      // RESPONSE ITSELF COULD BE A DEVICE
      // ========================================================

      if (registeredDevices.isEmpty) {
        final possibleDevice = _extractPossibleDevice(
          data,
        );

        if (possibleDevice != null) {
          registeredDevices.add(
            possibleDevice,
          );
        }
      }

      // ========================================================
      // FORCE GETX UPDATE
      // ========================================================

      deviceUser.refresh();

      registeredDevices.refresh();

      deviceHistory.refresh();

      loginSessions.refresh();

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint(
        '════════════════════════════════════════',
      );

      debugPrint(
        '✅ DEVICE INFORMATION PARSED',
      );

      debugPrint(
        '👤 USER:',
      );

      debugPrint(
        deviceUser.toString(),
      );

      debugPrint(
        '📱 DEVICES '
        '(${registeredDevices.length}):',
      );

      for (final device in registeredDevices) {
        debugPrint(
          device.toString(),
        );
      }

      debugPrint(
        '📜 HISTORY '
        '(${deviceHistory.length}):',
      );

      for (final history in deviceHistory) {
        debugPrint(
          history.toString(),
        );
      }

      debugPrint(
        '🔐 LOGIN SESSIONS '
        '(${loginSessions.length}):',
      );

      for (final session in loginSessions) {
        debugPrint(
          session.toString(),
        );
      }

      debugPrint(
        '════════════════════════════════════════',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '════════════════════════════════════════',
      );

      debugPrint(
        '❌ DEVICE INFORMATION ERROR',
      );

      debugPrint(
        e.toString(),
      );

      debugPrint(
        stackTrace.toString(),
      );

      debugPrint(
        '════════════════════════════════════════',
      );

      deviceError.value = e.toString().replaceFirst(
            'Exception: ',
            '',
          );

      deviceUser.clear();
      registeredDevices.clear();
      deviceHistory.clear();
      loginSessions.clear();
    } finally {
      if (!_isClosed) {
        isDeviceLoading.value = false;
      }
    }
  }

  // ============================================================
  // CONVERT RESPONSE VALUE INTO LIST<MAP>
  // ============================================================

  void _assignMapList({
    required dynamic source,
    required RxList<Map<String, dynamic>> target,
  }) {
    target.clear();

    if (source == null) {
      return;
    }

    // ==========================================================
    // DIRECT LIST
    //
    // [
    //   {...},
    //   {...}
    // ]
    // ==========================================================

    if (source is List) {
      for (final dynamic item in source) {
        if (item is Map) {
          target.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }

      return;
    }

    // ==========================================================
    // MAP
    //
    // {
    //    "rows": [...]
    // }
    //
    // OR:
    //
    // {
    //    "data": [...]
    // }
    // ==========================================================

    if (source is Map) {
      final map = Map<String, dynamic>.from(
        source,
      );

      final dynamic rows =
          map['rows'] ?? map['data'] ?? map['items'] ?? map['results'];

      if (rows is List) {
        for (final dynamic item in rows) {
          if (item is Map) {
            target.add(
              Map<String, dynamic>.from(
                item,
              ),
            );
          }
        }

        return;
      }

      // Single object.
      target.add(map);
    }
  }

  // ============================================================
  // CHECK WHETHER ROOT DATA LOOKS LIKE A DEVICE
  // ============================================================

  Map<String, dynamic>? _extractPossibleDevice(
    Map<String, dynamic> data,
  ) {
    const List<String> deviceKeys = [
      'device_id',
      'deviceId',
      'device_name',
      'deviceName',
      'device_model',
      'deviceModel',
      'platform',
      'os_version',
      'osVersion',
      'app_version',
      'appVersion',
      'status',
    ];

    final bool hasDeviceField = deviceKeys.any(
      (key) => data.containsKey(key),
    );

    if (!hasDeviceField) {
      return null;
    }

    return Map<String, dynamic>.from(
      data,
    );
  }

  // ============================================================
  // REFRESH DEVICE INFORMATION
  // ============================================================

  Future<void> refreshDeviceInfo() async {
    if (_isClosed) return;

    await fetchRegisteredDeviceInfo();
  }

  // ============================================================
  // PRIMARY DEVICE
  // ============================================================

  Map<String, dynamic>? get primaryDevice {
    if (registeredDevices.isEmpty) {
      return null;
    }

    for (final device in registeredDevices) {
      final String status =
          device['status']?.toString().trim().toUpperCase() ?? '';

      if (status == 'ACTIVE') {
        return device;
      }
    }

    return registeredDevices.first;
  }

  // ============================================================
  // HAS REGISTERED DEVICE
  // ============================================================

  bool get hasRegisteredDevice => registeredDevices.isNotEmpty;

  // ============================================================
  // ACTIVE DEVICE COUNT
  // ============================================================

  int get activeDeviceCount {
    return registeredDevices.where(
      (device) {
        final String status =
            device['status']?.toString().trim().toUpperCase() ?? '';

        return status == 'ACTIVE';
      },
    ).length;
  }

  // ============================================================
  // DEVICE USERNAME
  // ============================================================

  String get deviceUsername {
    return deviceUser['username']?.toString() ??
        deviceUser['email']?.toString() ??
        '';
  }

  // ============================================================
  // DEVICE USER NAME
  // ============================================================

  String get deviceUserName {
    return deviceUser['full_name']?.toString() ??
        deviceUser['name']?.toString() ??
        '';
  }

  // ============================================================
  // CLEAR DEVICE DATA
  // ============================================================

  void clearDeviceData() {
    deviceUser.clear();

    registeredDevices.clear();

    deviceHistory.clear();

    loginSessions.clear();

    deviceError.value = null;
  }

  // ============================================================
  // CLEAR EMPLOYEE DATA
  // ============================================================

  void clearEmployeeData() {
    employee.value = null;

    employeeHistory.clear();

    profileImageUrl.value = null;

    nameController.clear();

    emailController.clear();

    phoneController.clear();

    addressController.clear();

    clearDeviceData();
  }

  // ============================================================
  // ON CLOSE
  // ============================================================

  @override
  void onClose() {
    _isClosed = true;

    nameController.dispose();

    emailController.dispose();

    phoneController.dispose();

    addressController.dispose();

    super.onClose();
  }
}

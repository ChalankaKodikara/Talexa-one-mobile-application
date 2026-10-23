import 'package:corehris/auth/core/auth_interceptors.dart';
import 'package:corehris/auth/core/auth_session.dart';
import 'package:corehris/auth/core/dio_clients.dart';

import 'package:corehris/auth/service/master_auth_api.dart';
import 'package:corehris/auth/service/permission_api.dart';

import 'package:corehris/auth/tenant/attendance_api.dart';
import 'package:corehris/auth/tenant/claims_api.dart';
import 'package:corehris/auth/tenant/employee_api.dart';
import 'package:corehris/auth/tenant/holidays_api.dart';
import 'package:corehris/auth/tenant/leave_api.dart';
import 'package:corehris/auth/tenant/loan_api.dart';
import 'package:corehris/auth/tenant/notice_api.dart';
import 'package:corehris/auth/tenant/notification_api.dart';
import 'package:corehris/auth/tenant/overtime_api.dart';
import 'package:corehris/auth/tenant/payroll_api.dart';
import 'package:corehris/auth/tenant/performance_api.dart';
import 'package:corehris/auth/tenant/profile_api.dart';
import 'package:corehris/auth/tenant/timesheet_api.dart';

import 'package:dio/dio.dart';

class AuthService {
  // ============================================================
  // SINGLETON
  // ============================================================

  AuthService._internal() {
    // ==========================================================
    // DIO CLIENTS
    // ==========================================================

    _dio = DioClients(
      session: _session,
    );

    // ==========================================================
    // INTERCEPTORS
    // ==========================================================

    _interceptors = AuthInterceptors(
      authDio: _dio.authDio,
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    _interceptors.setup();

    // ==========================================================
    // MASTER AUTH API
    // ==========================================================

    _master = MasterAuthApi(
      authDio: _dio.authDio,
      session: _session,
    );

    // ==========================================================
    // PERMISSION API
    // ==========================================================

    _permission = PermissionApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    // ==========================================================
    // TENANT APIS
    // ==========================================================

    attendance = AttendanceApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    leave = LeaveApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    timesheet = TimesheetApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    loan = LoanApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    payroll = PayrollApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    performance = PerformanceApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    employee = EmployeeApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    claims = ClaimsApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    notice = NoticeApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    notification = NotificationApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    profile = ProfileApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );

    holidays = HolidaysApi();

    overtime = OvertimeApi(
      tenantDio: _dio.tenantDio,
      session: _session,
    );
  }

  static final AuthService instance = AuthService._internal();

  factory AuthService() => instance;

  // ============================================================
  // CORE
  // ============================================================

  late final DioClients _dio;

  final AuthSession _session = AuthSession();

  late final AuthInterceptors _interceptors;

  late final MasterAuthApi _master;

  late final PermissionApi _permission;

  // ============================================================
  // TENANT SERVICES
  // ============================================================

  late final AttendanceApi attendance;

  late final LeaveApi leave;

  late final TimesheetApi timesheet;

  late final LoanApi loan;

  late final PayrollApi payroll;

  late final PerformanceApi performance;

  late final EmployeeApi employee;

  late final ClaimsApi claims;

  late final NoticeApi notice;

  late final NotificationApi notification;

  late final ProfileApi profile;

  late final HolidaysApi holidays;

  late final OvertimeApi overtime;

  // ============================================================
  // SESSION GETTERS
  // ============================================================

  String? get currentApiBaseUrl => _session.apiBaseUrl;

  String? get currentUsername => _session.username;

  String? get currentSystemCode => _session.selectedSystemCode;

  String get currentEditor => (_session.username ?? '').trim();

  AttendanceApi get attendanceApi => attendance;

  AuthSession get session => _session;

  // ============================================================
  // DIO GETTERS
  // ============================================================

  Dio get tenantDio => _dio.tenantDio;

  Dio get authDio => _dio.authDio;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    await _session.initialize();

    await _dio.applyTenantBaseUrlFromSession();
  }

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  Future<bool> isLoggedIn() {
    return _session.isLoggedIn();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _session.clear();

    await _dio.applyTenantBaseUrlFromSession();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Response> login(
    String username,
    String password, {
    required String clientType,
    required String deviceId,
    required String deviceName,
    required String devicePlatform,
    required String deviceModel,
    required String osVersion,
    required String appVersion,
  }) async {
    final Response response = await _master.login(
      username,
      password,
      clientType: clientType,
      deviceId: deviceId,
      deviceName: deviceName,
      devicePlatform: devicePlatform,
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
    );

    if (response.statusCode == 200) {
      await _dio.applyTenantBaseUrlFromSession();

      try {
        await _permission.getPermission(
          username,
        );
      } catch (_) {
        // Permission failure must not block successful login.
      }
    }

    return response;
  }

  // ============================================================
  // LOGIN WITH PIN - BOOL VERSION
  // ============================================================

  Future<bool> loginWithPin(
    String pin, {
    required String username,
    required String clientType,
    required String deviceId,
    required String deviceName,
    required String devicePlatform,
    required String deviceModel,
    required String osVersion,
    required String appVersion,
  }) async {
    final bool ok = await _master.loginWithPin(
      pin,
      username: username,
      clientType: clientType,
      deviceId: deviceId,
      deviceName: deviceName,
      devicePlatform: devicePlatform,
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
    );

    if (ok) {
      await _dio.applyTenantBaseUrlFromSession();

      try {
        await _permission.getPermission(
          username,
        );
      } catch (_) {
        // Permission failure must not block PIN login.
      }
    }

    return ok;
  }

  // ============================================================
  // LOGIN WITH PIN - RESPONSE VERSION
  // ============================================================

  Future<Response> loginWithPinApi(
    String username,
    String pin, {
    required String clientType,
    required String deviceId,
    required String deviceName,
    required String devicePlatform,
    required String deviceModel,
    required String osVersion,
    required String appVersion,
  }) async {
    final Response response = await _master.loginWithPinApi(
      pin,
      username: username,
      clientType: clientType,
      deviceId: deviceId,
      deviceName: deviceName,
      devicePlatform: devicePlatform,
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
    );

    if (response.statusCode == 200) {
      await _dio.applyTenantBaseUrlFromSession();

      try {
        await _permission.getPermission(
          username,
        );
      } catch (_) {
        // Permission failure must not block PIN login.
      }
    }

    return response;
  }

  // ============================================================
  // FORGOT PASSWORD - GET OTP
  // ============================================================

  Future<Response> forgotPasswordGetOtp(
    String email,
  ) async {
    return await _master.forgotPasswordOtpGet(
      email,
    );
  }

  // ============================================================
  // FORGOT PASSWORD - VERIFY OTP
  // ============================================================

  Future<Response> forgotPasswordVerifyOtp(
    String email,
    String otp,
  ) async {
    return await _master.forgotPasswordOtpSend(
      email,
      otp,
    );
  }

  // ============================================================
  // FORGOT PASSWORD - SET NEW PASSWORD
  // ============================================================

  Future<Response> forgotPasswordSetNew(
    String email,
    String confirmPassword,
  ) async {
    return await _master.forgotPasswordSetNew(
      email,
      confirmPassword,
    );
  }

  // ============================================================
  // LOGIN 2FA
  // ============================================================

  Future<Response> login2FAOtp(
    String email,
    String otp,
  ) async {
    final Response response = await _master.login2FAOtp(
      email,
      otp,
    );

    if (response.statusCode == 200) {
      await _dio.applyTenantBaseUrlFromSession();
    }

    return response;
  }

  // ============================================================
  // SWITCH SYSTEM
  // ============================================================

  Future<void> switchSystem(
    String systemCode,
  ) async {
    await _session.selectSystem(
      systemCode,
    );

    await _dio.applyTenantBaseUrlFromSession();
  }

  // ============================================================
  // PIN SETUP
  // ============================================================

  Future<Map<String, dynamic>> setupPin(
    String pin,
  ) {
    return _master.setupPin(
      pin,
    );
  }

  // ============================================================
  // ENABLE 2FA
  // ============================================================

  Future<void> enableTwoFactorAuth(
    String password,
  ) {
    return _master.enableTwoFactorAuth(
      password,
    );
  }

  // ============================================================
  // CONFIRM 2FA
  // ============================================================

  Future<void> confirmEnableTwoFactorAuth(
    String code,
  ) {
    return _master.confirmEnableTwoFactorAuth(
      code,
    );
  }

  // ============================================================
  // DISABLE 2FA
  // ============================================================

  Future<void> disableTwoFactorAuth(
    String code,
  ) {
    return _master.disableTwoFactorAuth(
      code,
    );
  }

  // ============================================================
  // GET 2FA STATUS
  // ============================================================

  Future<bool> get2FAStatus() async {
    return await _master.get2FAStatus();
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> resetPassword(
    String currentPassword,
    String confirmPassword,
  ) async {
    await _session.initialize();

    await _master.resetPassword(
      currentPassword,
      confirmPassword,
    );
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  Future<List<int>> getPermission(
    String email,
  ) {
    return _permission.getPermission(
      email,
    );
  }

  // ============================================================
  // GET DEVICE INFO
  // ============================================================
  Future<Map<String, dynamic>?> fetchDeviceLogs(
    String username,
  ) async {
    final Map<String, dynamic>? data = await _master.fetchDeviceLogs(
      username,
    );

    return data;
  }
}

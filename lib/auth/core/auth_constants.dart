class AuthConstants {
  // =========================
  // MASTER (Fixed)
  // =========================
  static const String kMasterBaseUrl =
      'https://back-master-admin.talentfort.live';

  /// default system after login (can be changed from Landing)
  static const String kPreferredSystemCode = 'HRMS01';

  // MASTER PATHS
  static const String kLoginPath = '/api/auth/logintenant';
  static const String kVerifyLogin2FAOtpPath = '/api/auth/tenant/verify-otp';
  static const String kRefreshPath = '/api/auth/tenant/refresh-token';

  static const String kEnableTwoFactorAuthPath = '/api/auth/tenant/enable-2fa';
  static const String kConfirmEnableTwoFactorAuthPath =
      '/api/auth/tenant/confirm-enable-2fa';
  static const String kDisableTwoFactorAuthPath =
      '/api/auth/tenant/disable-2fa';
  static const String kGet2FAStatusPath = '/api/auth/tenant/2fa-status';
  static const String kDeviceLogPath = '/api/mobile-devices/username';

  //forget password
  static const String kForgotPasswordOTPGetPath = '/api/auth/forgot-password';
  static const String kForgotPasswordOTPSendPath = '/api/auth/verify-reset-otp';
  static const String kForgotPasswordSetNewPath = '/api/auth/set-new-password';
  static const String kResetPasswordPath = '/api/auth/change-password';

  // =========================
  // TENANT (Dynamic baseUrl)
  // =========================
  static const String kGetPermissionPath =
      '/v1/hris/user/getUserByIDORName-mobile/';
  static const String kLoginWithPinPath = '/api/auth/login-pin';
  static const String kSetupPinPath = '/api/auth/setup-pin';

  // =========================
  // STORAGE KEYS (Tokens/User)
  // =========================
  static const String kKeyAccessToken = 'accessToken';
  static const String kKeyRefreshToken = 'refreshToken';
  static const String kKeyUsername = 'username';
  static const String kKeyOwnSupervisorId = 'own_supervisor_id';
  static const String kKeySupervisorId = 'supervisor_id';

  static const String kKeyUserId = 'user_id';
  static const String kKeyEmployeeNo = 'employee_no';
  static const String kKeyRoleId = 'role_id';
  static const String kKeyRoleName = 'role_name';
  static const String kKeyRoleDescription = 'role_description';
  static const String kKeyEmployeeFullName = 'employee_fullname';
  static const String kKeyCallingName = 'employee_calling_name';
  static const String kKeyPersonalEmail = 'personal_email';
  static const String kOrganizationId = 'organization_id';

  // =========================
  // ✅ SYSTEM SWITCHING KEYS
  // =========================

  /// full systems list from login response
  static const String kKeySystemsJson = 'systems_json';

  /// selected system code (HRMS01, FMS123...)
  static const String kKeySelectedSystemCode = 'selected_system_code';

  /// selected system backend_url (dynamic tenant base url)
  static const String kKeyTenantApiBaseUrl = 'tenant_api_base_url';

  /// selected system frontend_url (optional)
  static const String kKeyTenantFrontendUrl = 'tenant_frontend_url';

  // =========================
  // ✅ MASTER SESSION KEYS (if you want to keep master separate)
  // =========================
  static const String kKeyMasterAccessToken = 'master_access_token';
  static const String kKeyMasterRefreshToken = 'master_refresh_token';

  // =========================
  // PERMISSIONS
  // =========================
  static const String kKeyPermissions = 'user_permissions';
  static const String kKeyUserFullObject = 'user_full_object';
}

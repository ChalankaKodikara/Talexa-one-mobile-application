import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_constants.dart';
import 'url_helpers.dart';

class AuthSession {
  /// ===============================
  /// TOKENS / USER
  /// ===============================
  String? accessToken;
  String? refreshToken;

  String? username;
  String? email;
  String? employeeNo;
  String? fullName;

  String? apiBaseUrl;

  String? masterAccessToken;
  String? masterRefreshToken;

  /// ===============================
  /// TENANT SYSTEM
  /// ===============================
  String? selectedSystemCode;
  List<Map<String, dynamic>> systems = [];

  bool _initialized = false;

  /// ===============================
  /// INIT SESSION
  /// ===============================
  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    accessToken = prefs.getString(AuthConstants.kKeyAccessToken);
    refreshToken = prefs.getString(AuthConstants.kKeyRefreshToken);

    username = prefs.getString(AuthConstants.kKeyUsername);
    employeeNo = prefs.getString(AuthConstants.kKeyEmployeeNo);
    fullName = prefs.getString(AuthConstants.kKeyEmployeeFullName);
    email = prefs.getString(AuthConstants.kKeyPersonalEmail);

    masterAccessToken = prefs.getString(AuthConstants.kKeyMasterAccessToken);
    masterRefreshToken = prefs.getString(AuthConstants.kKeyMasterRefreshToken);

    final systemsRaw = prefs.getString(AuthConstants.kKeySystemsJson) ?? '';
    systems = _decodeSystems(systemsRaw);

    selectedSystemCode = prefs.getString(AuthConstants.kKeySelectedSystemCode);

    final savedBase = prefs.getString(AuthConstants.kKeyTenantApiBaseUrl) ?? '';
    if (savedBase.isNotEmpty) {
      apiBaseUrl = UrlHelpers.normalizeBaseUrl(savedBase);
    }

    _initialized = true;
  }

  /// ===============================
  /// LOGIN CHECK
  /// ===============================
  Future<bool> isLoggedIn() async {
    await initialize();
    return (accessToken ?? '').isNotEmpty;
  }

  /// ===============================
  /// TOKEN SAVE
  /// ===============================
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = token;
    await prefs.setString(AuthConstants.kKeyAccessToken, token);
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    refreshToken = token;
    await prefs.setString(AuthConstants.kKeyRefreshToken, token);
  }

  /// ===============================
  /// MASTER TOKENS
  /// ===============================
  Future<void> saveMasterTokens({
    String? accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if ((accessToken ?? '').isNotEmpty) {
      masterAccessToken = accessToken;
      await prefs.setString(
        AuthConstants.kKeyMasterAccessToken,
        accessToken!,
      );
    }

    if ((refreshToken ?? '').isNotEmpty) {
      masterRefreshToken = refreshToken;
      await prefs.setString(
        AuthConstants.kKeyMasterRefreshToken,
        refreshToken!,
      );
    }
  }

  /// ===============================
  /// SAVE USER FROM MASTER LOGIN
  /// ===============================
  Future<void> saveUserFromMaster(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    username = (user['username'] ?? user['email'] ?? '').toString();
    employeeNo = (user['employee_no'] ?? '').toString();
    fullName = (user['employee_fullname'] ?? '').toString();
    email = (user['email'] ?? '').toString();

    await prefs.setString(
      AuthConstants.kKeyUsername,
      username ?? '',
    );

    await prefs.setInt(
      AuthConstants.kKeyUserId,
      int.tryParse('${user['id']}') ?? 0,
    );

    await prefs.setString(
      AuthConstants.kKeyEmployeeNo,
      employeeNo ?? '',
    );

    await prefs.setString(
      AuthConstants.kKeyEmployeeFullName,
      fullName ?? '',
    );

    await prefs.setInt(
      AuthConstants.kKeySupervisorId,
      int.tryParse('${user['supervisor_id']}') ?? 0,
    );

    await prefs.setString(
      AuthConstants.kKeyPersonalEmail,
      email ?? '',
    );

    await prefs.setInt(
      AuthConstants.kOrganizationId,
      int.tryParse('${user['organization_id']}') ?? 0,
    );
  }

  /// ===============================
  /// SYSTEMS
  /// ===============================
  Future<void> saveSystems(List<dynamic> systemsList) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      AuthConstants.kKeySystemsJson,
      jsonEncode(systemsList),
    );

    systems = systemsList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _decodeSystems(String raw) {
    if (raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  Map<String, dynamic>? findSystemByCode(String code) {
    for (final s in systems) {
      if ((s['system_code'] ?? '').toString() == code) {
        return s;
      }
    }
    return null;
  }

  /// ===============================
  /// SELECT SYSTEM
  /// ===============================
  Future<void> selectSystem(String systemCode) async {
    final prefs = await SharedPreferences.getInstance();

    await initialize();

    final sys = findSystemByCode(systemCode);
    if (sys == null) {
      throw Exception("System not found");
    }

    final backend = (sys['backend_url'] ?? '').toString().trim();
    if (backend.isEmpty) {
      throw Exception("Backend URL missing for system");
    }

    selectedSystemCode = systemCode;
    apiBaseUrl = UrlHelpers.normalizeBaseUrl(backend);

    await prefs.setString(
      AuthConstants.kKeySelectedSystemCode,
      systemCode,
    );

    await prefs.setString(
      AuthConstants.kKeyTenantApiBaseUrl,
      apiBaseUrl!,
    );

    final fe = (sys['frontend_url'] ?? '').toString();
    if (fe.isNotEmpty) {
      await prefs.setString(
        AuthConstants.kKeyTenantFrontendUrl,
        fe,
      );
    }

    await prefs.reload();
  }

  /// ===============================
  /// DEFAULT SYSTEM
  /// ===============================
  Future<void> selectDefaultSystem({
    String? preferredSystemCode,
  }) async {
    await initialize();

    if ((preferredSystemCode ?? '').isNotEmpty) {
      final sys = findSystemByCode(preferredSystemCode!);

      if (sys != null) {
        final backend = (sys['backend_url'] ?? '').toString().trim();
        if (backend.isNotEmpty) {
          await selectSystem(preferredSystemCode);
          return;
        }
      }
    }

    for (final s in systems) {
      final code = (s['system_code'] ?? '').toString();
      final backend = (s['backend_url'] ?? '').toString().trim();

      if (code.isNotEmpty && backend.isNotEmpty) {
        await selectSystem(code);
        return;
      }
    }
  }

  /// ===============================
  /// SAVE USER FROM PERMISSION API
  /// ===============================
  Future<void> saveUserFromPermission(
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final parsedUsername = (user['username'] ?? user['email'] ?? '').toString();

    username = parsedUsername;
    employeeNo = (user['employee_no'] ?? '').toString();
    fullName = (user['employee_fullname'] ?? '').toString();
    email = (user['personal_email'] ?? user['email'] ?? '').toString();

    await prefs.setString(
      AuthConstants.kKeyUserFullObject,
      jsonEncode(user),
    );

    await prefs.setInt(
      AuthConstants.kKeyUserId,
      int.tryParse('${user['id']}') ?? 0,
    );

    await prefs.setString(
      AuthConstants.kKeyEmployeeNo,
      employeeNo ?? '',
    );

    await prefs.setString(
      AuthConstants.kKeyUsername,
      parsedUsername,
    );

    await prefs.setInt(
      AuthConstants.kKeyOwnSupervisorId,
      int.tryParse('${user['own_supervisor_id']}') ?? 0,
    );

    await prefs.setInt(
      AuthConstants.kKeySupervisorId,
      int.tryParse('${user['supervisor_id']}') ?? 0,
    );

    await prefs.setInt(
      AuthConstants.kKeyRoleId,
      int.tryParse('${user['role_id']}') ?? 0,
    );

    await prefs.setString(
      AuthConstants.kKeyRoleName,
      (user['role_name'] ?? '').toString(),
    );

    await prefs.setString(
      AuthConstants.kKeyRoleDescription,
      (user['role_description'] ?? '').toString(),
    );

    await prefs.setString(
      AuthConstants.kKeyEmployeeFullName,
      fullName ?? '',
    );

    await prefs.setString(
      AuthConstants.kKeyCallingName,
      (user['employee_calling_name'] ?? '').toString(),
    );

    await prefs.setString(
      AuthConstants.kKeyPersonalEmail,
      email ?? '',
    );

    await prefs.setInt(
      AuthConstants.kOrganizationId,
      int.tryParse('${user['organization_id']}') ?? 0,
    );
  }

  /// ===============================
  /// PERMISSIONS
  /// ===============================
  Future<void> savePermissions(List<int> permissions) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      AuthConstants.kKeyPermissions,
      jsonEncode(permissions),
    );
  }

  Future<List<int>> readPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(AuthConstants.kKeyPermissions);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e != 0)
            .toList();
      }
    } catch (_) {}

    return [];
  }

  /// ===============================
  /// SAVE PERMISSION API RESPONSE
  /// ===============================
  Future<void> savePermissionResponse(
    Map<String, dynamic> response,
  ) async {
    if (response['success'] != true) {
      throw Exception("Permission API failed");
    }

    final data = Map<String, dynamic>.from(response['data'] ?? {});
    final user = Map<String, dynamic>.from(data['user'] ?? {});
    final permissionsRaw = data['permissions'] ?? [];

    await saveUserFromPermission(user);

    final permissions = permissionsRaw is List
        ? permissionsRaw
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e != 0)
            .toList()
        : <int>[];

    await savePermissions(permissions);
  }

  /// ===============================
  /// HELPERS
  /// ===============================
  Future<String?> getEmployeeNo() async {
    await initialize();
    return employeeNo;
  }

  Future<String?> getEmail() async {
    await initialize();
    return email;
  }

  Future<String?> getUsername() async {
    await initialize();
    return username;
  }

  Future<String?> getFullName() async {
    await initialize();
    return fullName;
  }

  /// ===============================
  /// LOGOUT / CLEAR SESSION
  /// ===============================
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    accessToken = null;
    refreshToken = null;
    username = null;
    employeeNo = null;
    fullName = null;
    email = null;

    masterAccessToken = null;
    masterRefreshToken = null;

    apiBaseUrl = null;
    selectedSystemCode = null;

    systems = [];

    await prefs.clear();
    await prefs.reload();

    _initialized = false;
  }
}

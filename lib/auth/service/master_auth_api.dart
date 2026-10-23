import 'package:dio/dio.dart';

import '../core/auth_constants.dart';
import '../core/auth_session.dart';

class MasterAuthApi {
  final Dio authDio;
  final AuthSession session;

  MasterAuthApi({
    required this.authDio,
    required this.session,
  });

  // =========================================================
  // DEVICE HEADERS
  // =========================================================

  Map<String, dynamic> _buildDeviceHeaders({
    required String clientType,
    required String deviceId,
    required String deviceName,
    required String devicePlatform,
    required String deviceModel,
    required String osVersion,
    required String appVersion,
  }) {
    return {
      'x-client-type': clientType.trim(),
      'x-device-id': deviceId.trim(),
      'x-device-name': deviceName.trim(),
      'x-device-platform': devicePlatform.trim(),
      'x-device-model': deviceModel.trim(),
      'x-os-version': osVersion.trim(),
      'x-app-version': appVersion.trim(),
      'Content-Type': 'application/json',
    };
  }

  // =========================================================
  // LOGIN
  // =========================================================

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
    try {
      final Response res = await authDio.post(
        AuthConstants.kLoginPath,

        // =====================================================
        // LOGIN DATA IN BODY
        // =====================================================

        data: {
          'email': username.trim(),
          'password': password,
        },

        // =====================================================
        // DEVICE DATA ONLY IN HEADERS
        // =====================================================

        options: Options(
          headers: _buildDeviceHeaders(
            clientType: clientType,
            deviceId: deviceId,
            deviceName: deviceName,
            devicePlatform: devicePlatform,
            deviceModel: deviceModel,
            osVersion: osVersion,
            appVersion: appVersion,
          ),
        ),
      );

      await _handleLoginSuccess(res);

      return res;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(
              path: AuthConstants.kLoginPath,
            ),
            statusCode: 500,
            data: {
              'success': false,
              'message': e.message ?? 'Server error',
            },
          );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(
          path: AuthConstants.kLoginPath,
        ),
        statusCode: 500,
        data: {
          'success': false,
          'message': e.toString(),
        },
      );
    }
  }

  // =========================================================
  // SETUP PIN
  // =========================================================

  Future<Map<String, dynamic>> setupPin(
    String pin,
  ) async {
    try {
      final Response res = await authDio.post(
        AuthConstants.kSetupPinPath,
        data: {
          'pin': pin,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.data is Map<String, dynamic>) {
          return res.data as Map<String, dynamic>;
        }

        if (res.data is Map) {
          return Map<String, dynamic>.from(
            res.data as Map,
          );
        }

        return {
          'success': true,
          'message': 'PIN setup successful',
        };
      }

      return {
        'success': false,
        'message': 'Unexpected server response (${res.statusCode})',
      };
    } on DioException catch (e) {
      final dynamic body = e.response?.data;

      if (body is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          body,
        );

        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to set up PIN',
        };
      }

      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // =========================================================
  // LOGIN WITH PIN - BOOL VERSION
  // =========================================================

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
    try {
      final Response res = await loginWithPinApi(
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

      if (res.statusCode != 200 || res.data is! Map) {
        return false;
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        res.data as Map,
      );

      if (data.containsKey('success') && data['success'] != true) {
        return false;
      }

      final dynamic accessToken = data['accessToken'];

      return accessToken != null && accessToken.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // LOGIN WITH PIN - RESPONSE VERSION
  // =========================================================

  Future<Response> loginWithPinApi(
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
    try {
      final Response res = await authDio.post(
        AuthConstants.kLoginWithPinPath,

        // =====================================================
        // PIN LOGIN DATA IN BODY
        // =====================================================

        data: {
          'email': username.trim(),
          'pin': pin.trim(),
        },

        // =====================================================
        // DEVICE DATA ONLY IN HEADERS
        // =====================================================

        options: Options(
          headers: _buildDeviceHeaders(
            clientType: clientType,
            deviceId: deviceId,
            deviceName: deviceName,
            devicePlatform: devicePlatform,
            deviceModel: deviceModel,
            osVersion: osVersion,
            appVersion: appVersion,
          ),
        ),
      );

      if (res.statusCode == 200 && res.data is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          res.data as Map,
        );

        if (!data.containsKey('success') || data['success'] == true) {
          await _handleLoginSuccess(res);
        }
      }

      return res;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(
              path: AuthConstants.kLoginWithPinPath,
            ),
            statusCode: 500,
            data: {
              'success': false,
              'message': e.message ?? 'Server error',
            },
          );
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(
          path: AuthConstants.kLoginWithPinPath,
        ),
        statusCode: 500,
        data: {
          'success': false,
          'message': e.toString(),
        },
      );
    }
  }

  // =========================================================
  // FORGOT PASSWORD - GET OTP
  // =========================================================

  Future<Response> forgotPasswordOtpGet(
    String email,
  ) async {
    try {
      final Response res = await authDio.post(
        AuthConstants.kForgotPasswordOTPGetPath,
        data: {
          'email': email,
        },
      );

      return res;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(
              path: AuthConstants.kForgotPasswordOTPGetPath,
            ),
            statusCode: 500,
            data: {
              'success': false,
              'message': e.message ?? 'Server error',
            },
          );
    }
  }

  // =========================================================
  // FORGOT PASSWORD - VERIFY OTP
  // =========================================================

  Future<Response> forgotPasswordOtpSend(
    String email,
    String otp,
  ) async {
    try {
      final Response res = await authDio.post(
        AuthConstants.kForgotPasswordOTPSendPath,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      return res;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(
              path: AuthConstants.kForgotPasswordOTPSendPath,
            ),
            statusCode: 500,
            data: {
              'success': false,
              'message': e.message ?? 'Server error',
            },
          );
    }
  }

  // =========================================================
  // FORGOT PASSWORD - SET NEW PASSWORD
  // =========================================================

  Future<Response> forgotPasswordSetNew(
    String email,
    String confirmPassword,
  ) async {
    try {
      final Response res = await authDio.post(
        AuthConstants.kForgotPasswordSetNewPath,
        data: {
          'email': email,
          'newPassword': confirmPassword,
        },
      );

      return res;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(
              path: AuthConstants.kForgotPasswordSetNewPath,
            ),
            statusCode: 500,
            data: {
              'success': false,
              'message': e.message ?? 'Server error',
            },
          );
    }
  }

  // =========================================================
  // VERIFY LOGIN 2FA OTP
  // =========================================================

  Future<Response> login2FAOtp(
    String email,
    String otp,
  ) async {
    try {
      final Response res = await authDio.post(
        AuthConstants.kVerifyLogin2FAOtpPath,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (res.statusCode == 200 && res.data is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          res.data as Map,
        );

        if (!data.containsKey('success') || data['success'] == true) {
          await _handleLoginSuccess(res);
        }
      }

      return res;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }

      return Response(
        requestOptions: RequestOptions(
          path: AuthConstants.kVerifyLogin2FAOtpPath,
        ),
        statusCode: 503,
        data: {
          'success': false,
          'message': 'Network error. Please check your connection.',
        },
      );
    }
  }

  // =========================================================
  // REFRESH SESSION
  // =========================================================

  Future<void> refreshSession() async {
    try {
      await session.initialize();

      final String refresh = session.refreshToken?.trim() ?? '';

      if (refresh.isEmpty) {
        throw Exception(
          'No refresh token available',
        );
      }

      final Response res = await authDio.post(
        AuthConstants.kRefreshPath,
        data: {
          'refreshToken': refresh,
        },
        options: Options(
          headers: {
            'Authorization': '',
          },
        ),
      );

      if (res.statusCode == 200 && res.data is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          res.data as Map,
        );

        final dynamic accessToken = data['accessToken'];

        if (accessToken != null && accessToken.toString().trim().isNotEmpty) {
          await session.saveAccessToken(
            accessToken.toString(),
          );
        }

        final dynamic refreshToken = data['refreshToken'];

        if (refreshToken != null && refreshToken.toString().trim().isNotEmpty) {
          await session.saveRefreshToken(
            refreshToken.toString(),
          );
        }

        return;
      }

      throw Exception(
        'Refresh failed',
      );
    } catch (e) {
      await session.clear();

      throw Exception(
        'Session refresh failed: $e',
      );
    }
  }

  // =========================================================
  // ENABLE 2FA
  // =========================================================

  Future<void> enableTwoFactorAuth(
    String password,
  ) async {
    try {
      final Response res = await authDio.post(
        AuthConstants.kEnableTwoFactorAuthPath,
        data: {
          'password': password,
        },
      );

      if (res.statusCode != 200) {
        final dynamic message =
            res.data is Map ? (res.data as Map)['error'] : null;

        throw Exception(
          message ?? 'Failed to enable 2FA',
        );
      }
    } catch (e) {
      throw Exception(
        'Failed to enable 2FA: $e',
      );
    }
  }

  // =========================================================
  // CONFIRM ENABLE 2FA
  // =========================================================

  Future<void> confirmEnableTwoFactorAuth(
    String code,
  ) async {
    try {
      final Response res = await authDio.post(
        AuthConstants.kConfirmEnableTwoFactorAuthPath,
        data: {
          'otp': code,
        },
      );

      if (res.statusCode != 200) {
        final dynamic message =
            res.data is Map ? (res.data as Map)['error'] : null;

        throw Exception(
          message ?? 'Failed to confirm 2FA',
        );
      }
    } catch (e) {
      throw Exception(
        'Failed to confirm 2FA: $e',
      );
    }
  }

  // =========================================================
  // DISABLE 2FA
  // =========================================================

  Future<void> disableTwoFactorAuth(
    String code,
  ) async {
    try {
      final Response res = await authDio.post(
        AuthConstants.kDisableTwoFactorAuthPath,
        data: {
          'password': code,
        },
      );

      if (res.statusCode != 200) {
        final dynamic message =
            res.data is Map ? (res.data as Map)['error'] : null;

        throw Exception(
          message ?? 'Failed to disable 2FA',
        );
      }
    } catch (e) {
      throw Exception(
        'Failed to disable 2FA: $e',
      );
    }
  }

  // =========================================================
  // GET 2FA STATUS
  // =========================================================

  Future<bool> get2FAStatus() async {
    try {
      final Response res = await authDio.get(
        AuthConstants.kGet2FAStatusPath,
      );

      if (res.statusCode != 200 || res.data == null) {
        throw Exception(
          'Invalid response',
        );
      }

      final dynamic data = res.data;

      if (data is Map &&
          data['data'] is Map &&
          (data['data'] as Map)['two_factor_enabled'] != null) {
        final dynamic value = (data['data'] as Map)['two_factor_enabled'];

        return value == true || value == 1 || value.toString() == '1';
      }

      if (data is Map && data['two_factor_enabled'] != null) {
        final dynamic value = data['two_factor_enabled'];

        return value == true || value == 1 || value.toString() == '1';
      }

      if (data is Map && data['data'] is bool) {
        return data['data'] == true;
      }

      return false;
    } catch (e) {
      throw Exception(
        'Failed to get 2FA status: $e',
      );
    }
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  Future<void> resetPassword(
    String currentPassword,
    String newPassword,
  ) async {
    final Response res = await authDio.put(
      AuthConstants.kResetPasswordPath,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to reset password',
      );
    }
  }

  // =========================================================
  // INTERNAL LOGIN SUCCESS HANDLER
  // =========================================================

  Future<void> _handleLoginSuccess(
    Response res,
  ) async {
    if (res.statusCode != 200 || res.data is! Map) {
      return;
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      res.data as Map,
    );

    if (data.containsKey('success') && data['success'] == false) {
      return;
    }

    final dynamic accessToken = data['accessToken'];

    if (accessToken != null && accessToken.toString().trim().isNotEmpty) {
      await session.saveAccessToken(
        accessToken.toString(),
      );
    }

    final dynamic refreshToken = data['refreshToken'];

    if (refreshToken != null && refreshToken.toString().trim().isNotEmpty) {
      await session.saveRefreshToken(
        refreshToken.toString(),
      );
    }

    if (data['user'] is Map) {
      await session.saveUserFromMaster(
        Map<String, dynamic>.from(
          data['user'] as Map,
        ),
      );
    }

    if (data['systems'] is List) {
      await session.saveSystems(
        List<dynamic>.from(
          data['systems'] as List,
        ),
      );
    }

    await session.selectDefaultSystem(
      preferredSystemCode: AuthConstants.kPreferredSystemCode,
    );
  }

  // =========================================================
  //  get device log
  // =========================================================
  Future<Map<String, dynamic>?> fetchDeviceLogs(
    String username,
  ) async {
    try {
      final Response res = await authDio.get(
        '${AuthConstants.kDeviceLogPath}/$username',
      );

      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(
          res.data as Map,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

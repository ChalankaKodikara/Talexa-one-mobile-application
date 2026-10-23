import 'package:corehris/auth/core/auth_constants.dart';
import 'package:corehris/auth/core/auth_session.dart';
import 'package:dio/dio.dart';

class DioClients {
  final AuthSession session;

  DioClients({required this.session}) {
    // ✅ Attach interceptors once
    authDio.interceptors
        .add(_AuthHeaderInterceptor(session, useMasterToken: true));
    tenantDio.interceptors
        .add(_AuthHeaderInterceptor(session, useMasterToken: false));
  }

  /// ✅ MASTER DIO (fixed baseUrl)
  late final Dio authDio = Dio(
    BaseOptions(
      baseUrl: AuthConstants.kMasterBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// ✅ TENANT DIO (dynamic baseUrl)
  late final Dio tenantDio = Dio(
    BaseOptions(
      baseUrl: '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// ✅ Call this after login OR after system switch
  Future<void> applyTenantBaseUrlFromSession() async {
    await session.initialize();
    final base = (session.apiBaseUrl ?? '').trim();
    tenantDio.options.baseUrl = base; // dynamic backend_url
  }
}

/// =========================================================
/// ✅ Interceptor to add Authorization token to every request
/// =========================================================
class _AuthHeaderInterceptor extends Interceptor {
  final AuthSession session;
  final bool useMasterToken;

  _AuthHeaderInterceptor(this.session, {required this.useMasterToken});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    await session.initialize();

    final token = (useMasterToken
            ? (session.masterAccessToken ?? '')
            : (session.accessToken ?? ''))
        .trim();

    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // keep content-type default set in BaseOptions, but safe:
    options.headers['Content-Type'] ??= 'application/json';
    options.headers['Accept'] ??= 'application/json';

    handler.next(options);
  }
}

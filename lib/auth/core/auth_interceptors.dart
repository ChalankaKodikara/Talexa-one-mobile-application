import 'dart:async';
import 'package:corehris/utils/api_error_handler.dart';
import 'package:dio/dio.dart';
import '../core/auth_constants.dart';
import 'auth_session.dart';

class AuthInterceptors {
  final Dio authDio;
  final Dio tenantDio;
  final AuthSession session;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  AuthInterceptors({
    required this.authDio,
    required this.tenantDio,
    required this.session,
  });

  void setup() {
    _setupAuth();
    _setupTenant();
  }

  // ✅ MASTER (authDio) - attach ONLY access token (if exists)
  void _setupAuth() {
    authDio.interceptors.clear();
    authDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          await session.initialize();

          // ✅ pass ONLY access token
          if ((session.accessToken ?? '').isNotEmpty) {
            o.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }

          h.next(o);
        },
        onError: (e, h) async {
          final status = e.response?.statusCode ?? 0;
          final alreadyRetried = e.requestOptions.extra['__retried__'] == true;

          // ✅ avoid infinite loop: don't try refresh if refresh endpoint itself fails
          final isRefreshCall =
              e.requestOptions.path.contains(AuthConstants.kRefreshPath);

          if (status == 401 &&
              !alreadyRetried &&
              !isRefreshCall &&
              (session.refreshToken ?? '').isNotEmpty) {
            try {
              await _refreshToken();
              final res = await _retry(authDio, e.requestOptions);
              return h.resolve(res);
            } catch (_) {
              await session.clear();
              return h.next(ApiErrorHandler.normalizeDioException(e));
            }
          }

          h.next(ApiErrorHandler.normalizeDioException(e));
        },
      ),
    );
  }

  // ✅ TENANT (tenantDio) - attach ONLY access token (if exists)
  void _setupTenant() {
    tenantDio.interceptors.clear();
    tenantDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          await session.initialize();

          // ✅ ensure tenant baseUrl ready
          if ((session.apiBaseUrl ?? '').isNotEmpty &&
              tenantDio.options.baseUrl.trim().isEmpty) {
            tenantDio.options.baseUrl = session.apiBaseUrl!;
          }

          // ✅ pass ONLY access token
          if ((session.accessToken ?? '').isNotEmpty) {
            o.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }

          h.next(o);
        },
        onError: (e, h) async {
          final status = e.response?.statusCode ?? 0;
          final alreadyRetried = e.requestOptions.extra['__retried__'] == true;

          // ✅ avoid infinite loop: don't try refresh if refresh endpoint itself fails
          final isRefreshCall =
              e.requestOptions.path.contains(AuthConstants.kRefreshPath);

          if (status == 401 &&
              !alreadyRetried &&
              !isRefreshCall &&
              (session.refreshToken ?? '').isNotEmpty) {
            try {
              await _refreshToken();
              final res = await _retry(tenantDio, e.requestOptions);
              return h.resolve(res);
            } catch (_) {
              await session.clear();
              return h.next(ApiErrorHandler.normalizeDioException(e));
            }
          }

          h.next(ApiErrorHandler.normalizeDioException(e));
        },
      ),
    );
  }

  // ✅ Refresh call uses refreshToken (NOT in normal headers)
  Future<void> _refreshToken() async {
    await session.initialize();

    if (_isRefreshing) {
      await _refreshCompleter?.future;
      return;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final refresh = session.refreshToken ?? '';
      if (refresh.isEmpty) throw Exception('Missing refresh token');

      // ✅ call refresh endpoint (send refresh token in BODY as your backend expects)
      final res = await authDio.post(
        AuthConstants.kRefreshPath,
        data: {'refreshToken': refresh},
        options: Options(
          // ✅ important: do NOT attach Authorization here unless your backend needs it
          headers: {'Authorization': ''},
        ),
      );

      if (res.statusCode == 200 &&
          res.data is Map &&
          res.data['accessToken'] != null) {
        await session.saveAccessToken(res.data['accessToken'].toString());

        // ✅ refresh rotation (if backend returns new refreshToken)
        if (res.data['refreshToken'] != null) {
          await session.saveRefreshToken(res.data['refreshToken'].toString());
        }

        _refreshCompleter?.complete();
      } else {
        throw Exception('Refresh failed');
      }
    } catch (err) {
      _refreshCompleter?.completeError(err);
      rethrow;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // ✅ retry original request with NEW access token only
  Future<Response<dynamic>> _retry(Dio client, RequestOptions ro) async {
    await session.initialize();

    // ensure baseUrl for tenant
    if (client == tenantDio) {
      if ((session.apiBaseUrl ?? '').isEmpty) {
        throw Exception('Tenant baseUrl not ready');
      }
      tenantDio.options.baseUrl = session.apiBaseUrl!;
    }

    final extra = Map<String, dynamic>.from(ro.extra);
    extra['__retried__'] = true;

    final headers = Map<String, dynamic>.from(ro.headers);

    // ✅ override with latest access token ONLY
    if ((session.accessToken ?? '').isNotEmpty) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    } else {
      headers.remove('Authorization');
    }

    final options = Options(
      method: ro.method,
      headers: headers,
      extra: extra,
      responseType: ro.responseType,
      contentType: ro.contentType,
      followRedirects: ro.followRedirects,
      receiveDataWhenStatusError: ro.receiveDataWhenStatusError,
      sendTimeout: ro.sendTimeout,
      receiveTimeout: ro.receiveTimeout,
    );

    return client.request<dynamic>(
      ro.path,
      data: ro.data,
      queryParameters: ro.queryParameters,
      options: options,
    );
  }
}

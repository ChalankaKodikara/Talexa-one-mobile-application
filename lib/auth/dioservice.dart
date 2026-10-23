import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class DioService {
  late Dio _dio;

  DioService() {
    _dio = Dio();
    _setupDio();
  }

  Dio get dio => _dio;

  void _setupDio() {
    final cookieJar = CookieJar();
    final cookieManager = CookieManager(cookieJar);
    _dio.interceptors.add(cookieManager);

    // Add other interceptors or configurations as needed
  }
}

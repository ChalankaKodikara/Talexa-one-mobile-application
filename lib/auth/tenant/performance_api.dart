import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class PerformanceApi {
  PerformanceApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kPerformanceHistoryPath =
      '/v1/hris/performance/performance-type-marks-to-date-month-year';
  static const String kPerformanceUpdatePath =
      '/v1/hris/performance/performance-type-marks-to-date-month-year';

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty)
      throw Exception('Tenant baseUrl not ready');
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<Map<String, dynamic>> getPerformanceHistory(
      String employeeId, String date) async {
    await _ready();
    final res = await tenantDio.get(
      kPerformanceHistoryPath,
      queryParameters: {'employee_no': employeeId, 'date': date},
    );

    if (res.statusCode == 200 && res.data is Map)
      return Map<String, dynamic>.from(res.data);
    throw Exception('Failed to fetch performance history');
  }

  Future<Map<String, dynamic>> updatePerformanceScore(
    String employeeId,
    List<Map<String, dynamic>> criteriaUpdates,
  ) async {
    await _ready();
    final res = await tenantDio.put(
      kPerformanceUpdatePath,
      data: {'employee_id': employeeId, 'criteriaUpdates': criteriaUpdates},
    );

    if (res.statusCode == 200 && res.data is Map)
      return Map<String, dynamic>.from(res.data);
    throw Exception('Failed to update performance score: ${res.statusCode}');
  }
}

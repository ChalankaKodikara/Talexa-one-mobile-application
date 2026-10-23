import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class OvertimeApi {
  OvertimeApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kOvertimeAssignPath =
      '/v1/hris/overtime/assignments-by-employee';
  static const String kOvertimeDetailsPath = '/v1/hris/overtime/assignments';

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty)
      throw Exception('Tenant baseUrl not ready');
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<Map<String, dynamic>> fetchOvertimeData(String employeeId) async {
    await _ready();
    final res = await tenantDio.get(
      kOvertimeAssignPath,
      queryParameters: {'employee_no': employeeId},
    );

    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }
    throw Exception('Invalid overtime response');
  }

  Future<Map<String, dynamic>> getOvertimeAssignmentById(int overtimeId) async {
    await _ready();
    final res = await tenantDio.get('$kOvertimeDetailsPath/$overtimeId');

    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }
    throw Exception('Invalid overtime details response');
  }
}

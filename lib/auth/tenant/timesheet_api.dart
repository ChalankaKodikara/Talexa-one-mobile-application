import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class TimesheetApi {
  TimesheetApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kGetTimesheetPath =
      '/v1/hris/employeeTimeTable/get-employee-timetable';

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty)
      throw Exception('Tenant baseUrl not ready');
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<Map<String, dynamic>> fetchTimeSheetData(String employeeId) async {
    await _ready();
    final res = await tenantDio.get(
      kGetTimesheetPath,
      queryParameters: {'employee_no': employeeId},
    );

    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }
    throw Exception('Invalid timesheet response');
  }
}

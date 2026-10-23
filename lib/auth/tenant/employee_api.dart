import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class EmployeeApi {
  EmployeeApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kEmployeePersonalPathPrefix =
      '/v1/hris/employees/personal';
  static const String kFacilityCountsPath =
      '/v1/hris/facilities/facility-counts';
  static const String kAllEmployeesPath =
      '/v1/hris/employees/employee/all-details';
  static const String kUpcomingBirthdaysPath =
      '/v1/hris/employees/get-birthdays';

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty)
      throw Exception('Tenant baseUrl not ready');
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<Map<String, dynamic>> getEmployeePersonalDetails(
      String employeeId) async {
    await _ready();
    final res = await tenantDio.get('$kEmployeePersonalPathPrefix/$employeeId');
    if (res.statusCode == 200 && res.data is Map)
      return Map<String, dynamic>.from(res.data);
    throw Exception('Failed to fetch employee personal details');
  }

  Future<Map<String, dynamic>> editEmployeePersonalDetails(
    String employeeId,
    Map<String, dynamic> updatedData,
  ) async {
    await _ready();
    final res = await tenantDio.put('$kEmployeePersonalPathPrefix/$employeeId',
        data: updatedData);
    if (res.statusCode == 200 && res.data is Map)
      return Map<String, dynamic>.from(res.data);
    throw Exception('Failed to update employee personal details');
  }

  Future<Map<String, dynamic>> getFacilityCounts(String employeeId) async {
    await _ready();
    final res = await tenantDio.get(
      kFacilityCountsPath,
      queryParameters: {'employee_no': employeeId},
    );
    if (res.statusCode == 200 && res.data is Map)
      return Map<String, dynamic>.from(res.data);
    throw Exception('Failed to fetch facility counts');
  }

  Future<List<Map<String, dynamic>>> searchEmployees({
    required String search,
    required int organizationId,
    int limit = 15,
  }) async {
    await _ready();
    final res = await tenantDio.get(
      kAllEmployeesPath,
      queryParameters: {
        'organization': organizationId,
        'employee_active_status': 'Active',
        'search': search,
        'limit': limit,
      },
    );

    final body = res.data;
    if (body is Map && body['data'] is List) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchUpcomingBirthdays(
      String organizationId) async {
    await _ready();
    final res = await tenantDio.get(
      kUpcomingBirthdaysPath,
      queryParameters: {'organization': organizationId},
    );

    if (res.statusCode == 200) {
      if (res.data is List) return List<Map<String, dynamic>>.from(res.data);
      if (res.data is Map && res.data['data'] is List) {
        return List<Map<String, dynamic>>.from(res.data['data']);
      }
    }
    throw Exception('Unexpected upcoming birthdays response');
  }
}

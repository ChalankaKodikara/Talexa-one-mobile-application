import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class PayrollApi {
  PayrollApi({
    required this.tenantDio,
    required this.session,
  });

  final Dio tenantDio;
  final AuthSession session;

  static const String kGeneratedPayrollByMonthYearPath =
      '/v1/hris/payroll/genarated-payroll-by-month-and-year';

  static const String kLastLoanLeavePath = '/v1/hris/employees/last-leave-loan';

  Future<void> _ready() async {
    await session.initialize();

    if ((session.apiBaseUrl ?? '').isEmpty) {
      throw Exception('Tenant baseUrl not ready');
    }

    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<String> _resolveEmployeeNo([String? employeeNo]) async {
    await session.initialize();

    final resolved = (employeeNo ?? session.employeeNo ?? '').trim();

    if (resolved.isEmpty) {
      throw Exception('Employee number not found in session');
    }

    return resolved;
  }

  String _normalizeMonth(String month) {
    final parsed = int.tryParse(month.trim());
    if (parsed == null || parsed < 1 || parsed > 12) {
      throw Exception('Invalid month: $month');
    }
    return parsed.toString();
  }

  Future<Map<String, dynamic>> getMonthlySalary(
    String year,
    String month, {
    String? employeeNo,
  }) async {
    await _ready();

    final empNo = await _resolveEmployeeNo(employeeNo);
    final normalizedMonth = _normalizeMonth(month);

    final res = await tenantDio.get(
      kGeneratedPayrollByMonthYearPath,
      queryParameters: {
        'year': year,
        'month': normalizedMonth,
        'page': 1,
        'limit': 10,
        'search': empNo,
      },
    );

    if (res.statusCode == 200 && res.data is Map) {
      final root = Map<String, dynamic>.from(res.data);

      if (root['success'] == true && root['data'] is List) {
        final List dataList = root['data'] as List;

        if (dataList.isNotEmpty && dataList.first is Map) {
          return Map<String, dynamic>.from(dataList.first as Map);
        }

        return <String, dynamic>{};
      }
    }

    throw Exception('Failed to fetch salary details: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> latestLeaveAndLoanUpdates({
    String? employeeNo,
  }) async {
    await _ready();

    final empNo = await _resolveEmployeeNo(employeeNo);

    final res = await tenantDio.get(
      kLastLoanLeavePath,
      queryParameters: {
        'employee_no': empNo,
      },
    );

    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }

    throw Exception('Failed to fetch last updates');
  }
}

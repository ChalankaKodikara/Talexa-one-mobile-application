import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class LoanApi {
  LoanApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kLoanTypesPath = '/v1/hris/organizations/loan-types';
  static const String kAddLoanRequestPath = '/v1/hris/loans/apply';
  static const String kLoanRequestsPath = '/v1/hris/loans/loanapplications';

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty)
      throw Exception('Tenant baseUrl not ready');
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<List<Map<String, dynamic>>> getLoanTypes(
      {required int organizationId}) async {
    await _ready();
    final res = await tenantDio.get(
      kLoanTypesPath,
      queryParameters: {'organization_id': organizationId},
    );

    if (res.statusCode == 200) {
      final body = res.data;
      if (body is Map<String, dynamic> &&
          body['success'] == true &&
          body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    }
    throw Exception('Failed to load loan types');
  }

  Future<void> submitLoanRequest(Map<String, dynamic> payload) async {
    await _ready();
    final res = await tenantDio.post(kAddLoanRequestPath, data: payload);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Loan request failed: ${res.statusMessage}');
    }
  }

  Future<List<Map<String, dynamic>>> getLoanRequests({
    required String employeeNo,
    required int organizationId,
    int? loanTypeId,
    int page = 1,
    int limit = 10,
  }) async {
    await _ready();
    final res = await tenantDio.get(
      kLoanRequestsPath,
      queryParameters: {
        'employee_no': employeeNo,
        'organization_id': organizationId,
        if (loanTypeId != null) 'loan_type_id': loanTypeId,
        'page': page,
        'limit': limit,
      },
    );

    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return List<Map<String, dynamic>>.from(res.data['data']);
    }
    throw Exception('Failed to fetch loan requests');
  }
}

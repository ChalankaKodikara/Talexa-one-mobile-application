import 'dart:io';
import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class ClaimsApi {
  ClaimsApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kClaimList = '/v1/hris/claims/configs/active';
  static const String kClaimSubmit = '/v1/hris/claims/submit';
  static const String kAllApplyedClaims = '/v1/hris/claims/';

  static const String kSpectacleCreatePath =
      '/v1/hris/employee-spectacle-medical/create';
  static const String kBillReimbListPath =
      '/v1/hris/bill-reimbursement-allowance';
  static const String kBillReimbCreatePath =
      '/v1/hris/bill-reimbursement-allowance/create';
  static const String kBillReimbTypesPath =
      '/v1/hris/bill-type/get-all-bill-types';

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty)
      throw Exception('Tenant baseUrl not ready');
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<List<Map<String, dynamic>>> fetchClaimTypes(String employeeId) async {
    await _ready();
    final res = await tenantDio.get(kClaimList);
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return List<Map<String, dynamic>>.from(res.data['data'] as List);
    }
    throw Exception('Unexpected medical reimbursement response');
  }

  Future<bool> submitClaim({
    required String employeeNo,
    required int claimConfigurationId,
    required double claimAmount,
    List<File> documents = const [],
  }) async {
    await _ready();

    final formData = FormData.fromMap({
      'employee_no': employeeNo,
      'claim_configuration_id': claimConfigurationId,
      'claim_amount': claimAmount,
      if (documents.isNotEmpty)
        'documents': documents
            .map((file) => MultipartFile.fromFileSync(file.path,
                filename: file.path.split('/').last))
            .toList(),
    });

    final res = await tenantDio.post(
      kClaimSubmit,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<List<Map<String, dynamic>>> fetchClaimsByEmployee(
      String employeeNo) async {
    await _ready();
    final res = await tenantDio.get(
      kAllApplyedClaims,
      queryParameters: {'employee_no': employeeNo},
    );

    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return List<Map<String, dynamic>>.from(res.data['data']);
    }
    throw Exception('Unexpected claims response');
  }

  Future<Map<String, dynamic>> applySpectacleClaim({
    required String empId,
    required int typeId,
    required String claimAmount,
    String? note,
    String? invoicePath,
    String? prescriptionPath,
  }) async {
    await _ready();

    final fields = <String, dynamic>{
      'empId': empId,
      'typeId': typeId,
      'claim_Amount': claimAmount,
    };

    if ((note ?? '').trim().isNotEmpty) fields['note'] = note;

    if ((invoicePath ?? '').trim().isNotEmpty) {
      fields['Invoice'] =
          await MultipartFile.fromFile(invoicePath!, filename: 'invoice.pdf');
    }
    if ((prescriptionPath ?? '').trim().isNotEmpty) {
      fields['Prescription'] = await MultipartFile.fromFile(prescriptionPath!,
          filename: 'Prescription.pdf');
    }

    final formData = FormData.fromMap(fields);
    final res = await tenantDio.post(
      kSpectacleCreatePath,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = res.data;
      return data is Map<String, dynamic> ? data : {'data': data};
    }
    throw Exception('Failed to apply spectacle claim: ${res.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchBillReimbursementClaims(
      String employeeId) async {
    await _ready();
    final res = await tenantDio.get(
      kBillReimbListPath,
      queryParameters: {'employeeId': employeeId},
    );

    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return List<Map<String, dynamic>>.from(res.data['data'] as List);
    }
    throw Exception('Unexpected bill reimbursement response');
  }

  Future<Map<String, dynamic>> addBillReimbursementClaim({
    required String empId,
    required String empName,
    required int billTypeId,
    required String billDate,
    required String amount,
    String? additionalComments,
    String? invoicePath,
    String? paymentReceiptPath,
  }) async {
    await _ready();

    final fields = <String, dynamic>{
      'employee_no': empId,
      'employeeName': empName,
      'billDate': billDate,
      'billTypeId': billTypeId,
      'amount': amount,
    };

    if ((additionalComments ?? '').trim().isNotEmpty) {
      fields['AdditionalComments'] = additionalComments;
    }

    if ((invoicePath ?? '').trim().isNotEmpty) {
      fields['invoices'] =
          await MultipartFile.fromFile(invoicePath!, filename: 'invoice.pdf');
    }
    if ((paymentReceiptPath ?? '').trim().isNotEmpty) {
      fields['paymentReceipts'] = await MultipartFile.fromFile(
          paymentReceiptPath!,
          filename: 'PaymentReceipt.pdf');
    }

    final formData = FormData.fromMap(fields);
    final res = await tenantDio.post(
      kBillReimbCreatePath,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = res.data;
      return data is Map<String, dynamic> ? data : {'data': data};
    }
    throw Exception('Failed to apply bill reimbursement: ${res.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchBillReimbursementTypes(
      {required int organizationId}) async {
    await _ready();
    final res = await tenantDio.get(
      kBillReimbTypesPath,
      queryParameters: {'organization_id': organizationId},
    );

    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return List<Map<String, dynamic>>.from(res.data['data'] as List);
    }
    throw Exception('Unexpected bill reimbursement types response');
  }
}

// ignore_for_file: avoid_print

import 'package:corehris/components/leavedata.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../core/auth_session.dart';

class LeaveApi {
  LeaveApi({
    required this.tenantDio,
    required this.session,
  });

  final Dio tenantDio;
  final AuthSession session;

  /// ============================================================
  /// ENDPOINTS
  /// ============================================================

  static const String kAddLeavePath = '/v1/hris/leave/addleave-new';

  static const String kGetLeaveByEmpNoPath =
      '/v1/hris/leave/getLeaveByEmployeeNo';

  static const String kGetRestrictedDatePath =
      '/v1/hris/daterestriction/getAllDataRestrictions';

  static const String kGetLeaveCountsPath =
      '/v1/hris/leave/GetLeaveCountsdaypart';

  static const String kDeleteLeaveByIdPath = '/v1/hris/leave/deleteLeaveById';

  static const String kGetLeaveByIdPath = '/v1/hris/leave/getleavebyid';

  static const String kSupervisorApprovalPath =
      '/v1/hris/leave/updateLeaveStatus';

  static const String kCoveringApprovalPath = '/v1/hris/leave/covering';

  static const String kEncashLeavePath = '/v1/hris/leave-encash/encash';

  static const String kGetEncashedLeavesPath = '/v1/hris/leave-encash/encash';

  static const String kGetLeaveAll = '/v1/hris/leave/getleave';

  /// GET MY RECALL REQUESTS
  static const String kGetRecallLeaveAll =
      '/v1/hris/leave/mobile/leave-recall/my';

  /// POST RECALL REQUEST
  static const String kRequestLeaveRecallPath =
      '/v1/hris/leave/mobile/leave-recall';

  /// ============================================================
  /// READY
  /// ============================================================

  Future<void> _ready() async {
    await session.initialize();

    final baseUrl = session.apiBaseUrl?.trim() ?? '';

    if (baseUrl.isEmpty) {
      throw Exception(
        'Tenant base URL is not available.',
      );
    }

    tenantDio.options.baseUrl = baseUrl;
  }

  /// ============================================================
  /// ADD LEAVE
  /// ============================================================

  Future<Response> leaveRequest(
    FormData formData,
  ) async {
    await _ready();

    try {
      final response = await tenantDio.post(
        kAddLeavePath,
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }

      throw Exception(
        "Leave request failed: ${e.message}",
      );
    }
  }

  /// ============================================================
  /// GET EMPLOYEE LEAVES
  /// ============================================================

  Future<List<Map<String, dynamic>>> fetchLeaveData(
    String employeeCode,
  ) async {
    await _ready();

    final cleanEmployeeCode = employeeCode.trim();

    if (cleanEmployeeCode.isEmpty) {
      throw Exception(
        'Employee number is required.',
      );
    }

    try {
      final response = await tenantDio.get(
        kGetLeaveByEmpNoPath,
        queryParameters: {
          'employee_no': cleanEmployeeCode,
        },
      );

      if (response.statusCode == 200) {
        return _extractList(
          response.data,
        );
      }

      throw Exception(
        _extractErrorMessage(
          response.data,
          fallback: 'Failed to load leave requests.',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(
          e,
          fallback: 'Failed to load leave requests.',
        ),
      );
    }
  }

  /// ============================================================
  /// APPROVED EMPLOYEE LEAVES
  /// ============================================================

  Future<List<Map<String, dynamic>>> fetchApprovedLeaveData(
    String employeeCode,
  ) async {
    final leaves = await fetchLeaveData(
      employeeCode,
    );

    final approved = leaves.where(
      (leave) {
        return isLeaveApproved(
          leave,
        );
      },
    ).toList();

    approved.sort(
      (a, b) {
        final aDate = getLeaveRequestedDate(
              a,
            ) ??
            DateTime(1900);

        final bDate = getLeaveRequestedDate(
              b,
            ) ??
            DateTime(1900);

        return bDate.compareTo(
          aDate,
        );
      },
    );

    return approved;
  }

  bool isLeaveApproved(
    Map<String, dynamic> leave,
  ) {
    final status = (leave['approved_status_1'] ??
            leave['status'] ??
            leave['leave_status'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();

    return status == 'APPROVED';
  }

  DateTime? getLeaveRequestedDate(
    Map<String, dynamic> leave,
  ) {
    final rawDate = leave['requested_date'] ??
        leave['leave_date'] ??
        leave['start_date'] ??
        leave['from_date'];

    if (rawDate == null) {
      return null;
    }

    return DateTime.tryParse(
      rawDate.toString(),
    );
  }

  /// ============================================================
  /// RESTRICTION DATES
  /// ============================================================

  Future<List<Map<String, dynamic>>> fetchRestrictionDates() async {
    await _ready();

    try {
      final response = await tenantDio.get(
        kGetRestrictedDatePath,
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractErrorMessage(
            response.data,
            fallback: 'Failed to load restriction dates.',
          ),
        );
      }

      final body = response.data;

      if (body is Map && body['data'] is List) {
        final List items = body['data'];

        return items
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (item) {
                final rawDate = item['restricted_dates'];

                final parsedDate = DateTime.tryParse(
                  rawDate?.toString() ?? '',
                );

                return {
                  'date': parsedDate == null
                      ? null
                      : DateTime(
                          parsedDate.year,
                          parsedDate.month,
                          parsedDate.day,
                        ),
                  'reason': item['reason_for_restriction']?.toString() ?? '',
                  'type':
                      item['restriction_datetype']?.toString() ?? 'Restricted',
                };
              },
            )
            .where(
              (item) => item['date'] != null,
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(
          e,
          fallback: 'Failed to load restriction dates.',
        ),
      );
    }
  }

  /// ============================================================
  /// LEAVE BALANCE
  /// ============================================================

  Future<LeaveResponse> countLeaveData(
    String employeeId,
  ) async {
    await _ready();

    final cleanEmployeeId = employeeId.trim();

    if (cleanEmployeeId.isEmpty) {
      throw Exception(
        'Employee number is required.',
      );
    }

    final response = await tenantDio.get(
      kGetLeaveCountsPath,
      queryParameters: {
        'employee_no': cleanEmployeeId,
      },
    );

    if (response.statusCode == 200) {
      return LeaveResponse.fromJson(
        response.data,
      );
    }

    throw Exception(
      'Failed to load leave data.',
    );
  }

  /// ============================================================
  /// DELETE LEAVE
  /// ============================================================

  Future<void> deleteLeaveRequest(
    int leaveId,
  ) async {
    await _ready();

    final response = await tenantDio.delete(
      kDeleteLeaveByIdPath,
      queryParameters: {
        'leaveid': leaveId,
      },
    );

    if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
      throw Exception(
        _extractErrorMessage(
          response.data,
          fallback: 'Failed to delete leave.',
        ),
      );
    }
  }

  /// ============================================================
  /// TODAY APPROVED
  /// ============================================================

  Future<List<Map<String, dynamic>>> fetchTodayApprovedLeaves({
    DateTime? date,
    int page = 1,
    int limit = 500,
  }) async {
    await _ready();

    try {
      final targetDate = date ?? DateTime.now();

      final requestedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(
        targetDate,
      );

      final response = await tenantDio.get(
        kGetLeaveAll,
        queryParameters: {
          'page': page,
          'limit': limit,
          'requested_date': requestedDate,
          'approved_status_1': 'APPROVED',
        },
      );

      if (response.statusCode == 200) {
        return _extractList(
          response.data,
        );
      }

      return [];
    } catch (e) {
      print(
        'Approved leave error: $e',
      );

      return [];
    }
  }

  /// ============================================================
  /// GET LEAVE BY ID
  /// ============================================================

  Future<Map<String, dynamic>?> getLeaveDataById(
    int leaveId,
  ) async {
    await _ready();

    try {
      final response = await tenantDio.get(
        kGetLeaveByIdPath,
        queryParameters: {
          'id': leaveId,
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final body = response.data;

      if (body is Map && body['data'] is Map) {
        return Map<String, dynamic>.from(
          body['data'],
        );
      }

      if (body is Map) {
        return Map<String, dynamic>.from(
          body,
        );
      }
    } catch (_) {}

    return null;
  }

  /// ============================================================
  /// SUPERVISOR APPROVAL
  /// ============================================================

  Future<Response?> supervisorApproval({
    required int leaveId,
    required String approvalStatus,
    required String remarks,
    required List<String> emails,
  }) async {
    await _ready();

    try {
      return await tenantDio.put(
        kSupervisorApprovalPath,
        queryParameters: {
          'leaveid': leaveId,
        },
        data: {
          'approved_status_1': approvalStatus,
          'remarks': remarks,
          'emails': emails,
        },
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  /// ============================================================
  /// COVERING APPROVAL
  /// ============================================================

  Future<Response?> coveringApproval({
    required int leaveId,
    required String approvalStatus,
    required String coveringEmployeeNo,
  }) async {
    await _ready();

    try {
      return await tenantDio.put(
        kCoveringApprovalPath,
        data: {
          'leave_id': leaveId,
          'action': approvalStatus,
          'covering_employee_no': coveringEmployeeNo,
        },
      );
    } on DioException catch (e) {
      return e.response;
    }
  }

  /// ============================================================
  /// ENCASH
  /// ============================================================

  Future<List<Map<String, dynamic>>> getEncashedLeaves({
    required String employeeNo,
    String? status,
    int? organizationId,
  }) async {
    await _ready();

    final response = await tenantDio.get(
      kGetEncashedLeavesPath,
      queryParameters: {
        "search": employeeNo,
        if (status != null) "status": status,
        if (organizationId != null) "organization_id": organizationId,
      },
    );

    if (response.statusCode == 200) {
      return _extractList(
        response.data,
      );
    }

    throw Exception(
      "Failed to load encashed leaves",
    );
  }

  Future<void> encashLeave({
    required String employeeNo,
    required int leaveCategoryId,
    required int requestedDays,
  }) async {
    await _ready();

    final response = await tenantDio.post(
      kEncashLeavePath,
      data: {
        "employee_no": employeeNo,
        "leave_category_id": leaveCategoryId,
        "requested_days": requestedDays,
      },
    );

    final code = response.statusCode ?? 0;

    if (code < 200 || code >= 300) {
      throw Exception(
        "Encash failed",
      );
    }
  }

  /// ============================================================
  /// GET MY RECALL REQUESTS
  /// ============================================================

  Future<List<Map<String, dynamic>>> fetchMyLeaveRecallRequests({
    required String employeeNo,
    int page = 1,
    int limit = 100,
  }) async {
    await _ready();

    final cleanEmployeeNo = employeeNo.trim();

    if (cleanEmployeeNo.isEmpty) {
      throw Exception(
        'Employee number is required.',
      );
    }

    try {
      final encoded = Uri.encodeComponent(
        cleanEmployeeNo,
      );

      final response = await tenantDio.get(
        '$kGetRecallLeaveAll/$encoded',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final code = response.statusCode ?? 0;

      if (code < 200 || code >= 300) {
        throw Exception(
          _extractErrorMessage(
            response.data,
            fallback: 'Failed to load recall requests.',
          ),
        );
      }

      final body = response.data;

      if (body is! Map) {
        return [];
      }

      final data = body['data'];

      if (data is! Map) {
        return [];
      }

      final requests = data['requests'];

      if (requests is! List) {
        return [];
      }

      return requests
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(
              item,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(
          e,
          fallback: 'Failed to load recall requests.',
        ),
      );
    }
  }

  /// ============================================================
  /// SUBMIT LEAVE RECALL
  /// ============================================================

  Future<Response?> requestLeaveRecall({
    required int leaveId,
    required String employeeNo,
    required String reason,
    required String remarks,
  }) async {
    await _ready();

    final cleanEmployeeNo = employeeNo.trim();

    final cleanReason = reason.trim();

    if (leaveId <= 0) {
      throw Exception(
        'Invalid leave ID.',
      );
    }

    if (cleanEmployeeNo.isEmpty) {
      throw Exception(
        'Employee number is required.',
      );
    }

    if (cleanReason.isEmpty) {
      throw Exception(
        'Recall reason is required.',
      );
    }

    try {
      return await tenantDio.post(
        kRequestLeaveRecallPath,
        data: {
          "leave_id": leaveId,
          "employee_no": cleanEmployeeNo,
          "reason": cleanReason,
          "remarks": remarks.trim(),
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response;
      }

      throw Exception(
        'Unable to connect to server.',
      );
    }
  }

  /// ============================================================
  /// LIST PARSER
  /// ============================================================

  List<Map<String, dynamic>> _extractList(
    dynamic body,
  ) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(
              item,
            ),
          )
          .toList();
    }

    if (body is Map && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(
              item,
            ),
          )
          .toList();
    }

    if (body is Map && body['result'] is List) {
      return (body['result'] as List)
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(
              item,
            ),
          )
          .toList();
    }

    return [];
  }

  String _extractErrorMessage(
    dynamic body, {
    required String fallback,
  }) {
    if (body is Map) {
      final message =
          body['message'] ?? body['error'] ?? body['developerMessage'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }

    return fallback;
  }

  String _extractDioError(
    DioException error, {
    required String fallback,
  }) {
    if (error.response != null) {
      return _extractErrorMessage(
        error.response?.data,
        fallback: fallback,
      );
    }

    return error.message ?? fallback;
  }
}

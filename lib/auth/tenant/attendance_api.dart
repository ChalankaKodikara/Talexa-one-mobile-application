import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../core/auth_session.dart';
import '../utils/attendance_helpers.dart';

class AttendanceApi {
  AttendanceApi({
    required this.tenantDio,
    required this.session,
  });

  final Dio tenantDio;
  final AuthSession session;

  // ============================================================
  // API PATHS
  // ============================================================

  static const String kAddAttendancePath =
      '/v1/hris/attendence/addMobileAttendance';

  static const String kGetAttendancePath = '/v1/hris/new-attendence/by-date';

  static const String kGetAttendanceRangePath =
      '/v1/hris/new-attendence/by-date-range';

  static const String kGetAllAttendanceTodayPath =
      '/v1/hris/new-attendence/by-date';

  static const String kAttendanceEditPath =
      '/v1/hris/attendence/adjustments/mobile';

  static const String kAttendanceEditReportPath =
      '/v1/hris/attendence/adjustments/my-requests';

  static const String kAuthorizedLocationCoordinate =
      '/v1/hris/attendence/authorized-locations';

  // ============================================================
  // READY
  // ============================================================

  Future<void> _ready() async {
    await session.initialize();

    final String baseUrl = (session.apiBaseUrl ?? '').trim();

    if (baseUrl.isEmpty) {
      throw Exception(
        'Tenant baseUrl not ready',
      );
    }

    tenantDio.options.baseUrl = baseUrl;
  }

  // ============================================================
  // ADD MOBILE ATTENDANCE
  // ============================================================

  Future<void> addAttendance(
    Map<String, dynamic> requestData,
  ) async {
    await _ready();

    try {
      final Response<dynamic> response = await tenantDio.post(
        kAddAttendancePath,
        data: requestData,
      );

      final int statusCode = response.statusCode ?? 0;

      if (statusCode < 200 || statusCode >= 300) {
        throw Exception(
          _getErrorMessage(
            response.data,
            fallback: 'Failed to add attendance: $statusCode',
          ),
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e.response?.data,
          fallback: e.message ?? 'Failed to add attendance',
        ),
      );
    }
  }

  // ============================================================
  // GET ATTENDANCE - SINGLE DATE
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchAttendanceData(
    String username,
    DateTime selectedDate,
  ) async {
    await _ready();

    final String formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(selectedDate);

    try {
      final Response<dynamic> response = await tenantDio.get(
        kGetAttendancePath,
        queryParameters: {
          'search': username,
          'date': formattedDate,
        },
      );

      if (response.statusCode == 200) {
        final dynamic body = response.data;

        if (body is Map && body['success'] == true) {
          final dynamic data = body['data'];

          if (data is List) {
            return data
                .whereType<Map>()
                .map<Map<String, dynamic>>(
                  (Map item) => Map<String, dynamic>.from(
                    item,
                  ),
                )
                .toList();
          }

          if (data is Map && data['attendance'] is List) {
            return (data['attendance'] as List)
                .whereType<Map>()
                .map<Map<String, dynamic>>(
                  (Map item) => Map<String, dynamic>.from(
                    item,
                  ),
                )
                .toList();
          }
        }
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e.response?.data,
          fallback: e.message ?? 'Unable to fetch attendance',
        ),
      );
    }
  }

  // ============================================================
  // GET AUTHORIZED ATTENDANCE LOCATIONS
  //
  // GET:
  // /v1/hris/attendence/authorized-locations
  //
  // Query:
  // employee_id=EMP03438
  // ============================================================

  Future<Map<String, dynamic>> fetchAuthorizedLocations({
    required String employeeId,
  }) async {
    await _ready();

    final String cleanEmployeeId = employeeId.trim();

    if (cleanEmployeeId.isEmpty) {
      throw Exception(
        'Employee ID is required to load authorized attendance locations.',
      );
    }

    try {
      final Response<dynamic> response = await tenantDio.get(
        kAuthorizedLocationCoordinate,
        queryParameters: {
          'employee_id': cleanEmployeeId,
        },
      );

      final int statusCode = response.statusCode ?? 0;

      if (statusCode < 200 || statusCode >= 300) {
        throw Exception(
          _getErrorMessage(
            response.data,
            fallback: 'Failed to fetch authorized attendance locations '
                '($statusCode)',
          ),
        );
      }

      final dynamic rawBody = response.data;

      if (rawBody is! Map) {
        throw Exception(
          'Invalid authorized attendance location response.',
        );
      }

      final Map<String, dynamic> body = Map<String, dynamic>.from(
        rawBody,
      );

      if (body['success'] != true) {
        throw Exception(
          _getErrorMessage(
            body,
            fallback: 'Unable to retrieve authorized attendance locations.',
          ),
        );
      }

      // ========================================================
      // BACKEND DATA
      // ========================================================

      final dynamic rawData = body['data'];

      if (rawData is! Map) {
        return {
          'success': true,
          'message': body['message']?.toString() ??
              'Authorized attendance locations retrieved successfully.',
          'data': {
            'employee_id': cleanEmployeeId,
            'organization_id': null,
            'gps_rules': {
              'max_accuracy_meters': 100.0,
            },
            'location_count': 0,
            'company_location_available': false,
            'employee_location_count': 0,
            'locations': <Map<String, dynamic>>[],
          },
        };
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        rawData,
      );

      // ========================================================
      // GPS RULES
      // ========================================================

      final Map<String, dynamic> gpsRules = <String, dynamic>{};

      final dynamic rawGpsRules = data['gps_rules'];

      if (rawGpsRules is Map) {
        final Map<String, dynamic> convertedGpsRules =
            Map<String, dynamic>.from(
          rawGpsRules,
        );

        gpsRules.addAll(
          convertedGpsRules,
        );
      }

      gpsRules['max_accuracy_meters'] = _toDouble(
            gpsRules['max_accuracy_meters'],
          ) ??
          100.0;

      // ========================================================
      // LOCATIONS
      // ========================================================

      final List<Map<String, dynamic>> locations = [];

      final dynamic rawLocations = data['locations'];

      if (rawLocations is List) {
        for (final dynamic rawLocation in rawLocations) {
          if (rawLocation is! Map) {
            continue;
          }

          final Map<String, dynamic> item = Map<String, dynamic>.from(
            rawLocation,
          );

          final double? latitude = _toDouble(
            item['latitude'],
          );

          final double? longitude = _toDouble(
            item['longitude'],
          );

          // A location without coordinates cannot be used
          // for GPS attendance validation.
          if (latitude == null || longitude == null) {
            continue;
          }

          final double allowedRadiusMeters = _toDouble(
                item['allowed_radius_meters'],
              ) ??
              100.0;

          final Map<String, dynamic> location = {
            'id': item['id'],
            'attendance_location_id': item['attendance_location_id'],
            'location_name': _stringOrDefault(
              item['location_name'],
              'Authorized Location',
            ),
            'location_type': _stringOrDefault(
              item['location_type'],
              'OTHER',
            ),
            'area_alias': _nullableString(
              item['area_alias'],
            ),
            'terminal_alias': _nullableString(
              item['terminal_alias'],
            ),
            'terminal_sn': _nullableString(
              item['terminal_sn'],
            ),
            'latitude': latitude,
            'longitude': longitude,
            'address': _nullableString(
              item['address'],
            ),
            'allowed_radius_meters': allowedRadiusMeters,
            'requires_approval': _toBool(
              item['requires_approval'],
            ),
            'valid_from': item['valid_from'],
            'valid_to': item['valid_to'],
            'source': _stringOrDefault(
              item['source'],
              'EMPLOYEE_AUTHORIZED',
            ),
          };

          locations.add(
            location,
          );
        }
      }

      // ========================================================
      // COUNTS
      // ========================================================

      final int companyLocationCount = locations.where(
        (
          Map<String, dynamic> item,
        ) {
          return item['source']?.toString().toUpperCase() == 'COMPANY';
        },
      ).length;

      final int employeeLocationCount = locations.where(
        (
          Map<String, dynamic> item,
        ) {
          return item['source']?.toString().toUpperCase() ==
              'EMPLOYEE_AUTHORIZED';
        },
      ).length;

      // ========================================================
      // RETURN SAME STRUCTURE AS BACKEND
      // ========================================================

      return {
        'success': true,
        'message': body['message']?.toString() ??
            'Authorized attendance locations retrieved successfully.',
        'data': {
          'employee_id': _stringOrDefault(
            data['employee_id'],
            cleanEmployeeId,
          ),
          'organization_id': data['organization_id'],
          'gps_rules': gpsRules,
          'location_count': _toInt(
                data['location_count'],
              ) ??
              locations.length,
          'company_location_available': data.containsKey(
            'company_location_available',
          )
              ? _toBool(
                  data['company_location_available'],
                )
              : companyLocationCount > 0,
          'employee_location_count': _toInt(
                data['employee_location_count'],
              ) ??
              employeeLocationCount,
          'locations': locations,
        },
      };
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e.response?.data,
          fallback:
              e.message ?? 'Unable to fetch authorized attendance locations',
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to fetch authorized attendance locations: $e',
      );
    }
  }

  // ============================================================
  // ATTENDANCE EDIT / ADJUSTMENT REQUEST
  // ============================================================

  Future<Map<String, dynamic>> updateAttendanceEdit({
    required String employeeId,
    required DateTime workDate,
    required String adjustmentType,
    DateTime? requestedCheckIn,
    DateTime? requestedCheckOut,
    required String requestedStatus,
    required String reason,
    String? attachmentUrl,
  }) async {
    await _ready();

    final String workDateLocal = DateFormat(
      'yyyy-MM-dd',
    ).format(workDate);

    final Map<String, dynamic> requestData = {
      'employee_id': employeeId.trim(),
      'work_date_local': workDateLocal,
      'adjustment_type': adjustmentType.trim(),
      'requested_check_in': requestedCheckIn != null
          ? DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(
              requestedCheckIn,
            )
          : null,
      'requested_check_out': requestedCheckOut != null
          ? DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(
              requestedCheckOut,
            )
          : null,
      'requested_status': requestedStatus.trim(),
      'reason': reason.trim(),
      'attachment_url':
          attachmentUrl?.trim().isEmpty == true ? null : attachmentUrl?.trim(),
    };

    try {
      final Response<dynamic> response = await tenantDio.post(
        kAttendanceEditPath,
        data: requestData,
      );

      final int statusCode = response.statusCode ?? 0;

      if (statusCode >= 200 && statusCode < 300) {
        final dynamic responseBody = response.data;

        if (responseBody is Map) {
          return Map<String, dynamic>.from(
            responseBody,
          );
        }

        return {
          'success': true,
          'message': 'Attendance adjustment submitted successfully',
          'data': responseBody,
        };
      }

      throw Exception(
        _getErrorMessage(
          response.data,
          fallback: 'Failed to update attendance ($statusCode)',
        ),
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e.response?.data,
          fallback: e.message ?? 'Unable to update attendance',
        ),
      );
    }
  }

  // ============================================================
  // GET ATTENDANCE RANGE
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchAttendanceRange(
    String username,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await _ready();

    final String formattedStart = DateFormat(
      'yyyy-MM-dd',
    ).format(startDate);

    final String formattedEnd = DateFormat(
      'yyyy-MM-dd',
    ).format(endDate);

    try {
      final Response<dynamic> response = await tenantDio.get(
        kGetAttendanceRangePath,
        queryParameters: {
          'employee_no': username,
          'from': formattedStart,
          'to': formattedEnd,
          'page': 1,
        },
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true &&
          response.data['data'] is List) {
        final List<dynamic> rawList = List<dynamic>.from(
          response.data['data'],
        );

        return rawList.map<Map<String, dynamic>>(
          (
            dynamic raw,
          ) {
            final Map<String, dynamic> item = Map<String, dynamic>.from(
              raw as Map,
            );

            final String rawStatus = (item['status'] ?? '').toString().trim();

            final Map<String, dynamic> mapped = AttendanceHelpers.mapStatus(
              rawStatus,
            );

            final dynamic punches = AttendanceHelpers.buildPunches(
              item,
            );

            String? legacyCheckoutAddress;

            final dynamic legacyAddress = item['legacy_address'];

            if (legacyAddress is Map) {
              final dynamic checkout = legacyAddress['checkout'];

              if (checkout is Map) {
                legacyCheckoutAddress = checkout['address']?.toString();
              }
            }

            return {
              'employee_id': item['employee_id'],
              'employee_no': item['employee_no'],
              'employee_fullname': item['employee_fullname'],
              'employee_active_status': item['employee_active_status'],
              'organization_id': item['organization_id'],
              'organization_code': item['organization_code'],
              'organization_name': item['organization_name'],
              'date': item['date'] ?? '',
              'rawStatus': rawStatus,
              'status': mapped['status'],
              'dayType': mapped['dayType'],
              'check_in_time': item['check_in_time'],
              'check_in_type': item['check_in_type'],
              'check_in_address': item['check_in_address'],
              'check_out_time': item['check_out_time'],
              'check_out_type': item['check_out_type'],
              'check_out_address':
                  item['check_out_address'] ?? legacyCheckoutAddress,
              'legacy_address': item['legacy_address'],
              'ot': item['OT']?.toString() ?? '0',
              'punches': punches,
            };
          },
        ).toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e.response?.data,
          fallback: e.message ?? 'Unable to fetch attendance range',
        ),
      );
    }
  }

  // ============================================================
  // GET ATTENDANCE EDIT / ADJUSTMENT REPORT
  // ============================================================

  Future<Map<String, dynamic>> fetchAttendanceEditReport({
    required String employeeId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    await _ready();

    final String cleanEmployeeId = employeeId.trim();

    if (cleanEmployeeId.isEmpty) {
      throw Exception(
        'Employee ID is required to load attendance adjustment requests.',
      );
    }

    final Map<String, dynamic> queryParameters = {
      'employee_id': cleanEmployeeId,
      'page': page < 1 ? 1 : page,
      'limit': limit < 1 ? 20 : limit,
    };

    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    if (dateFrom != null) {
      queryParameters['date_from'] = DateFormat(
        'yyyy-MM-dd',
      ).format(dateFrom);
    }

    if (dateTo != null) {
      queryParameters['date_to'] = DateFormat(
        'yyyy-MM-dd',
      ).format(dateTo);
    }

    try {
      final Response<dynamic> response = await tenantDio.get(
        kAttendanceEditReportPath,
        queryParameters: queryParameters,
      );

      final int statusCode = response.statusCode ?? 0;

      if (statusCode < 200 || statusCode >= 300) {
        throw Exception(
          _getErrorMessage(
            response.data,
            fallback: 'Failed to fetch attendance adjustment requests '
                '($statusCode)',
          ),
        );
      }

      final dynamic responseBody = response.data;

      if (responseBody is! Map) {
        return {
          'success': false,
          'message': 'Invalid attendance adjustment response.',
          'pagination': {
            'page': page,
            'limit': limit,
            'total': 0,
            'totalPages': 0,
          },
          'data': <Map<String, dynamic>>[],
        };
      }

      final Map<String, dynamic> body = Map<String, dynamic>.from(
        responseBody,
      );

      final List<Map<String, dynamic>> requests = [];

      final dynamic rawData = body['data'];

      if (rawData is List) {
        for (final dynamic rawItem in rawData) {
          if (rawItem is! Map) {
            continue;
          }

          final Map<String, dynamic> item = Map<String, dynamic>.from(
            rawItem,
          );

          requests.add({
            'id': item['id'],
            'organization_id': item['organization_id'],
            'employee_id': item['employee_id']?.toString(),
            'attendance_id': item['attendance_id'],
            'work_date_local': item['work_date_local'],
            'adjustment_type': item['adjustment_type'],
            'current_check_in': item['current_check_in'],
            'requested_check_in': item['requested_check_in'],
            'current_check_out': item['current_check_out'],
            'requested_check_out': item['requested_check_out'],
            'current_status': item['current_status'],
            'requested_status': item['requested_status'],
            'reason': item['reason'],
            'attachment_url': item['attachment_url'],
            'status': item['status'],
            'requested_by': item['requested_by'],
            'requested_at': item['requested_at'] ?? item['created_at'],
            'reviewed_by': item['reviewed_by'],
            'reviewed_at': item['reviewed_at'],
            'review_remarks': item['review_remarks'],
            'raw': item,
          });
        }
      }

      final Map<String, dynamic> pagination = body['pagination'] is Map
          ? Map<String, dynamic>.from(
              body['pagination'] as Map,
            )
          : <String, dynamic>{
              'page': page,
              'limit': limit,
              'total': requests.length,
              'totalPages': requests.isEmpty ? 0 : 1,
            };

      return {
        'success': body['success'] == true,
        'message': body['message']?.toString() ??
            'Attendance adjustment requests retrieved successfully.',
        'pagination': pagination,
        'data': requests,
      };
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e.response?.data,
          fallback:
              e.message ?? 'Unable to fetch attendance adjustment requests',
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to fetch attendance adjustment requests: $e',
      );
    }
  }

  // ============================================================
  // GET ALL ATTENDANCE TODAY
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchAllAttendanceToday(
    DateTime date,
    int organizationId,
    int supervisorId,
  ) async {
    await _ready();

    final String formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(date);

    try {
      final Response<dynamic> response = await tenantDio.get(
        kGetAllAttendanceTodayPath,
        queryParameters: {
          'date': formattedDate,
          'organization': organizationId,
          'supervisor_id': supervisorId,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;

        if (data is List) {
          return data
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (Map item) => Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();
        }

        if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (Map item) => Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e.response?.data,
          fallback: e.message ?? 'Unable to fetch attendance',
        ),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(
      text,
    );
  }

  int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return int.tryParse(
      text,
    );
  }

  bool _toBool(
    dynamic value,
  ) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'yes' || text == 'y';
  }

  String _stringOrDefault(
    dynamic value,
    String fallback,
  ) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String? _nullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  String _getErrorMessage(
    dynamic body, {
    required String fallback,
  }) {
    if (body == null) {
      return fallback;
    }

    if (body is String) {
      final String value = body.trim();

      if (value.isNotEmpty) {
        return value;
      }

      return fallback;
    }

    if (body is Map) {
      final dynamic message = body['message'] ?? body['error'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }

      final dynamic errors = body['errors'];

      if (errors is List && errors.isNotEmpty) {
        return errors
            .map(
              (dynamic item) => item.toString(),
            )
            .join('\n');
      }
    }

    return fallback;
  }
}

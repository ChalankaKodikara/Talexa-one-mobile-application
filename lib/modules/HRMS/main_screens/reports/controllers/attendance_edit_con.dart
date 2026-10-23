import 'package:corehris/auth/authservices.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class AttendanceEditReportController extends GetxController {
  // ============================================================
  // SERVICE
  // ============================================================

  final AuthService authService = AuthService();

  // ============================================================
  // LOADING / ERROR
  // ============================================================

  final isLoading = false.obs;
  final isLoadingMore = false.obs;

  final hasError = false.obs;
  final errorMessage = ''.obs;

  // ============================================================
  // EMPLOYEE
  // ============================================================

  final employeeId = ''.obs;
  final employeeName = ''.obs;

  // ============================================================
  // DATA
  // ============================================================

  final RxList<Map<String, dynamic>> requests = <Map<String, dynamic>>[].obs;

  // ============================================================
  // FILTERS
  // ============================================================

  final selectedStatus = 'ALL'.obs;

  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  final List<String> statusOptions = const [
    'ALL',
    'PENDING',
    'APPROVED',
    'REJECTED',
  ];

  // ============================================================
  // PAGINATION
  // ============================================================

  final page = 1.obs;
  final limit = 20.obs;

  final total = 0.obs;
  final totalPages = 0.obs;

  final hasNextPage = false.obs;
  final hasPreviousPage = false.obs;

  // ============================================================
  // SUMMARY
  // ============================================================

  final pendingCount = 0.obs;
  final approvedCount = 0.obs;
  final rejectedCount = 0.obs;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await authService.initialize();

      await _loadEmployee();

      _setCurrentMonthWithoutFetch();

      await fetchRequests();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = _cleanError(e);
    }
  }

  // ============================================================
  // LOAD EMPLOYEE FROM SHARED PREFERENCES
  // ============================================================

  Future<void> _loadEmployee() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // ----------------------------------------------------------
    // IMPORTANT:
    // Employee ID comes ONLY from employee_no.
    // Example: EMP03439
    // ----------------------------------------------------------

    employeeId.value = (prefs.getString('employee_no') ?? '').trim();

    // ----------------------------------------------------------
    // Employee name is optional.
    // ----------------------------------------------------------

    employeeName.value = (prefs.getString('employee_fullname') ??
            prefs.getString('employee_name') ??
            prefs.getString('full_name') ??
            prefs.getString('fullname') ??
            prefs.getString('name') ??
            '')
        .trim();

    print(
      '[AttendanceEditReport] employee_no: ${employeeId.value}',
    );

    print(
      '[AttendanceEditReport] employee_name: ${employeeName.value}',
    );
  }

  // ============================================================
  // FETCH REQUESTS
  // ============================================================

  Future<void> fetchRequests({
    bool resetPage = true,
  }) async {
    final String empNo = employeeId.value.trim();

    if (empNo.isEmpty) {
      requests.clear();

      hasError.value = true;

      errorMessage.value =
          'Employee number is unavailable. Please login again.';

      _resetPagination();
      _resetSummary();

      return;
    }

    if (resetPage) {
      page.value = 1;
    }

    try {
      isLoading.value = true;

      hasError.value = false;
      errorMessage.value = '';

      final Map<String, dynamic> response =
          await authService.attendance.fetchAttendanceEditReport(
        employeeId: empNo,
        status: selectedStatus.value == 'ALL' ? null : selectedStatus.value,
        dateFrom: startDate.value,
        dateTo: endDate.value,
        page: page.value,
        limit: limit.value,
      );

      print(
        '[AttendanceEditReport] Response: $response',
      );

      // --------------------------------------------------------
      // SUCCESS CHECK
      // --------------------------------------------------------

      if (response['success'] == false) {
        throw Exception(
          response['message']?.toString() ??
              'Unable to load attendance requests.',
        );
      }

      // --------------------------------------------------------
      // DATA
      // --------------------------------------------------------

      final dynamic responseData = response['data'];

      if (responseData is List) {
        final List<Map<String, dynamic>> mapped =
            responseData.whereType<Map>().map<Map<String, dynamic>>(
          (dynamic item) {
            return _normalizeRequest(
              Map<String, dynamic>.from(item),
            );
          },
        ).toList();

        requests.assignAll(mapped);
      } else {
        requests.clear();
      }

      // --------------------------------------------------------
      // PAGINATION
      // --------------------------------------------------------

      _applyPagination(
        response['pagination'],
      );

      // --------------------------------------------------------
      // SUMMARY
      // --------------------------------------------------------

      _calculateSummary();
    } catch (e) {
      requests.clear();

      hasError.value = true;

      errorMessage.value = _cleanError(e);

      _resetPagination();
      _resetSummary();

      print(
        '[AttendanceEditReport] Fetch Error: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // NORMALIZE REQUEST
  // ============================================================

  Map<String, dynamic> _normalizeRequest(
    Map<String, dynamic> item,
  ) {
    // ----------------------------------------------------------
    // If AttendanceApi includes original response inside raw,
    // use it as fallback.
    // ----------------------------------------------------------

    final Map<String, dynamic> source = <String, dynamic>{};

    final dynamic raw = item['raw'];

    if (raw is Map) {
      source.addAll(
        Map<String, dynamic>.from(raw),
      );
    }

    source.addAll(item);

    return {
      'id': source['id'],

      'organization_id': source['organization_id'],

      'employee_id': source['employee_id'],

      'attendance_id': source['attendance_id'],

      'work_date_local': source['work_date_local'],

      'adjustment_type': source['adjustment_type'],

      'current_check_in': source['current_check_in'],

      'requested_check_in': source['requested_check_in'],

      'current_check_out': source['current_check_out'],

      'requested_check_out': source['requested_check_out'],

      'current_status': source['current_status'],

      'requested_status': source['requested_status'],

      'reason': source['reason'],

      'attachment_url': source['attachment_url'],

      // --------------------------------------------------------
      // EXACT BACKEND FIELD
      // --------------------------------------------------------

      'request_status': source['request_status'] ?? source['status'],

      'requested_by': source['requested_by'],

      'requested_at': source['requested_at'],

      'reviewed_by': source['reviewed_by'],

      'reviewed_at': source['reviewed_at'],

      'applied_at': source['applied_at'],

      // --------------------------------------------------------
      // EXACT BACKEND FIELD
      // --------------------------------------------------------

      'review_comment': source['review_comment'] ?? source['review_remarks'],

      'created_at': source['created_at'],

      'updated_at': source['updated_at'],

      'raw': source,
    };
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshRequests() async {
    await fetchRequests(
      resetPage: true,
    );
  }

  // ============================================================
  // LOAD MORE
  // ============================================================

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasNextPage.value) {
      return;
    }

    final String empNo = employeeId.value.trim();

    if (empNo.isEmpty) {
      return;
    }

    try {
      isLoadingMore.value = true;

      final int nextPage = page.value + 1;

      final Map<String, dynamic> response =
          await authService.attendance.fetchAttendanceEditReport(
        employeeId: empNo,
        status: selectedStatus.value == 'ALL' ? null : selectedStatus.value,
        dateFrom: startDate.value,
        dateTo: endDate.value,
        page: nextPage,
        limit: limit.value,
      );

      if (response['success'] == false) {
        throw Exception(
          response['message']?.toString() ??
              'Unable to load more attendance requests.',
        );
      }

      final dynamic responseData = response['data'];

      if (responseData is List) {
        final List<Map<String, dynamic>> newItems =
            responseData.whereType<Map>().map<Map<String, dynamic>>(
          (dynamic item) {
            return _normalizeRequest(
              Map<String, dynamic>.from(item),
            );
          },
        ).toList();

        requests.addAll(newItems);
      }

      page.value = nextPage;

      _applyPagination(
        response['pagination'],
      );

      _calculateSummary();
    } catch (e) {
      AppAlert.toast(
        title: 'Unable to load more',
        message: _cleanError(e),
      );

      print(
        '[AttendanceEditReport] Load More Error: $e',
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Future<void> setStatus(
    String value,
  ) async {
    final String normalized = value.trim().toUpperCase();

    if (!statusOptions.contains(
      normalized,
    )) {
      return;
    }

    if (selectedStatus.value == normalized) {
      return;
    }

    selectedStatus.value = normalized;

    await fetchRequests(
      resetPage: true,
    );
  }

  // ============================================================
  // START DATE
  // ============================================================

  Future<void> setStartDate(
    DateTime value,
  ) async {
    final DateTime normalized = DateTime(
      value.year,
      value.month,
      value.day,
    );

    startDate.value = normalized;

    // ----------------------------------------------------------
    // If start > end, move end to start.
    // ----------------------------------------------------------

    if (endDate.value != null &&
        normalized.isAfter(
          endDate.value!,
        )) {
      endDate.value = normalized;
    }

    await fetchRequests(
      resetPage: true,
    );
  }

  // ============================================================
  // END DATE
  // ============================================================

  Future<void> setEndDate(
    DateTime value,
  ) async {
    final DateTime normalized = DateTime(
      value.year,
      value.month,
      value.day,
    );

    endDate.value = normalized;

    // ----------------------------------------------------------
    // If end < start, move start to end.
    // ----------------------------------------------------------

    if (startDate.value != null &&
        normalized.isBefore(
          startDate.value!,
        )) {
      startDate.value = normalized;
    }

    await fetchRequests(
      resetPage: true,
    );
  }

  // ============================================================
  // LAST 7 DAYS
  // ============================================================

  Future<void> setLastSevenDays() async {
    final DateTime now = DateTime.now();

    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    endDate.value = today;

    startDate.value = today.subtract(
      const Duration(
        days: 6,
      ),
    );

    await fetchRequests(
      resetPage: true,
    );
  }

  // ============================================================
  // CURRENT MONTH
  // ============================================================

  void _setCurrentMonthWithoutFetch() {
    final DateTime now = DateTime.now();

    startDate.value = DateTime(
      now.year,
      now.month,
      1,
    );

    endDate.value = DateTime(
      now.year,
      now.month + 1,
      0,
    );
  }

  Future<void> setCurrentMonth() async {
    _setCurrentMonthWithoutFetch();

    await fetchRequests(
      resetPage: true,
    );
  }

  // ============================================================
  // CLEAR DATES
  // ============================================================

  Future<void> clearDates() async {
    startDate.value = null;
    endDate.value = null;

    await fetchRequests(
      resetPage: true,
    );
  }

  // ============================================================
  // CLEAR ALL FILTERS
  // ============================================================

  Future<void> clearAllFilters() async {
    selectedStatus.value = 'ALL';

    startDate.value = null;
    endDate.value = null;

    await fetchRequests(
      resetPage: true,
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  void _applyPagination(
    dynamic rawPagination,
  ) {
    if (rawPagination is! Map) {
      total.value = requests.length;

      totalPages.value = requests.isEmpty ? 0 : 1;

      hasNextPage.value = false;

      hasPreviousPage.value = false;

      return;
    }

    final Map<String, dynamic> pagination = Map<String, dynamic>.from(
      rawPagination,
    );

    page.value = _toInt(
          pagination['page'],
        ) ??
        page.value;

    limit.value = _toInt(
          pagination['limit'],
        ) ??
        limit.value;

    total.value = _toInt(
          pagination['total'],
        ) ??
        requests.length;

    totalPages.value = _toInt(
          pagination['totalPages'],
        ) ??
        _toInt(
          pagination['total_pages'],
        ) ??
        0;

    hasNextPage.value = page.value < totalPages.value;

    hasPreviousPage.value = page.value > 1;

    print(
      '[AttendanceEditReport] '
      'page=${page.value}, '
      'limit=${limit.value}, '
      'total=${total.value}, '
      'totalPages=${totalPages.value}',
    );
  }

  void _resetPagination() {
    page.value = 1;

    total.value = 0;
    totalPages.value = 0;

    hasNextPage.value = false;
    hasPreviousPage.value = false;
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  void _calculateSummary() {
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    for (final Map<String, dynamic> request in requests) {
      final String status =
          (request['request_status'] ?? '').toString().trim().toUpperCase();

      switch (status) {
        case 'PENDING':
          pending++;
          break;

        case 'APPROVED':
          approved++;
          break;

        case 'REJECTED':
        case 'DECLINED':
          rejected++;
          break;
      }
    }

    pendingCount.value = pending;

    approvedCount.value = approved;

    rejectedCount.value = rejected;

    print(
      '[AttendanceEditReport] '
      'Pending=$pending, '
      'Approved=$approved, '
      'Rejected=$rejected',
    );
  }

  void _resetSummary() {
    pendingCount.value = 0;
    approvedCount.value = 0;
    rejectedCount.value = 0;
  }

  // ============================================================
  // GET REQUEST BY ID
  // ============================================================

  Map<String, dynamic>? getRequestById(
    dynamic requestId,
  ) {
    for (final Map<String, dynamic> request in requests) {
      if (request['id']?.toString() == requestId?.toString()) {
        return request;
      }
    }

    return null;
  }

  // ============================================================
  // HELPER - REQUEST STATUS
  // ============================================================

  String getRequestStatus(
    Map<String, dynamic> request,
  ) {
    return (request['request_status'] ?? '').toString().trim().toUpperCase();
  }

  // ============================================================
  // HELPER - IS PENDING
  // ============================================================

  bool isPending(
    Map<String, dynamic> request,
  ) {
    return getRequestStatus(
          request,
        ) ==
        'PENDING';
  }

  // ============================================================
  // HELPER - IS APPROVED
  // ============================================================

  bool isApproved(
    Map<String, dynamic> request,
  ) {
    return getRequestStatus(
          request,
        ) ==
        'APPROVED';
  }

  // ============================================================
  // HELPER - IS REJECTED
  // ============================================================

  bool isRejected(
    Map<String, dynamic> request,
  ) {
    final String status = getRequestStatus(request);

    return status == 'REJECTED' || status == 'DECLINED';
  }

  // ============================================================
  // HELPER - HAS CHECK IN CHANGE
  // ============================================================

  bool hasCheckInChange(
    Map<String, dynamic> request,
  ) {
    final dynamic requested = request['requested_check_in'];

    if (requested == null) {
      return false;
    }

    final String value = requested.toString().trim();

    return value.isNotEmpty && value.toLowerCase() != 'null';
  }

  // ============================================================
  // HELPER - HAS CHECK OUT CHANGE
  // ============================================================

  bool hasCheckOutChange(
    Map<String, dynamic> request,
  ) {
    final dynamic requested = request['requested_check_out'];

    if (requested == null) {
      return false;
    }

    final String value = requested.toString().trim();

    return value.isNotEmpty && value.toLowerCase() != 'null';
  }

  // ============================================================
  // HELPER - HAS STATUS CHANGE
  // ============================================================

  bool hasStatusChange(
    Map<String, dynamic> request,
  ) {
    final String current =
        (request['current_status'] ?? '').toString().trim().toLowerCase();

    final String requested =
        (request['requested_status'] ?? '').toString().trim().toLowerCase();

    if (requested.isEmpty) {
      return false;
    }

    return current != requested;
  }

  // ============================================================
  // INT CONVERTER
  // ============================================================

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

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // ERROR CLEANER
  // ============================================================

  String _cleanError(
    dynamic error,
  ) {
    String message = error.toString().trim();

    if (message.startsWith(
      'Exception: ',
    )) {
      message = message.substring(
        'Exception: '.length,
      );
    }

    return message.trim();
  }
}

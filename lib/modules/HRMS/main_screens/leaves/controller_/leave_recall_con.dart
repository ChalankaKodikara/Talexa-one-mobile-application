// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/controller_/leave_menu_con.dart';
import 'package:corehris/utils/api_error_handler.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:corehris/utils/app_snackbar.dart';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveRecallController extends GetxController {
  /// ============================================================
  /// SERVICES
  /// ============================================================

  final AuthService authService = AuthService();

  late final LeaveMenuController leaveMenuController;

  /// ============================================================
  /// UPCOMING APPROVED LEAVES
  /// ============================================================

  final RxList<Map<String, dynamic>> approvedLeaveData =
      <Map<String, dynamic>>[].obs;

  /// Leaves that are actually available to submit recall.
  final RxList<Map<String, dynamic>> availableRecallLeaves =
      <Map<String, dynamic>>[].obs;

  /// Filtered list displayed by LeaveRecallScreen.
  final RxList<Map<String, dynamic>> filteredLeaveData =
      <Map<String, dynamic>>[].obs;

  /// ============================================================
  /// RECALL REQUESTS
  /// ============================================================

  final RxList<Map<String, dynamic>> recallRequests =
      <Map<String, dynamic>>[].obs;

  /// Filtered list used by LeaveRecallStatusScreen.
  final RxList<Map<String, dynamic>> filteredRecallRequests =
      <Map<String, dynamic>>[].obs;

  /// leave_id -> latest recall request
  final RxMap<int, Map<String, dynamic>> recallByLeaveId =
      <int, Map<String, dynamic>>{}.obs;

  /// ============================================================
  /// COMMON STATE
  /// ============================================================

  final RxBool isLoading = false.obs;
  final RxBool isLoadingRecalls = false.obs;

  final RxInt recallingLeaveId = 0.obs;

  /// ============================================================
  /// RECALL SCREEN FILTERS
  /// ============================================================

  final RxString searchText = ''.obs;

  final TextEditingController searchController = TextEditingController();

  final Rx<DateTime?> startDate = Rx<DateTime?>(null);

  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  /// ============================================================
  /// STATUS SCREEN FILTERS
  /// ============================================================

  final RxString statusSearchText = ''.obs;

  final TextEditingController statusSearchController = TextEditingController();

  final RxString selectedRecallStatus = 'ALL'.obs;

  /// ============================================================
  /// WORKERS
  /// ============================================================

  Worker? _approvedLeavesWorker;

  /// ============================================================
  /// INIT
  /// ============================================================

  @override
  void onInit() {
    super.onInit();

    if (Get.isRegistered<LeaveMenuController>()) {
      leaveMenuController = Get.find<LeaveMenuController>();
    } else {
      leaveMenuController = Get.put(
        LeaveMenuController(),
      );
    }

    searchController.addListener(
      _onLeaveSearchChanged,
    );

    statusSearchController.addListener(
      _onStatusSearchChanged,
    );

    _approvedLeavesWorker = ever<List<Map<String, dynamic>>>(
      leaveMenuController.approvedLeaveRequests,
      (_) {
        syncApprovedLeaves();
      },
    );

    initialize();
  }

  /// ============================================================
  /// INITIALIZE
  /// ============================================================

  Future<void> initialize() async {
    try {
      isLoading.value = true;

      if (leaveMenuController.employeeId.value.isEmpty) {
        await leaveMenuController.initialize();
      }

      final employeeNo = leaveMenuController.employeeId.value.trim();

      if (employeeNo.isEmpty) {
        AppSnackbar.error(
          "Employee number not found. Please login again.",
        );

        return;
      }

      if (leaveMenuController.allLeaveRequests.isEmpty) {
        await leaveMenuController.fetchLatestLeaveRequests();
      }

      await fetchRecallRequests();

      syncApprovedLeaves();
      applyRecallStatusFilters();
    } catch (e) {
      print(
        "❌ Leave recall initialize error: $e",
      );

      AppSnackbar.error(
        ApiErrorHandler.getMessage(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ============================================================
  /// CLOSE
  /// ============================================================

  @override
  void onClose() {
    _approvedLeavesWorker?.dispose();

    searchController.removeListener(
      _onLeaveSearchChanged,
    );

    statusSearchController.removeListener(
      _onStatusSearchChanged,
    );

    searchController.dispose();
    statusSearchController.dispose();

    super.onClose();
  }

  /// ============================================================
  /// SEARCH LISTENERS
  /// ============================================================

  void _onLeaveSearchChanged() {
    searchText.value = searchController.text.trim();

    applyLeaveFilters();
  }

  void _onStatusSearchChanged() {
    statusSearchText.value = statusSearchController.text.trim();

    applyRecallStatusFilters();
  }

  /// ============================================================
  /// FETCH RECALL REQUESTS
  /// ============================================================

  Future<void> fetchRecallRequests() async {
    final employeeNo = leaveMenuController.employeeId.value.trim();

    if (employeeNo.isEmpty) {
      return;
    }

    try {
      isLoadingRecalls.value = true;

      final data = await authService.leave.fetchMyLeaveRecallRequests(
        employeeNo: employeeNo,
        page: 1,
        limit: 100,
      );

      /// --------------------------------------------------------
      /// NEWEST RECALL FIRST
      /// --------------------------------------------------------

      data.sort(
        (a, b) {
          final aDate = getRecallRequestedDate(a);

          final bDate = getRecallRequestedDate(b);

          if (aDate == null && bDate == null) {
            return 0;
          }

          if (aDate == null) {
            return 1;
          }

          if (bDate == null) {
            return -1;
          }

          return bDate.compareTo(
            aDate,
          );
        },
      );

      recallRequests.assignAll(
        data,
      );

      /// --------------------------------------------------------
      /// CREATE leave_id -> LATEST recall MAP
      /// --------------------------------------------------------

      final Map<int, Map<String, dynamic>> map = {};

      for (final request in data) {
        final leaveId = _toInt(
          request["leave_id"],
        );

        if (leaveId == null) {
          continue;
        }

        /// data already newest first
        if (!map.containsKey(
          leaveId,
        )) {
          map[leaveId] = request;
        }
      }

      recallByLeaveId.assignAll(
        map,
      );

      syncApprovedLeaves();
      applyRecallStatusFilters();
    } catch (e) {
      print(
        "❌ Fetch recall requests error: $e",
      );

      AppSnackbar.error(
        ApiErrorHandler.getMessage(e),
      );
    } finally {
      isLoadingRecalls.value = false;
    }
  }

  /// ============================================================
  /// REFRESH EVERYTHING
  /// ============================================================

  Future<void> refreshAll() async {
    if (isLoading.value) {
      return;
    }

    try {
      isLoading.value = true;

      if (leaveMenuController.employeeId.value.isEmpty) {
        await leaveMenuController.initialize();
      }

      await leaveMenuController.fetchLatestLeaveRequests();

      await fetchRecallRequests();

      syncApprovedLeaves();
      applyRecallStatusFilters();
    } catch (e) {
      print(
        "❌ Refresh leave recall error: $e",
      );

      AppSnackbar.error(
        ApiErrorHandler.getMessage(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshLeaves() async {
    await refreshAll();
  }

  Future<void> refreshRecallStatus() async {
    await fetchRecallRequests();
  }

  /// ============================================================
  /// UPCOMING APPROVED LEAVES
  /// ============================================================

  void syncApprovedLeaves() {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final data = List<Map<String, dynamic>>.from(
      leaveMenuController.approvedLeaveRequests,
    );

    /// ----------------------------------------------------------
    /// ONLY APPROVED + TODAY/FUTURE
    /// ----------------------------------------------------------

    final upcoming = data.where(
      (leave) {
        if (!isApprovedLeave(
          leave,
        )) {
          return false;
        }

        final date = getLeaveDate(
          leave,
        );

        if (date == null) {
          return false;
        }

        final normalized = DateTime(
          date.year,
          date.month,
          date.day,
        );

        return !normalized.isBefore(
          today,
        );
      },
    ).toList();

    /// Nearest upcoming leave first.
    upcoming.sort(
      (a, b) {
        final aDate = getLeaveDate(a);

        final bDate = getLeaveDate(b);

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return aDate.compareTo(
          bDate,
        );
      },
    );

    approvedLeaveData.assignAll(
      upcoming,
    );

    /// ----------------------------------------------------------
    /// LEAVE RECALL SCREEN
    ///
    /// Hide leaves that already have an active recall request.
    ///
    /// Rejected / cancelled recalls can be submitted again.
    /// ----------------------------------------------------------

    final available = upcoming.where(
      (leave) {
        if (isSpecialLeave(
          leave,
        )) {
          return false;
        }

        if (hasActiveRecallRequest(
          leave,
        )) {
          return false;
        }

        return true;
      },
    ).toList();

    availableRecallLeaves.assignAll(
      available,
    );

    applyLeaveFilters();
  }

  /// ============================================================
  /// IDS
  /// ============================================================

  int? getLeaveId(
    Map<String, dynamic> leave,
  ) {
    return _toInt(
      leave["id"] ?? leave["leave_id"] ?? leave["request_id"],
    );
  }

  int? getRecallRequestId(
    Map<String, dynamic> recall,
  ) {
    return _toInt(
      recall["id"],
    );
  }

  int? getRecallLeaveId(
    Map<String, dynamic> recall,
  ) {
    return _toInt(
      recall["leave_id"],
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

    return int.tryParse(
      value.toString(),
    );
  }

  /// ============================================================
  /// CATEGORY NAME
  /// ============================================================

  String getCategoryName(
    Map<String, dynamic> data,
  ) {
    final value = data["category_name"] ??
        data["leave_category_name"] ??
        data["leave_category"] ??
        data["category"];

    if (value == null) {
      return "Leave";
    }

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == "null") {
      return "Leave";
    }

    return text;
  }

  /// ============================================================
  /// NORMAL LEAVE STATUS
  /// ============================================================

  String getLeaveApprovalStatus(
    Map<String, dynamic> leave,
  ) {
    return (leave["approved_status_1"] ??
            leave["leave_status"] ??
            leave["status"] ??
            "")
        .toString()
        .trim()
        .toUpperCase();
  }

  bool isApprovedLeave(
    Map<String, dynamic> leave,
  ) {
    return getLeaveApprovalStatus(
          leave,
        ) ==
        "APPROVED";
  }

  String getLeaveApprovalText(
    Map<String, dynamic> leave,
  ) {
    final status = getLeaveApprovalStatus(
      leave,
    );

    switch (status) {
      case "APPROVED":
        return "Approved";

      case "PENDING":
      case "NOT APPROVED":
        return "Pending Approval";

      case "REJECTED":
        return "Rejected";

      default:
        return status.isEmpty
            ? "-"
            : formatStatus(
                status,
              );
    }
  }

  /// ============================================================
  /// LEAVE DATE
  /// ============================================================

  DateTime? getLeaveDate(
    Map<String, dynamic> leave,
  ) {
    final value = leave["requested_date"] ??
        leave["leave_date"] ??
        leave["start_date"] ??
        leave["from_date"];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String getLeaveDateText(
    Map<String, dynamic> leave,
  ) {
    final date = getLeaveDate(
      leave,
    );

    if (date == null) {
      return "-";
    }

    return formatDate(
      date,
    );
  }

  /// ============================================================
  /// NORMAL LEAVE REASON
  /// ============================================================

  String getLeaveReason(
    Map<String, dynamic> leave,
  ) {
    final value = leave["original_leave_reason"] ??
        leave["reason"] ??
        leave["leave_reason"] ??
        leave["reason_for_leave"] ??
        "";

    return _safeText(
      value,
    );
  }

  /// ============================================================
  /// SPECIAL LEAVE
  /// ============================================================

  bool isSpecialLeave(
    Map<String, dynamic> leave,
  ) {
    final category = getCategoryName(
      leave,
    ).toUpperCase();

    final type =
        (leave["leave_type"] ?? leave["leave_type_name"] ?? leave["type"] ?? "")
            .toString()
            .trim()
            .toUpperCase();

    return category == "SPECIAL" ||
        category.contains(
          "SPECIAL LEAVE",
        ) ||
        type == "SPECIAL" ||
        type.contains(
          "SPECIAL LEAVE",
        );
  }

  /// ============================================================
  /// GET LATEST RECALL FOR LEAVE
  /// ============================================================

  Map<String, dynamic>? getRecallForLeave(
    Map<String, dynamic> leave,
  ) {
    final leaveId = getLeaveId(
      leave,
    );

    if (leaveId == null) {
      return null;
    }

    return recallByLeaveId[leaveId];
  }

  /// ============================================================
  /// ACTIVE RECALL CHECK
  /// ============================================================

  bool hasActiveRecallRequest(
    Map<String, dynamic> leave,
  ) {
    final recall = getRecallForLeave(
      leave,
    );

    if (recall == null) {
      return false;
    }

    final status = getRecallStatus(
      recall,
    );

    /// Can request again if previous request failed/rejected.
    if (status == "REJECTED" ||
        status == "REJECTED_SUPERVISOR" ||
        status == "REJECTED_HR" ||
        status == "CANCELLED") {
      return false;
    }

    return status.isNotEmpty;
  }

  /// ============================================================
  /// RECALL STATUS
  /// ============================================================

  String getRecallStatus(
    Map<String, dynamic> recall,
  ) {
    return (recall["status"] ?? "").toString().trim().toUpperCase();
  }

  String getRecallStatusText(
    Map<String, dynamic> recall,
  ) {
    return formatStatus(
      getRecallStatus(
        recall,
      ),
    );
  }

  String formatStatus(
    String value,
  ) {
    final status = value.trim().toUpperCase();

    switch (status) {
      case "PENDING_SUPERVISOR":
        return "Pending Supervisor";

      case "PENDING_HR":
        return "Pending HR";

      case "PENDING":
        return "Pending";

      case "PROCESSING":
        return "Processing";

      case "APPROVED":
      case "RECALLED":
        return "Recalled";

      case "REJECTED_SUPERVISOR":
        return "Rejected by Supervisor";

      case "REJECTED_HR":
        return "Rejected by HR";

      case "REJECTED":
        return "Rejected";

      case "CANCELLED":
        return "Cancelled";

      default:
        if (status.isEmpty) {
          return "-";
        }

        return status.split("_").map(
          (word) {
            if (word.isEmpty) {
              return "";
            }

            return "${word[0]}${word.substring(1).toLowerCase()}";
          },
        ).join(" ");
    }
  }

  /// ============================================================
  /// SUPERVISOR STATUS
  /// ============================================================

  String getSupervisorStatus(
    Map<String, dynamic> recall,
  ) {
    final value = recall["supervisor_status"];

    if (value == null) {
      return "";
    }

    return value.toString().trim().toUpperCase();
  }

  String getSupervisorStatusText(
    Map<String, dynamic> recall,
  ) {
    final status = getSupervisorStatus(
      recall,
    );

    if (status.isEmpty) {
      return "Waiting";
    }

    return formatStatus(
      status,
    );
  }

  String getSupervisorReason(
    Map<String, dynamic> recall,
  ) {
    return _safeText(
      recall["supervisor_reason"],
    );
  }

  /// ============================================================
  /// HR STATUS
  /// ============================================================

  String getHrStatus(
    Map<String, dynamic> recall,
  ) {
    final value = recall["hr_status"];

    if (value == null) {
      return "";
    }

    return value.toString().trim().toUpperCase();
  }

  String getHrStatusText(
    Map<String, dynamic> recall,
  ) {
    final status = getHrStatus(
      recall,
    );

    if (status.isEmpty) {
      return "Waiting";
    }

    return formatStatus(
      status,
    );
  }

  String getHrReason(
    Map<String, dynamic> recall,
  ) {
    return _safeText(
      recall["hr_reason"],
    );
  }

  /// ============================================================
  /// CURRENT RECALL STAGE
  /// ============================================================

  String getRecallStage(
    Map<String, dynamic> recall,
  ) {
    final status = getRecallStatus(
      recall,
    );

    switch (status) {
      case "PENDING_SUPERVISOR":
        return "Supervisor Approval";

      case "PENDING_HR":
        return "HR Approval";

      case "APPROVED":
      case "RECALLED":
        return "Completed";

      case "REJECTED_SUPERVISOR":
        return "Supervisor Rejected";

      case "REJECTED_HR":
        return "HR Rejected";

      case "REJECTED":
        return "Rejected";

      case "CANCELLED":
        return "Cancelled";

      default:
        return formatStatus(
          status,
        );
    }
  }

  /// ============================================================
  /// RECALL REASON / REMARKS
  /// ============================================================

  String getRecallReason(
    Map<String, dynamic> recall,
  ) {
    return _safeText(
      recall["reason"],
    );
  }

  String getRecallRemarks(
    Map<String, dynamic> recall,
  ) {
    return _safeText(
      recall["remarks"],
    );
  }

  String getOriginalLeaveReasonFromRecall(
    Map<String, dynamic> recall,
  ) {
    return _safeText(
      recall["original_leave_reason"],
    );
  }

  /// ============================================================
  /// RECALL LEAVE DATE
  /// ============================================================

  DateTime? getRecallLeaveDate(
    Map<String, dynamic> recall,
  ) {
    final value = recall["leave_date"];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String getRecallLeaveDateText(
    Map<String, dynamic> recall,
  ) {
    final date = getRecallLeaveDate(
      recall,
    );

    if (date == null) {
      return "-";
    }

    return formatDate(
      date,
    );
  }

  /// ============================================================
  /// REQUESTED DATE
  /// ============================================================

  DateTime? getRecallRequestedDate(
    Map<String, dynamic> recall,
  ) {
    final value = recall["requested_at"] ?? recall["created_at"];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String getRecallRequestedDateText(
    Map<String, dynamic> recall,
  ) {
    final date = getRecallRequestedDate(
      recall,
    );

    if (date == null) {
      return "-";
    }

    return "${formatDate(date)} • ${formatTime(date)}";
  }

  /// ============================================================
  /// RECALLED AT
  /// ============================================================

  String getRecalledAtText(
    Map<String, dynamic> recall,
  ) {
    final value = recall["recalled_at"];

    if (value == null) {
      return "";
    }

    final date = DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return "";
    }

    return "${formatDate(date)} • ${formatTime(date)}";
  }

  /// ============================================================
  /// AVAILABLE LEAVE FILTER
  /// ============================================================

  void applyLeaveFilters() {
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      availableRecallLeaves,
    );

    if (startDate.value != null) {
      final start = _dateOnly(
        startDate.value!,
      );

      result = result.where(
        (leave) {
          final date = getLeaveDate(
            leave,
          );

          if (date == null) {
            return false;
          }

          return !_dateOnly(
            date,
          ).isBefore(
            start,
          );
        },
      ).toList();
    }

    if (endDate.value != null) {
      final end = _dateOnly(
        endDate.value!,
      );

      result = result.where(
        (leave) {
          final date = getLeaveDate(
            leave,
          );

          if (date == null) {
            return false;
          }

          return !_dateOnly(
            date,
          ).isAfter(
            end,
          );
        },
      ).toList();
    }

    final query = searchText.value.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where(
        (leave) {
          final category = getCategoryName(
            leave,
          ).toLowerCase();

          final reason = getLeaveReason(
            leave,
          ).toLowerCase();

          final date = getLeaveDateText(
            leave,
          ).toLowerCase();

          return category.contains(
                query,
              ) ||
              reason.contains(
                query,
              ) ||
              date.contains(
                query,
              );
        },
      ).toList();
    }

    filteredLeaveData.assignAll(
      result,
    );
  }

  /// ============================================================
  /// STATUS SCREEN FILTER
  /// ============================================================

  void applyRecallStatusFilters() {
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      recallRequests,
    );

    final selected = selectedRecallStatus.value.trim().toUpperCase();

    if (selected != "ALL") {
      result = result.where(
        (recall) {
          final status = getRecallStatus(
            recall,
          );

          /// Group all rejected statuses together.
          if (selected == "REJECTED") {
            return status == "REJECTED" ||
                status == "REJECTED_SUPERVISOR" ||
                status == "REJECTED_HR";
          }

          /// Completed group.
          if (selected == "RECALLED") {
            return status == "RECALLED" || status == "APPROVED";
          }

          return status == selected;
        },
      ).toList();
    }

    final query = statusSearchText.value.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where(
        (recall) {
          final category = getCategoryName(
            recall,
          ).toLowerCase();

          final status = getRecallStatusText(
            recall,
          ).toLowerCase();

          final stage = getRecallStage(
            recall,
          ).toLowerCase();

          final reason = getRecallReason(
            recall,
          ).toLowerCase();

          final originalReason = getOriginalLeaveReasonFromRecall(
            recall,
          ).toLowerCase();

          final leaveDate = getRecallLeaveDateText(
            recall,
          ).toLowerCase();

          return category.contains(
                query,
              ) ||
              status.contains(
                query,
              ) ||
              stage.contains(
                query,
              ) ||
              reason.contains(
                query,
              ) ||
              originalReason.contains(
                query,
              ) ||
              leaveDate.contains(
                query,
              );
        },
      ).toList();
    }

    filteredRecallRequests.assignAll(
      result,
    );
  }

  void setRecallStatusFilter(
    String status,
  ) {
    selectedRecallStatus.value = status;

    applyRecallStatusFilters();
  }

  /// ============================================================
  /// CLEAR FILTERS
  /// ============================================================

  void clearLeaveFilters() {
    startDate.value = null;
    endDate.value = null;

    searchController.clear();

    searchText.value = "";

    applyLeaveFilters();
  }

  void clearRecallStatusFilters() {
    statusSearchController.clear();

    statusSearchText.value = "";

    selectedRecallStatus.value = "ALL";

    applyRecallStatusFilters();
  }

  /// ============================================================
  /// DATE PICKER
  /// ============================================================

  Future<void> pickDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    DateTime initialDate;

    if (isStart) {
      initialDate = startDate.value ?? today;
    } else {
      initialDate = endDate.value ?? startDate.value ?? today;
    }

    if (initialDate.isBefore(
      today,
    )) {
      initialDate = today;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(
        2100,
      ),
    );

    if (picked == null) {
      return;
    }

    if (isStart) {
      startDate.value = picked;

      if (endDate.value != null &&
          _dateOnly(
            endDate.value!,
          ).isBefore(
            _dateOnly(
              picked,
            ),
          )) {
        endDate.value = null;
      }
    } else {
      if (startDate.value != null &&
          _dateOnly(
            picked,
          ).isBefore(
            _dateOnly(
              startDate.value!,
            ),
          )) {
        AppSnackbar.error(
          "End date cannot be before start date.",
        );

        return;
      }

      endDate.value = picked;
    }

    applyLeaveFilters();
  }

  DateTime _dateOnly(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  /// ============================================================
  /// CAN RECALL
  /// ============================================================

  bool canRecall(
    Map<String, dynamic> leave,
  ) {
    if (!isApprovedLeave(
      leave,
    )) {
      return false;
    }

    if (isSpecialLeave(
      leave,
    )) {
      return false;
    }

    final date = getLeaveDate(
      leave,
    );

    if (date == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final leaveDate = _dateOnly(
      date,
    );

    if (leaveDate.isBefore(
      today,
    )) {
      return false;
    }

    if (hasActiveRecallRequest(
      leave,
    )) {
      return false;
    }

    return true;
  }

  String getRecallUnavailableReason(
    Map<String, dynamic> leave,
  ) {
    if (!isApprovedLeave(
      leave,
    )) {
      return "Only approved leave can be recalled.";
    }

    if (isSpecialLeave(
      leave,
    )) {
      return "Special leave cannot be recalled.";
    }

    final date = getLeaveDate(
      leave,
    );

    if (date == null) {
      return "Leave date is not available.";
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    if (_dateOnly(
      date,
    ).isBefore(
      today,
    )) {
      return "Passed leave cannot be recalled.";
    }

    if (hasActiveRecallRequest(
      leave,
    )) {
      final recall = getRecallForLeave(
        leave,
      );

      if (recall != null) {
        return "Recall status: ${getRecallStatusText(recall)}";
      }

      return "A recall request already exists.";
    }

    return "This leave cannot be recalled.";
  }

  /// ============================================================
  /// OPEN RECALL DIALOG
  /// ============================================================

  Future<void> openRecallDialog({
    required BuildContext context,
    required Map<String, dynamic> leave,
  }) async {
    if (!canRecall(
      leave,
    )) {
      AppSnackbar.error(
        getRecallUnavailableReason(
          leave,
        ),
      );

      return;
    }

    final reasonController = TextEditingController();

    final remarksController = TextEditingController();

    try {
      final result = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            title: const Text(
              "Recall Leave",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF6F8FC,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getCategoryName(
                            leave,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          getLeaveDateText(
                            leave,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(
                              0xFF6B7280,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  TextField(
                    controller: reasonController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: "Recall reason *",
                      hintText: "Enter reason for recalling this leave",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextField(
                    controller: remarksController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: "Remarks",
                      hintText: "Additional information (optional)",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                },
                child: const Text(
                  "Cancel",
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final reason = reasonController.text.trim();

                  if (reason.isEmpty) {
                    AppSnackbar.error(
                      "Please enter a recall reason.",
                    );

                    return;
                  }

                  Navigator.of(
                    dialogContext,
                  ).pop(
                    {
                      "reason": reason,
                      "remarks": remarksController.text.trim(),
                    },
                  );
                },
                child: const Text(
                  "Continue",
                ),
              ),
            ],
          );
        },
      );

      if (result == null || !context.mounted) {
        return;
      }

      final confirmed = await AppAlert.confirm(
        context: context,
        title: "Confirm Leave Recall",
        message: "Are you sure you want to submit this leave recall request?",
        confirmText: "Submit",
        isDestructive: false,
      );

      if (confirmed != true) {
        return;
      }

      await submitRecall(
        leave: leave,
        reason: result["reason"] ?? "",
        remarks: result["remarks"] ?? "",
      );
    } finally {
      reasonController.dispose();
      remarksController.dispose();
    }
  }

  /// ============================================================
  /// SUBMIT RECALL
  /// ============================================================

  Future<bool> submitRecall({
    required Map<String, dynamic> leave,
    required String reason,
    required String remarks,
  }) async {
    final leaveId = getLeaveId(
      leave,
    );

    if (leaveId == null || leaveId <= 0) {
      AppSnackbar.error(
        "Invalid leave ID.",
      );

      return false;
    }

    if (!canRecall(
      leave,
    )) {
      AppSnackbar.error(
        getRecallUnavailableReason(
          leave,
        ),
      );

      return false;
    }

    final employeeNo = leaveMenuController.employeeId.value.trim();

    if (employeeNo.isEmpty) {
      AppSnackbar.error(
        "Employee number not found.",
      );

      return false;
    }

    final cleanReason = reason.trim();

    if (cleanReason.isEmpty) {
      AppSnackbar.error(
        "Recall reason is required.",
      );

      return false;
    }

    if (recallingLeaveId.value == leaveId) {
      return false;
    }

    try {
      recallingLeaveId.value = leaveId;

      final dio.Response? response = await authService.leave.requestLeaveRecall(
        leaveId: leaveId,
        employeeNo: employeeNo,
        reason: cleanReason,
        remarks: remarks.trim(),
      );

      if (response == null) {
        throw Exception(
          "No response received from server.",
        );
      }

      final statusCode = response.statusCode ?? 0;

      final body = response.data;

      if (statusCode < 200 || statusCode >= 300) {
        throw Exception(
          _getBackendMessage(
            body,
            fallback: "Failed to submit leave recall request.",
          ),
        );
      }

      if (body is Map && body["success"] == false) {
        throw Exception(
          _getBackendMessage(
            body,
            fallback: "Failed to submit leave recall request.",
          ),
        );
      }

      AppSnackbar.success(
        "Recall Requested",
        _getBackendMessage(
          body,
          fallback: "Your leave recall request has been submitted.",
        ),
      );

      /// Critical:
      /// reload actual backend recall request.
      ///
      /// This gives PENDING_SUPERVISOR etc.
      await fetchRecallRequests();

      await leaveMenuController.fetchLatestLeaveRequests();

      syncApprovedLeaves();

      return true;
    } catch (e) {
      print(
        "❌ Submit recall error: $e",
      );

      AppSnackbar.error(
        ApiErrorHandler.getMessage(
          e,
        ),
      );

      return false;
    } finally {
      recallingLeaveId.value = 0;
    }
  }

  /// ============================================================
  /// HELPERS
  /// ============================================================

  String _safeText(
    dynamic value,
  ) {
    if (value == null) {
      return "";
    }

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == "null") {
      return "";
    }

    return text;
  }

  String formatDate(
    DateTime date,
  ) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${date.day.toString().padLeft(2, '0')} "
        "${months[date.month - 1]} "
        "${date.year}";
  }

  String formatTime(
    DateTime date,
  ) {
    int hour = date.hour;

    final minute = date.minute.toString().padLeft(
          2,
          "0",
        );

    final period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return "$hour:$minute $period";
  }

  String _getBackendMessage(
    dynamic body, {
    required String fallback,
  }) {
    if (body is Map) {
      final value =
          body["message"] ?? body["error"] ?? body["developerMessage"];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }
}

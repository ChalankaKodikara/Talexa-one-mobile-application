// ignore_for_file: deprecated_member_use

import 'package:corehris/modules/HRMS/main_screens/reports/controllers/attendance_edit_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AttendanceEditReportScreen extends StatefulWidget {
  const AttendanceEditReportScreen({
    super.key,
  });

  @override
  State<AttendanceEditReportScreen> createState() =>
      _AttendanceEditReportScreenState();
}

class _AttendanceEditReportScreenState
    extends State<AttendanceEditReportScreen> {
  late final AttendanceEditReportController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.put(
      AttendanceEditReportController(),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<AttendanceEditReportController>()) {
      Get.delete<AttendanceEditReportController>();
    }

    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate({
    required bool start,
  }) async {
    final DateTime initialDate = start
        ? controller.startDate.value ?? DateTime.now()
        : controller.endDate.value ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        final ThemeData theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primary2,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    if (start) {
      await controller.setStartDate(picked);
    } else {
      await controller.setEndDate(picked);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDark
                ? const [
                    Color(0xFF0B1220),
                    Color(0xFF101A2F),
                    Color(0xFF0F172A),
                  ]
                : const [
                    Color(0xFFF8FAFF),
                    Color(0xFFF3F6FB),
                    Color(0xFFEEF3FA),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary2,
                  onRefresh: controller.refreshRequests,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildEmployeeCard(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildDateFilters(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildQuickFilters(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildStatusFilters(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSummary(),
                      ),
                      Obx(() {
                        final bool isLoading = controller.isLoading.value;

                        final bool hasError = controller.hasError.value;

                        final List<Map<String, dynamic>> requestList =
                            controller.requests.toList();

                        final bool hasNextPage = controller.hasNextPage.value;

                        if (isLoading) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildLoading(),
                          );
                        }

                        if (hasError) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildError(),
                          );
                        }

                        if (requestList.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmpty(),
                          );
                        }

                        final int itemCount =
                            requestList.length + (hasNextPage ? 1 : 0);

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            2,
                            16,
                            24,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (
                                BuildContext context,
                                int index,
                              ) {
                                if (index == requestList.length) {
                                  return _buildLoadMore();
                                }

                                final Map<String, dynamic> record =
                                    requestList[index];

                                return _RequestCard(
                                  record: record,
                                  onTap: () {
                                    _showDetails(record);
                                  },
                                );
                              },
                              childCount: itemCount,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF2F6BFF),
            Color(0xFF4F46E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _headerButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: Get.back,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Track attendance correction requests',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _headerButton(
            icon: Icons.refresh_rounded,
            onTap: controller.refreshRequests,
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPLOYEE CARD
  // ============================================================

  Widget _buildEmployeeCard() {
    return Obx(() {
      final String employeeName = controller.employeeName.value;

      final String employeeId = controller.employeeId.value;

      return Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          10,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary2.withOpacity(0.10),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primary2,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeText(
                      employeeName,
                      fallback: 'Employee',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _safeText(
                      employeeId,
                      fallback: 'Employee ID unavailable',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // DATE FILTERS
  // ============================================================

  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final DateTime? startDate = controller.startDate.value;

              return _DateSelector(
                label: 'From',
                date: startDate,
                onTap: () {
                  _pickDate(
                    start: true,
                  );
                },
              );
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() {
              final DateTime? endDate = controller.endDate.value;

              return _DateSelector(
                label: 'To',
                date: endDate,
                onTap: () {
                  _pickDate(
                    start: false,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK FILTERS
  // ============================================================

  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        2,
        16,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickButton(
              label: 'Last 7 Days',
              icon: Icons.date_range_rounded,
              onTap: controller.setLastSevenDays,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickButton(
              label: 'This Month',
              icon: Icons.calendar_view_month_rounded,
              onTap: controller.setCurrentMonth,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: controller.clearDates,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.filter_alt_off_rounded,
                color: Color(0xFFDC2626),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS FILTERS
  // ============================================================

  Widget _buildStatusFilters() {
    return Obx(() {
      final String selectedStatus = controller.selectedStatus.value;

      final List<String> options = List<String>.from(
        controller.statusOptions,
      );

      return SizedBox(
        height: 50,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          itemCount: options.length,
          separatorBuilder: (
            BuildContext context,
            int index,
          ) {
            return const SizedBox(width: 8);
          },
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final String value = options[index];

            final bool selected = selectedStatus == value;

            return ChoiceChip(
              selected: selected,
              label: Text(
                _prettyText(value),
              ),
              onSelected: (_) {
                controller.setStatus(value);
              },
              selectedColor: AppColors.primary2,
              backgroundColor:
                  _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: selected
                    ? AppColors.primary2
                    : _isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            );
          },
        ),
      );
    });
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Obx(() {
      final int total = controller.total.value;

      final int pending = controller.pendingCount.value;

      final int approved = controller.approvedCount.value;

      final int rejected = controller.rejectedCount.value;

      return SizedBox(
        height: 102,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            14,
          ),
          children: [
            _SummaryCard(
              label: 'Total',
              value: total,
              icon: Icons.receipt_long_rounded,
              foreground: const Color(0xFF2563EB),
              background: const Color(0xFFDBEAFE),
            ),
            _SummaryCard(
              label: 'Pending',
              value: pending,
              icon: Icons.pending_actions_rounded,
              foreground: const Color(0xFFD97706),
              background: const Color(0xFFFEF3C7),
            ),
            _SummaryCard(
              label: 'Approved',
              value: approved,
              icon: Icons.check_circle_rounded,
              foreground: const Color(0xFF16A34A),
              background: const Color(0xFFDCFCE7),
            ),
            _SummaryCard(
              label: 'Rejected',
              value: rejected,
              icon: Icons.cancel_rounded,
              foreground: const Color(0xFFDC2626),
              background: const Color(0xFFFEE2E2),
            ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // LOAD MORE
  // ============================================================

  Widget _buildLoadMore() {
    return Obx(() {
      final bool loading = controller.isLoadingMore.value;

      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Center(
          child: loading
              ? CircularProgressIndicator(
                  color: AppColors.primary2,
                )
              : OutlinedButton.icon(
                  onPressed: controller.loadMore,
                  icon: const Icon(
                    Icons.expand_more_rounded,
                  ),
                  label: const Text(
                    'Load More',
                  ),
                ),
        ),
      );
    });
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showDetails(
    Map<String, dynamic> record,
  ) {
    final _StatusData status = _statusData(
      record['request_status'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (
        BuildContext bottomSheetContext,
      ) {
        return Container(
          margin: const EdgeInsets.only(
            top: 40,
          ),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.90,
              minChildSize: 0.55,
              maxChildSize: 0.96,
              builder: (
                BuildContext context,
                ScrollController scrollController,
              ) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailsHeader(
                        record,
                        status,
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(
                        'Request Information',
                      ),
                      const SizedBox(height: 10),
                      _detailsCard(
                        children: [
                          _detailRow(
                            icon: Icons.fingerprint_rounded,
                            title: 'Request ID',
                            value: _safeText(
                              record['id'],
                            ),
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.badge_rounded,
                            title: 'Employee ID',
                            value: _safeText(
                              record['employee_id'],
                            ),
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.calendar_month_rounded,
                            title: 'Work Date',
                            value: _formatDate(
                              record['work_date_local'],
                            ),
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.edit_calendar_rounded,
                            title: 'Adjustment Type',
                            value: _prettyText(
                              record['adjustment_type'],
                            ),
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.person_rounded,
                            title: 'Requested By',
                            value: _safeText(
                              record['requested_by'],
                            ),
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.schedule_rounded,
                            title: 'Requested At',
                            value: _formatDateTime(
                              record['requested_at'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        'Attendance Changes',
                      ),
                      const SizedBox(height: 10),
                      _detailsCard(
                        children: [
                          _changeRow(
                            icon: Icons.login_rounded,
                            title: 'Check In',
                            currentValue: _formatTime(
                              record['current_check_in'],
                            ),
                            requestedValue: _formatTime(
                              record['requested_check_in'],
                            ),
                          ),
                          _divider(),
                          _changeRow(
                            icon: Icons.logout_rounded,
                            title: 'Check Out',
                            currentValue: _formatTime(
                              record['current_check_out'],
                            ),
                            requestedValue: _formatTime(
                              record['requested_check_out'],
                            ),
                          ),
                          _divider(),
                          _changeRow(
                            icon: Icons.published_with_changes_rounded,
                            title: 'Attendance Status',
                            currentValue: _prettyText(
                              record['current_status'],
                            ),
                            requestedValue: _prettyText(
                              record['requested_status'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        'Reason',
                      ),
                      const SizedBox(height: 10),
                      _detailsCard(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailIcon(
                                Icons.notes_rounded,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _safeText(
                                    record['reason'],
                                    fallback: 'No reason provided',
                                  ),
                                  style: const TextStyle(
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_hasText(
                            record['reviewed_by'],
                          ) ||
                          _hasText(
                            record['reviewed_at'],
                          ) ||
                          _hasText(
                            record['review_comment'],
                          )) ...[
                        const SizedBox(height: 20),
                        _sectionTitle(
                          'Review Information',
                        ),
                        const SizedBox(height: 10),
                        _detailsCard(
                          children: [
                            _detailRow(
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'Reviewed By',
                              value: _safeText(
                                record['reviewed_by'],
                              ),
                            ),
                            _divider(),
                            _detailRow(
                              icon: Icons.schedule_rounded,
                              title: 'Reviewed At',
                              value: _formatDateTime(
                                record['reviewed_at'],
                              ),
                            ),
                            if (_hasText(
                              record['review_comment'],
                            )) ...[
                              _divider(),
                              _detailRow(
                                icon: Icons.comment_rounded,
                                title: 'Review Comment',
                                value: _safeText(
                                  record['review_comment'],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (_hasText(
                        record['attachment_url'],
                      )) ...[
                        const SizedBox(height: 20),
                        _sectionTitle(
                          'Attachment',
                        ),
                        const SizedBox(height: 10),
                        _detailsCard(
                          children: [
                            _detailRow(
                              icon: Icons.attach_file_rounded,
                              title: 'Attachment',
                              value: _safeText(
                                record['attachment_url'],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      _sectionTitle(
                        'System Information',
                      ),
                      const SizedBox(height: 10),
                      _detailsCard(
                        children: [
                          _detailRow(
                            icon: Icons.tag_rounded,
                            title: 'Attendance ID',
                            value: _safeText(
                              record['attendance_id'],
                            ),
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.business_rounded,
                            title: 'Organization ID',
                            value: _safeText(
                              record['organization_id'],
                            ),
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.add_circle_outline_rounded,
                            title: 'Created At',
                            value: _formatDateTime(
                              record['created_at'],
                            ),
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.update_rounded,
                            title: 'Updated At',
                            value: _formatDateTime(
                              record['updated_at'],
                            ),
                          ),
                          if (_hasText(
                            record['applied_at'],
                          )) ...[
                            _divider(),
                            _detailRow(
                              icon: Icons.done_all_rounded,
                              title: 'Applied At',
                              value: _formatDateTime(
                                record['applied_at'],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsHeader(
    Map<String, dynamic> record,
    _StatusData status,
  ) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: status.background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            status.icon,
            color: status.foreground,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(
                  record['work_date_local'],
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _prettyText(
                  record['adjustment_type'],
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 9),
              _StatusChip(
                label: status.label,
                foreground: status.foreground,
                background: status.background,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHANGE ROW
  // ============================================================

  Widget _changeRow({
    required IconData icon,
    required String title,
    required String currentValue,
    required String requestedValue,
  }) {
    final bool noChange = requestedValue == '--';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          currentValue,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requested',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          noChange ? 'No change' : requestedValue,
                          style: TextStyle(
                            color: noChange
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF2563EB),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAILS COMPONENTS
  // ============================================================

  Widget _detailsCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _isDark ? Colors.white.withOpacity(0.045) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDark
              ? Colors.white.withOpacity(0.07)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailIcon(
    IconData icon,
  ) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary2.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 18,
        color: AppColors.primary2,
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Divider(
        height: 1,
        color:
            _isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary2,
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading attendance requests...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Obx(() {
      final String message = controller.errorMessage.value;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load attendance requests',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: controller.refreshRequests,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Try Again',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary2,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(
                Icons.edit_calendar_rounded,
                color: Color(0xFF2563EB),
                size: 36,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'No attendance requests',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No requests were found for the selected filters.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _safeText(
    dynamic value, {
    String fallback = '--',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'undefined') {
      return fallback;
    }

    return text;
  }

  static bool _hasText(
    dynamic value,
  ) {
    return _safeText(
      value,
      fallback: '',
    ).isNotEmpty;
  }

  static String _prettyText(
    dynamic value,
  ) {
    final String raw = _safeText(value);

    if (raw == '--') {
      return raw;
    }

    return raw.replaceAll('_', ' ').toLowerCase().split(' ').map(
      (String word) {
        if (word.isEmpty) {
          return '';
        }

        return '${word[0].toUpperCase()}${word.substring(1)}';
      },
    ).join(' ');
  }

  static String _formatDate(
    dynamic value,
  ) {
    final String raw = _safeText(
      value,
      fallback: '',
    );

    if (raw.isEmpty) {
      return '--';
    }

    final DateTime? parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    return DateFormat(
      'EEE, dd MMM yyyy',
    ).format(parsed);
  }

  static String _formatTime(
    dynamic value,
  ) {
    final String raw = _safeText(
      value,
      fallback: '',
    );

    if (raw.isEmpty) {
      return '--';
    }

    if (raw.contains('T')) {
      final DateTime? parsed = DateTime.tryParse(raw);

      if (parsed != null) {
        return DateFormat(
          'hh:mm a',
        ).format(parsed);
      }
    }

    final List<String> parts = raw.split(':');

    if (parts.length >= 2) {
      final int? hour = int.tryParse(parts[0]);

      final int? minute = int.tryParse(parts[1]);

      if (hour != null && minute != null) {
        return DateFormat(
          'hh:mm a',
        ).format(
          DateTime(
            2000,
            1,
            1,
            hour,
            minute,
          ),
        );
      }
    }

    return raw;
  }

  static String _formatDateTime(
    dynamic value,
  ) {
    final String raw = _safeText(
      value,
      fallback: '',
    );

    if (raw.isEmpty) {
      return '--';
    }

    final DateTime? parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    return DateFormat(
      'dd MMM yyyy • hh:mm a',
    ).format(
      parsed.toLocal(),
    );
  }

  static _StatusData _statusData(
    dynamic value,
  ) {
    final String status = _safeText(
      value,
      fallback: 'PENDING',
    ).toUpperCase();

    switch (status) {
      case 'APPROVED':
        return const _StatusData(
          label: 'Approved',
          icon: Icons.check_circle_rounded,
          foreground: Color(0xFF16A34A),
          background: Color(0xFFDCFCE7),
        );

      case 'REJECTED':
      case 'DECLINED':
        return const _StatusData(
          label: 'Rejected',
          icon: Icons.cancel_rounded,
          foreground: Color(0xFFDC2626),
          background: Color(0xFFFEE2E2),
        );

      default:
        return const _StatusData(
          label: 'Pending',
          icon: Icons.pending_actions_rounded,
          foreground: Color(0xFFD97706),
          background: Color(0xFFFEF3C7),
        );
    }
  }
}

// ============================================================
// REQUEST CARD
// ============================================================

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.record,
    required this.onTap,
  });

  final Map<String, dynamic> record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final _StatusData status = _AttendanceEditReportScreenState._statusData(
      record['request_status'],
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: status.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        status.icon,
                        color: status.foreground,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _AttendanceEditReportScreenState._formatDate(
                              record['work_date_local'],
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _StatusChip(
                                label: status.label,
                                foreground: status.foreground,
                                background: status.background,
                              ),
                              _StatusChip(
                                label: _AttendanceEditReportScreenState
                                    ._prettyText(
                                  record['adjustment_type'],
                                ),
                                foreground: const Color(
                                  0xFF2563EB,
                                ),
                                background: const Color(
                                  0xFFDBEAFE,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _MiniChangeBox(
                        label: 'Check In',
                        current: _AttendanceEditReportScreenState._formatTime(
                          record['current_check_in'],
                        ),
                        requested: _AttendanceEditReportScreenState._formatTime(
                          record['requested_check_in'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniChangeBox(
                        label: 'Check Out',
                        current: _AttendanceEditReportScreenState._formatTime(
                          record['current_check_out'],
                        ),
                        requested: _AttendanceEditReportScreenState._formatTime(
                          record['requested_check_out'],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MiniChangeBox(
                  label: 'Attendance Status',
                  current: _AttendanceEditReportScreenState._prettyText(
                    record['current_status'],
                  ),
                  requested: _AttendanceEditReportScreenState._prettyText(
                    record['requested_status'],
                  ),
                ),
                if (_AttendanceEditReportScreenState._hasText(
                  record['reason'],
                )) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(
                              0.035,
                            )
                          : const Color(
                              0xFFF8FAFC,
                            ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _AttendanceEditReportScreenState._safeText(
                              record['reason'],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MINI CHANGE BOX
// ============================================================

class _MiniChangeBox extends StatelessWidget {
  const _MiniChangeBox({
    required this.label,
    required this.current,
    required this.requested,
  });

  final String label;
  final String current;
  final String requested;

  @override
  Widget build(BuildContext context) {
    final bool noChange = requested == '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.035)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current: $current',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            noChange ? 'Requested: No change' : 'Requested: $requested',
            style: TextStyle(
              fontSize: 11,
              color:
                  noChange ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATE SELECTOR
// ============================================================

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.primary2.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary2,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date == null
                          ? 'Select'
                          : DateFormat(
                              'dd MMM yyyy',
                            ).format(date!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// QUICK BUTTON
// ============================================================

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary2.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primary2,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary2,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 122,
      margin: const EdgeInsets.only(
        right: 10,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: foreground,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATUS CHIP
// ============================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// STATUS MODEL
// ============================================================

class _StatusData {
  const _StatusData({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
}

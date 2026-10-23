// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:corehris/modules/HRMS/main_screens/reports/controllers/attendance_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AttendanceReportScreen extends StatelessWidget {
  AttendanceReportScreen({super.key});

  final AttendanceReportController controller =
      Get.put(AttendanceReportController());

  Future<void> _pickDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final initialDate = isStart
        ? controller.startDate.value ?? DateTime.now()
        : controller.endDate.value ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final theme = Theme.of(context);

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

    if (isStart) {
      await controller.setStartDate(picked);
    } else {
      await controller.setEndDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
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
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshAttendance,
                  color: AppColors.primary2,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildEmployeeSection(context),
                      ),
                      SliverToBoxAdapter(
                        child: _buildDateFilters(context),
                      ),
                      SliverToBoxAdapter(
                        child: _buildQuickFilters(context),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSummarySection(context),
                      ),
                      Obx(() {
                        if (controller.isLoading.value) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildLoadingState(context),
                          );
                        }

                        if (controller.hasError.value) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildErrorState(context),
                          );
                        }

                        if (controller.attendanceData.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(context),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final record = controller.attendanceData[index];

                                return _AttendanceRecordCard(
                                  record: record,
                                  onTap: () =>
                                      _showAttendanceDetails(context, record),
                                );
                              },
                              childCount: controller.attendanceData.length,
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
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
      child: Column(
        children: [
          Row(
            children: [
              _headerIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: Get.back,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Report',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Review attendance, working time and locations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              _headerIconButton(
                icon: Icons.refresh_rounded,
                onTap: controller.refreshAttendance,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(
      () => Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
                      controller.employeeName.value,
                      fallback: 'Employee',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _safeText(
                      controller.username.value,
                      fallback: 'Employee number unavailable',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _DateSelector(
                label: 'Start Date',
                date: controller.startDate.value,
                onTap: () => _pickDate(
                  context,
                  isStart: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(
              () => _DateSelector(
                label: 'End Date',
                date: controller.endDate.value,
                onTap: () => _pickDate(
                  context,
                  isStart: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _QuickFilterButton(
              label: 'Last 7 Days',
              icon: Icons.date_range_rounded,
              onTap: controller.setLastSevenDays,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickFilterButton(
              label: 'This Month',
              icon: Icons.calendar_view_month_rounded,
              onTap: controller.setCurrentMonth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: 102,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            _SummaryCard(
              label: 'Records',
              value: controller.totalRecords.value.toString(),
              icon: Icons.receipt_long_rounded,
              foregroundColor: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFDBEAFE),
            ),
            _SummaryCard(
              label: 'Present',
              value: controller.presentDays.value.toString(),
              icon: Icons.check_circle_rounded,
              foregroundColor: const Color(0xFF16A34A),
              backgroundColor: const Color(0xFFDCFCE7),
            ),
            _SummaryCard(
              label: 'Late',
              value: controller.lateDays.value.toString(),
              icon: Icons.schedule_rounded,
              foregroundColor: const Color(0xFFD97706),
              backgroundColor: const Color(0xFFFEF3C7),
            ),
            _SummaryCard(
              label: 'Absent',
              value: controller.absentDays.value.toString(),
              icon: Icons.cancel_rounded,
              foregroundColor: const Color(0xFFDC2626),
              backgroundColor: const Color(0xFFFEE2E2),
            ),
            _SummaryCard(
              label: 'Incomplete',
              value: controller.incompleteDays.value.toString(),
              icon: Icons.warning_amber_rounded,
              foregroundColor: const Color(0xFFEA580C),
              backgroundColor: const Color(0xFFFFEDD5),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceDetails(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final status = _safeText(record['status'], fallback: 'No attendance');
    final statusData = _statusData(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.only(top: 38),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.88,
              minChildSize: 0.55,
              maxChildSize: 0.96,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.18)
                                : Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildDetailsHeader(
                        context,
                        record: record,
                        statusData: statusData,
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle(context, 'Time Summary'),
                      const SizedBox(height: 10),
                      _detailsCard(
                        context,
                        children: [
                          _detailRow(
                            context,
                            icon: Icons.login_rounded,
                            title: 'Check In',
                            value: _formatTime(record['check_in_time']),
                            trailing: _safeText(record['check_in_type']),
                          ),
                          _divider(context),
                          _detailRow(
                            context,
                            icon: Icons.logout_rounded,
                            title: 'Check Out',
                            value: _formatTime(record['check_out_time']),
                            trailing: _safeText(record['check_out_type']),
                          ),
                          _divider(context),
                          _detailRow(
                            context,
                            icon: Icons.timelapse_rounded,
                            title: 'Worked Time',
                            value: _formatMinutes(record['worked_minutes']),
                          ),
                          _divider(context),
                          _detailRow(
                            context,
                            icon: Icons.schedule_rounded,
                            title: 'Late Time',
                            value: _formatMinutes(record['late_minutes']),
                          ),
                          _divider(context),
                          _detailRow(
                            context,
                            icon: Icons.directions_run_rounded,
                            title: 'Early Departure',
                            value: _formatMinutes(
                              record['early_departure_minutes'],
                            ),
                          ),
                          _divider(context),
                          _detailRow(
                            context,
                            icon: Icons.more_time_rounded,
                            title: 'Overtime',
                            value: _resolveOvertime(record),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(context, 'Punch Information'),
                      const SizedBox(height: 10),
                      _detailsCard(
                        context,
                        children: [
                          _detailRow(
                            context,
                            icon: Icons.input_rounded,
                            title: 'Check In Source',
                            value: _safeText(record['checkIN_source']),
                            trailing: _safeText(record['checkIN_mode']),
                          ),
                          _divider(context),
                          _detailRow(
                            context,
                            icon: Icons.output_rounded,
                            title: 'Check Out Source',
                            value: _safeText(record['checkOUT_source']),
                            trailing: _safeText(record['checkOUT_mode']),
                          ),
                          _divider(context),
                          _detailBooleanRow(
                            context,
                            icon: Icons.merge_type_rounded,
                            title: 'Mixed Source',
                            value: record['is_mixed_source'],
                          ),
                          _divider(context),
                          _detailBooleanRow(
                            context,
                            icon: Icons.login_rounded,
                            title: 'Missing Check In',
                            value: record['is_missing_checkin'],
                            negativeIsGood: true,
                          ),
                          _divider(context),
                          _detailBooleanRow(
                            context,
                            icon: Icons.logout_rounded,
                            title: 'Missing Check Out',
                            value: record['is_missing_checkout'],
                            negativeIsGood: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(context, 'Authorization'),
                      const SizedBox(height: 10),
                      _detailsCard(
                        context,
                        children: [
                          _detailRow(
                            context,
                            icon: Icons.verified_user_rounded,
                            title: 'Overall Authorization',
                            value: _safeText(
                              record['authorization_status'],
                              fallback: 'Not available',
                            ),
                          ),
                          _divider(context),
                          _detailRow(
                            context,
                            icon: Icons.login_rounded,
                            title: 'Check In Authorization',
                            value: _safeText(
                              record['checkIN_authorization_status'],
                              fallback: 'Not available',
                            ),
                          ),
                          _divider(context),
                          _detailRow(
                            context,
                            icon: Icons.logout_rounded,
                            title: 'Check Out Authorization',
                            value: _safeText(
                              record['checkOUT_authorization_status'],
                              fallback: 'Not available',
                            ),
                          ),
                          _divider(context),
                          _detailBooleanRow(
                            context,
                            icon: Icons.location_on_rounded,
                            title: 'Authorized Location',
                            value: record['is_authorized_location'],
                          ),
                          if (record['authorized_location_id'] != null) ...[
                            _divider(context),
                            _detailRow(
                              context,
                              icon: Icons.tag_rounded,
                              title: 'Authorized Location ID',
                              value:
                                  record['authorized_location_id'].toString(),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(context, 'Location Details'),
                      const SizedBox(height: 10),
                      _detailsCard(
                        context,
                        children: [
                          _addressBlock(
                            context,
                            icon: Icons.login_rounded,
                            title: 'Check In Address',
                            value: _safeText(
                              record['check_in_address'],
                              fallback: 'Address unavailable',
                            ),
                            authorizationStatus: _safeText(
                              record['check_in_address_authorized_status'],
                            ),
                          ),
                          _divider(context),
                          _addressBlock(
                            context,
                            icon: Icons.logout_rounded,
                            title: 'Check Out Address',
                            value: _safeText(
                              record['check_out_address'],
                              fallback: 'Address unavailable',
                            ),
                            authorizationStatus: _safeText(
                              record['check_out_address_authorized_status'],
                            ),
                          ),
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
    BuildContext context, {
    required Map<String, dynamic> record,
    required _AttendanceStatusData statusData,
  }) {
    final theme = Theme.of(context);

    final employeeName = _safeText(
      record['employee_fullname'],
      fallback: controller.employeeName.value,
    );

    final employeeNumber = _safeText(
      record['employee_no'],
      fallback: controller.username.value,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: statusData.backgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            statusData.icon,
            color: statusData.foregroundColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(record['date']),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$employeeName • $employeeNumber',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.68),
                ),
              ),
              const SizedBox(height: 9),
              _StatusChip(
                label: statusData.label,
                foregroundColor: statusData.foregroundColor,
                backgroundColor: statusData.backgroundColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary2),
            const SizedBox(height: 16),
            Text(
              'Loading attendance records...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load attendance',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: controller.refreshAttendance,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary2,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: Color(0xFF2563EB),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No attendance records',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No records were found for the selected date range.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }

  Widget _detailsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.045) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String trailing = '',
  }) {
    final theme = Theme.of(context);

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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.68),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _safeText(value),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing.trim().isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary2.withOpacity(0.09),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                trailing,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary2,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailBooleanRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required dynamic value,
    bool negativeIsGood = false,
  }) {
    final bool? booleanValue = _toNullableBool(value);

    String displayValue;
    Color color;

    if (booleanValue == null) {
      displayValue = 'Not available';
      color = const Color(0xFF64748B);
    } else if (booleanValue) {
      displayValue = 'Yes';
      color =
          negativeIsGood ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    } else {
      displayValue = 'No';
      color =
          negativeIsGood ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    }

    return Row(
      children: [
        _detailIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            displayValue,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressBlock(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String authorizationStatus,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.68),
                      ),
                    ),
                  ),
                  if (authorizationStatus.isNotEmpty)
                    _AuthorizationChip(status: authorizationStatus),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailIcon(IconData icon) {
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

  Widget _divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        color:
            isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _headerIconButton({
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

  static _AttendanceStatusData _statusData(String value) {
    final status = value.toLowerCase();

    if (status.contains('no attendance')) {
      return const _AttendanceStatusData(
        label: 'No Attendance',
        icon: Icons.event_busy_rounded,
        foregroundColor: Color(0xFF64748B),
        backgroundColor: Color(0xFFE2E8F0),
      );
    }

    if (status.contains('incomplete') || status.contains('missing')) {
      return const _AttendanceStatusData(
        label: 'Incomplete',
        icon: Icons.warning_amber_rounded,
        foregroundColor: Color(0xFFEA580C),
        backgroundColor: Color(0xFFFFEDD5),
      );
    }

    if (status.contains('late')) {
      return const _AttendanceStatusData(
        label: 'Late',
        icon: Icons.schedule_rounded,
        foregroundColor: Color(0xFFD97706),
        backgroundColor: Color(0xFFFEF3C7),
      );
    }

    if (status.contains('short')) {
      return const _AttendanceStatusData(
        label: 'Short Leave',
        icon: Icons.trending_down_rounded,
        foregroundColor: Color(0xFFEA580C),
        backgroundColor: Color(0xFFFFEDD5),
      );
    }

    if (status.contains('half')) {
      return const _AttendanceStatusData(
        label: 'Half Day',
        icon: Icons.hourglass_bottom_rounded,
        foregroundColor: Color(0xFFD97706),
        backgroundColor: Color(0xFFFEF3C7),
      );
    }

    if (status.contains('absent')) {
      return const _AttendanceStatusData(
        label: 'Absent',
        icon: Icons.cancel_rounded,
        foregroundColor: Color(0xFFDC2626),
        backgroundColor: Color(0xFFFEE2E2),
      );
    }

    if (status.contains('leave')) {
      return const _AttendanceStatusData(
        label: 'Leave',
        icon: Icons.event_available_rounded,
        foregroundColor: Color(0xFF7C3AED),
        backgroundColor: Color(0xFFEDE9FE),
      );
    }

    if (status.contains('pending')) {
      return const _AttendanceStatusData(
        label: 'Pending',
        icon: Icons.pending_actions_rounded,
        foregroundColor: Color(0xFFCA8A04),
        backgroundColor: Color(0xFFFEF9C3),
      );
    }

    return const _AttendanceStatusData(
      label: 'Present',
      icon: Icons.check_circle_rounded,
      foregroundColor: Color(0xFF16A34A),
      backgroundColor: Color(0xFFDCFCE7),
    );
  }

  static String _safeText(
    dynamic value, {
    String fallback = '--',
  }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'undefined') {
      return fallback;
    }

    return text;
  }

  static String _formatDate(dynamic value) {
    final raw = _safeText(value, fallback: '');

    if (raw.isEmpty) {
      return 'No attendance date';
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    return DateFormat('EEE, dd MMM yyyy').format(date);
  }

  static String _formatShortDate(dynamic value) {
    final raw = _safeText(value, fallback: '');

    if (raw.isEmpty) {
      return 'No date';
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    return DateFormat('dd MMM yyyy').format(date);
  }

  static String _formatTime(dynamic value) {
    final raw = _safeText(value, fallback: '');

    if (raw.isEmpty) {
      return '--';
    }

    try {
      final parsedDateTime = DateTime.tryParse(raw);

      if (parsedDateTime != null && raw.contains('-')) {
        return DateFormat('hh:mm a').format(parsedDateTime.toLocal());
      }

      final timeParts = raw.split(':');

      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);

        if (hour != null && minute != null) {
          final dateTime = DateTime(2000, 1, 1, hour, minute);

          return DateFormat('hh:mm a').format(dateTime);
        }
      }
    } catch (_) {}

    return raw;
  }

  static String _formatMinutes(dynamic value) {
    if (value == null) {
      return '--';
    }

    final totalMinutes = value is num
        ? value.round()
        : double.tryParse(value.toString())?.round();

    if (totalMinutes == null) {
      return '--';
    }

    if (totalMinutes <= 0) {
      return '0 min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '$minutes min';
    }

    if (minutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $minutes min';
  }

  static String _resolveOvertime(Map<String, dynamic> record) {
    final overtimeMinutes = record['overtime_minutes'];

    if (overtimeMinutes != null) {
      return _formatMinutes(overtimeMinutes);
    }

    return _safeText(record['OT']);
  }

  static bool? _toNullableBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value.toString().trim().toLowerCase();

    if (['true', '1', 'yes', 'authorized'].contains(normalized)) {
      return true;
    }

    if (['false', '0', 'no', 'unauthorized'].contains(normalized)) {
      return false;
    }

    return null;
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onTap;

  const _AttendanceRecordCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final status = AttendanceReportScreen._safeText(
      record['status'],
      fallback: 'No attendance',
    );

    final statusData = AttendanceReportScreen._statusData(status);

    final checkInTime =
        AttendanceReportScreen._formatTime(record['check_in_time']);

    final checkOutTime =
        AttendanceReportScreen._formatTime(record['check_out_time']);

    final workedTime =
        AttendanceReportScreen._formatMinutes(record['worked_minutes']);

    final missingCheckIn =
        AttendanceReportScreen._toNullableBool(record['is_missing_checkin']) ??
            false;

    final missingCheckOut =
        AttendanceReportScreen._toNullableBool(record['is_missing_checkout']) ??
            false;

    final mixedSource =
        AttendanceReportScreen._toNullableBool(record['is_mixed_source']) ??
            false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.035),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
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
                        color: statusData.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        statusData.icon,
                        color: statusData.foregroundColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AttendanceReportScreen._formatShortDate(
                              record['date'],
                            ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _StatusChip(
                                label: statusData.label,
                                foregroundColor: statusData.foregroundColor,
                                backgroundColor: statusData.backgroundColor,
                              ),
                              if (mixedSource)
                                const _StatusChip(
                                  label: 'Mixed Source',
                                  foregroundColor: Color(0xFF7C3AED),
                                  backgroundColor: Color(0xFFEDE9FE),
                                ),
                              if (missingCheckIn || missingCheckOut)
                                const _StatusChip(
                                  label: 'Missing Punch',
                                  foregroundColor: Color(0xFFDC2626),
                                  backgroundColor: Color(0xFFFEE2E2),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color:
                          theme.textTheme.bodySmall?.color?.withOpacity(0.38),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _TimeBox(
                        title: 'Check In',
                        value: checkInTime,
                        icon: Icons.login_rounded,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _TimeBox(
                        title: 'Check Out',
                        value: checkOutTime,
                        icon: Icons.logout_rounded,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _TimeBox(
                        title: 'Worked',
                        value: workedTime,
                        icon: Icons.timelapse_rounded,
                      ),
                    ),
                  ],
                ),
                if (_hasAdditionalInformation(record)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_hasText(record['checkIN_source']))
                        Expanded(
                          child: _SourceLabel(
                            icon: Icons.input_rounded,
                            value: AttendanceReportScreen._safeText(
                              record['checkIN_source'],
                            ),
                          ),
                        ),
                      if (_hasText(record['checkIN_source']) &&
                          _hasText(record['authorization_status']))
                        const SizedBox(width: 8),
                      if (_hasText(record['authorization_status']))
                        Expanded(
                          child: _AuthorizationChip(
                            status: AttendanceReportScreen._safeText(
                              record['authorization_status'],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasAdditionalInformation(Map<String, dynamic> record) {
    return _hasText(record['checkIN_source']) ||
        _hasText(record['authorization_status']);
  }

  bool _hasText(dynamic value) {
    if (value == null) {
      return false;
    }

    final text = value.toString().trim();

    return text.isNotEmpty && text.toLowerCase() != 'null';
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date == null
                          ? 'Select'
                          : DateFormat('dd MMM yyyy').format(date!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
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

class _QuickFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickFilterButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary2.withOpacity(0.12)
                : AppColors.primary2.withOpacity(0.08),
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
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary2,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 122,
      margin: const EdgeInsets.only(right: 10),
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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: foregroundColor,
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
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _TimeBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _TimeBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.035) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.primary2,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceLabel extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SourceLabel({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sensors_rounded,
            size: 14,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorizationChip extends StatelessWidget {
  final String status;

  const _AuthorizationChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final bool authorized = normalized.contains('authorized') &&
        !normalized.contains('unauthorized');

    final bool mixed = normalized.contains('mixed');

    final foregroundColor = mixed
        ? const Color(0xFF7C3AED)
        : authorized
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);

    final backgroundColor = mixed
        ? const Color(0xFFEDE9FE)
        : authorized
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _StatusChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AttendanceStatusData {
  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _AttendanceStatusData({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });
}

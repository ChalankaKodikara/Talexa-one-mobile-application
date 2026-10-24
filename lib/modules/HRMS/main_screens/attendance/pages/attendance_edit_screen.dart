import 'package:corehris/modules/HRMS/main_screens/attendance/controllers/attendance_edit_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AttendanceEditScreen extends StatefulWidget {
  const AttendanceEditScreen({
    super.key,
  });

  @override
  State<AttendanceEditScreen> createState() => _AttendanceEditScreenState();
}

class _AttendanceEditScreenState extends State<AttendanceEditScreen> {
  late final AttendanceEditController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.put(
      AttendanceEditController(),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<AttendanceEditController>()) {
      Get.delete<AttendanceEditController>();
    }

    super.dispose();
  }

  // ============================================================
  // THEME
  // ============================================================

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background => Theme.of(context).scaffoldBackgroundColor;

  Color get _surface => Theme.of(context).colorScheme.surface;

  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  Color get _textSecondary =>
      _isDark ? Colors.white70 : AppColors.textColorSecondary;

  Color get _border =>
      _isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE6EAF0);

  Color get _fieldBackground =>
      _isDark ? const Color(0xFF1A2236) : const Color(0xFFF8FAFC);

  Color get _mutedSurface =>
      _isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F9FC);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        bool didPop,
        dynamic result,
      ) async {
        if (didPop) return;

        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: _background,

        // ======================================================
        // APP BAR
        // ======================================================

        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _surface,
          surfaceTintColor: _surface,
          foregroundColor: _textPrimary,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
            ),
          ),
          title: Text(
            'Attendance Adjustment',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Obx(
              () {
                if (!controller.hasChanges.value) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(
                    right: 14,
                    top: 14,
                    bottom: 14,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(
                      alpha: _isDark ? 0.14 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Unsaved',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

        // ======================================================
        // BODY
        // ======================================================

        body: Obx(
          () {
            if (controller.isInitializing.value) {
              return _loadingState();
            }

            return Form(
              key: controller.formKey,

              // =================================================
              // IMPORTANT:
              // RefreshIndicator directly owns ListView.
              // No Column -> Expanded -> SingleChildScrollView.
              // =================================================

              child: RefreshIndicator(
                color: AppColors.primary1,
                onRefresh: controller.refreshAttendance,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    30,
                  ),
                  children: [
                    // ============================================
                    // EMPLOYEE
                    // ============================================

                    // ============================================
                    // DATE
                    // ============================================

                    _dateCard(),

                    const SizedBox(height: 14),

                    // ============================================
                    // FETCHING
                    // ============================================

                    if (controller.isFetchingAttendance.value) _fetchingCard(),

                    // ============================================
                    // NO ATTENDANCE
                    // ============================================

                    if (!controller.isFetchingAttendance.value &&
                        !controller.attendanceFound.value)
                      _emptyAttendanceState(),

                    // ============================================
                    // ATTENDANCE FOUND
                    // ============================================

                    if (!controller.isFetchingAttendance.value &&
                        controller.attendanceFound.value) ...[
                      // ------------------------------------------
                      // ACTUAL ATTENDANCE
                      // ------------------------------------------

                      _actualAttendanceCard(),

                      const SizedBox(height: 16),

                      // ------------------------------------------
                      // ASK USER WHAT TO EDIT
                      // ------------------------------------------

                      if (!controller.hasPreselectedAdjustmentType)
                        _editSelectionCard(),

                      // ------------------------------------------
                      // ONLY SHOW AFTER SELECTION
                      // ------------------------------------------

                      if (controller.hasSelectedEditType) ...[
                        const SizedBox(height: 16),
                        if (controller.canEditCheckIn ||
                            controller.canEditCheckOut) ...[
                          _adjustAttendanceCard(),
                          const SizedBox(height: 16),
                        ],
                        _statusCard(),
                        const SizedBox(height: 16),
                        _reasonCard(),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        // ======================================================
        // FIXED SUBMIT AREA
        // ======================================================

        bottomNavigationBar: Obx(
          () {
            if (controller.isInitializing.value ||
                controller.isFetchingAttendance.value ||
                !controller.attendanceFound.value) {
              return const SizedBox.shrink();
            }

            return _bottomActionBar();
          },
        ),
      ),
    );
  }

  // ============================================================
  // BACK
  // ============================================================

  Future<void> _handleBack() async {
    final bool canClose = await controller.confirmDiscard();

    if (canClose && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _loadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading attendance...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPLOYEE
  // ============================================================

  // ============================================================
  // DATE
  // ============================================================

  Widget _dateCard() {
    return _card(
      child: InkWell(
        onTap: controller.isFetchingAttendance.value ||
                controller.hasPreselectedAdjustmentType
            ? null
            : () => controller.selectDate(context),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: Color(0xFF1769E8), size: 24),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SELECTED DATE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                    )),
                const SizedBox(height: 4),
                Text(controller.formattedDate,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    )),
              ],
            )),
            if (!controller.hasPreselectedAdjustmentType)
              Icon(Icons.chevron_right_rounded, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FETCHING
  // ============================================================

  Widget _fetchingCard() {
    return _card(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading attendance...',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTUAL ATTENDANCE
  // ============================================================

  Widget _actualAttendanceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current attendance',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Recorded details for your selected date',
              style: TextStyle(color: _textSecondary, fontSize: 11.5)),
          const SizedBox(height: 16),
          _attendanceInfoRow(Icons.login_rounded, 'Check in',
              _friendlyTime(controller.currentCheckIn.value)),
          Divider(height: 24, color: _border),
          _attendanceInfoRow(Icons.logout_rounded, 'Check out',
              _friendlyTime(controller.currentCheckOut.value)),
          Divider(height: 24, color: _border),
          _attendanceInfoRow(
              Icons.fact_check_outlined,
              'Status',
              controller.currentStatus.value.trim().isEmpty
                  ? 'Not available'
                  : controller.currentStatus.value),
        ],
      ),
    );
  }

  Widget _attendanceInfoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 17, color: const Color(0xFF1769E8)),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontSize: 12.5, color: _textSecondary)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: _textPrimary,
                  fontWeight: FontWeight.w700))),
    ]);
  }

  // ============================================================
  // EDIT SELECTION
  // ============================================================

  Widget _editSelectionCard() {
    final String selected = controller.selectedEditType.value;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.edit_rounded,
            title: 'What do you want to edit?',
            subtitle: 'Select the attendance information you want to correct.',
          ),

          const SizedBox(height: 20),

          // IMPORTANT:
          // DO NOT USE CrossAxisAlignment.stretch HERE.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _editOption(
                  title: 'Full Day',
                  subtitle: 'Check In & Out',
                  icon: Icons.calendar_month_rounded,
                  selected: selected == AttendanceEditController.editFullDay,
                  onTap: () {
                    controller.selectEditType(
                      AttendanceEditController.editFullDay,
                    );
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _editOption(
                  title: 'Check In',
                  subtitle: 'Entry time',
                  icon: Icons.login_rounded,
                  selected: selected == AttendanceEditController.editCheckIn,
                  onTap: () {
                    controller.selectEditType(
                      AttendanceEditController.editCheckIn,
                    );
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _editOption(
                  title: 'Check Out',
                  subtitle: 'Exit time',
                  icon: Icons.logout_rounded,
                  selected: selected == AttendanceEditController.editCheckOut,
                  onTap: () {
                    controller.selectEditType(
                      AttendanceEditController.editCheckOut,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _editOption(
              title: 'Status Only',
              subtitle: 'Correct attendance classification',
              icon: Icons.fact_check_outlined,
              selected: selected == AttendanceEditController.editStatus,
              onTap: () => controller
                  .selectEditType(AttendanceEditController.editStatus),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: controller.isSaving.value ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        // Fixed minimum height is safe.
        // There is NO Expanded inside this card vertically.
        constraints: const BoxConstraints(
          minHeight: 150,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary1.withValues(
                  alpha: _isDark ? 0.16 : 0.08,
                )
              : _fieldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary1 : _border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary1 : _mutedSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 23,
                color: selected ? Colors.white : _textSecondary,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: selected ? AppColors.primary1 : _textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 10,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary1 : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primary1 : _border,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADJUST ATTENDANCE
  // ============================================================

  Widget _adjustAttendanceCard() {
    final bool fullDay = controller.isFullDayEdit;
    final bool checkIn = controller.isCheckInEdit;

    String title;
    String subtitle;
    IconData icon;

    final type = controller.preselectedAdjustmentType;
    if (fullDay) {
      title = 'Full Day Correction';
      subtitle = 'Correct check-in, check-out and/or attendance status.';
      icon = Icons.calendar_month_outlined;
    } else if (checkIn) {
      title = type == AttendanceEditController.addCheckIn
          ? 'Add Check In'
          : 'Update Check In';
      subtitle = type == AttendanceEditController.addCheckIn
          ? 'Enter the missing check-in time.'
          : 'Enter the corrected check-in time.';
      icon = Icons.login_rounded;
    } else {
      title = type == AttendanceEditController.addCheckOut
          ? 'Add Check Out'
          : 'Update Check Out';
      subtitle = type == AttendanceEditController.addCheckOut
          ? 'Enter the missing check-out time.'
          : 'Enter the corrected check-out time.';
      icon = Icons.logout_rounded;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 20),
          if (controller.canEditCheckIn)
            _adjustTimeField(
              title: type == AttendanceEditController.addCheckIn
                  ? 'New Check-In Time'
                  : 'Corrected Check-In Time',
              hint: 'Select check-in time',
              textController: controller.checkInTimeController,
              icon: Icons.login_rounded,
              color: AppColors.success,
              onTap: () {
                controller.selectCheckInTime(context);
              },
              onClear: controller.clearCheckInTime,
            ),
          if (controller.isFullDayEdit)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 18,
              ),
              child: Divider(
                height: 1,
                color: _border,
              ),
            ),
          if (controller.canEditCheckOut)
            _adjustTimeField(
              title: type == AttendanceEditController.addCheckOut
                  ? 'New Check-Out Time'
                  : 'Corrected Check-Out Time',
              hint: 'Select check-out time',
              textController: controller.checkOutTimeController,
              icon: Icons.logout_rounded,
              color: AppColors.danger,
              onTap: () {
                controller.selectCheckOutTime(context);
              },
              onClear: controller.clearCheckOutTime,
            ),
        ],
      ),
    );
  }

  Widget _adjustTimeField({
    required String title,
    required String hint,
    required TextEditingController textController,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconBox(
              icon: icon,
              color: color,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: textController,
          readOnly: true,
          validator: controller.validateTime,
          onTap: onTap,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF1769E8),
            ),

            // Use one stable suffix icon.
            // This avoids depending on a controller listener
            // just to redraw the X icon.
            suffixIcon: IconButton(
              onPressed: onTap,
              icon: Icon(
                Icons.chevron_right_rounded,
                color: _textSecondary,
              ),
            ),

            filled: true,
            fillColor: _fieldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary1,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusOnlyHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text('Update Status',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          )),
    );
  }

  Widget _statusCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.fact_check_outlined,
            title: 'Requested Attendance Status',
            subtitle: 'Select a new status only if it is incorrect.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.statuses
                .map(
                  (String status) => _statusChip(status),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final bool selected = controller.selectedStatus.value == status;

    return InkWell(
      onTap: controller.isSaving.value
          ? null
          : () {
              controller.setStatus(status);
            },
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary1 : _mutedSurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppColors.primary1 : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              status,
              style: TextStyle(
                color: selected ? Colors.white : _textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REASON
  // ============================================================

  Widget _reasonCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.description_outlined,
            title: 'Reason for Correction',
            subtitle:
                'Briefly explain why this attendance record needs to be corrected.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller.reasonController,
            validator: controller.validateReason,
            minLines: 4,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Explain the correction...',
              hintStyle: TextStyle(
                color: _textSecondary,
              ),
              filled: true,
              fillColor: _fieldBackground,
              contentPadding: const EdgeInsets.all(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary1,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY ATTENDANCE
  // ============================================================

  Widget _emptyAttendanceState() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                size: 30,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No attendance found',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              child: Text(
                controller.fetchMessage.value.trim().isNotEmpty
                    ? controller.fetchMessage.value
                    : 'There is no attendance record available for ${controller.formattedDate}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: controller.refreshAttendance,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Try again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTION BAR
  // ============================================================

  Widget _bottomActionBar() {
    final bool disabled = controller.isSaving.value ||
        controller.isFetchingAttendance.value ||
        !controller.hasSelectedEditType ||
        !controller.hasAttendanceChanges;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12,
        ),
        decoration: BoxDecoration(
          color: _surface,
          border: Border(
            top: BorderSide(
              color: _border,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isDark ? 0.18 : 0.05,
              ),
              blurRadius: 16,
              offset: const Offset(
                0,
                -4,
              ),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: disabled ? null : controller.updateAttendance,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary1,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE4E7EC),
              disabledForegroundColor:
                  _isDark ? Colors.white38 : const Color(0xFF98A2B3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: controller.isSaving.value
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Submitting...',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Submit Adjustment Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.025,
                  ),
                  blurRadius: 14,
                  offset: const Offset(
                    0,
                    5,
                  ),
                ),
              ],
      ),
      child: child,
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF1769E8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _iconBox({
    required IconData icon,
    required Color color,
    double size = 42,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.50,
      ),
    );
  }

  // ============================================================
  // FRIENDLY TIME
  // ============================================================

  String _friendlyTime(String value) {
    final String raw = value.trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return 'Not recorded';
    }

    try {
      String timePart = raw;

      // Handles datetime values if one ever reaches UI.
      if (timePart.contains(' ')) {
        timePart = timePart.split(' ').last;
      }

      final List<String> parts = timePart.split(':');

      if (parts.length < 2) {
        return raw;
      }

      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      final TimeOfDay time = TimeOfDay(
        hour: hour,
        minute: minute,
      );

      return MaterialLocalizations.of(context).formatTimeOfDay(
        time,
        alwaysUse24HourFormat: false,
      );
    } catch (_) {
      return raw;
    }
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _initials(String name) {
    final List<String> words = name
        .trim()
        .split(
          RegExp(r'\s+'),
        )
        .where(
          (String item) => item.isNotEmpty,
        )
        .toList();

    if (words.isEmpty) {
      return 'E';
    }

    if (words.length == 1) {
      return words.first
          .substring(
            0,
            1,
          )
          .toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

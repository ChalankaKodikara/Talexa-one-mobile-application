// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/modules/HRMS/leave_info/controllers/leave_approval_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupervisorApprovalPage extends StatelessWidget {
  final int leaveId;

  const SupervisorApprovalPage({
    super.key,
    required this.leaveId,
  });

  @override
  Widget build(BuildContext context) {
    final LeaveApprovalController controller = Get.put(
      LeaveApprovalController(
        leaveId: leaveId,
        isSupervisor: true,
      ),
    );

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    final Color surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;

    final Color secondarySurface =
        isDark ? const Color(0xFF1A2236) : const Color(0xFFF8FAFC);

    final Color textPrimary = isDark ? Colors.white : const Color(0xFF111827);

    final Color textSecondary =
        isDark ? Colors.white70 : const Color(0xFF667085);

    final Color borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4E7EC);

    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
        foregroundColor: textPrimary,
        centerTitle: true,
        title: Text(
          'Supervisor Approval',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary2,
              ),
            );
          }

          final Map<String, dynamic> leave = Map<String, dynamic>.from(
            controller.leaveData,
          );

          if (leave.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No leave details found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // LEAVE DETAILS CARD
                // =================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: borderColor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.16 : 0.04,
                        ),
                        blurRadius: 16,
                        offset: const Offset(
                          0,
                          5,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------------------------------------------
                      // HEADER
                      // -------------------------------------------

                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary2.withValues(
                                alpha: isDark ? 0.18 : 0.09,
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.fact_check_outlined,
                              color: AppColors.primary2,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Leave Request Details',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Review the employee leave request before making your decision.',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _infoRow(
                        context: context,
                        label: 'Employee',
                        value: leave['employee_fullname'],
                        icon: Icons.person_outline_rounded,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        secondarySurface: secondarySurface,
                        borderColor: borderColor,
                      ),

                      const SizedBox(height: 9),

                      _infoRow(
                        context: context,
                        label: 'Department',
                        value: leave['department'] ?? '-',
                        icon: Icons.apartment_rounded,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        secondarySurface: secondarySurface,
                        borderColor: borderColor,
                      ),

                      const SizedBox(height: 9),

                      _infoRow(
                        context: context,
                        label: 'Category',
                        value: leave['category_name'],
                        icon: Icons.category_outlined,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        secondarySurface: secondarySurface,
                        borderColor: borderColor,
                      ),

                      const SizedBox(height: 9),

                      _infoRow(
                        context: context,
                        label: 'Requested Date',
                        value: leave['requested_date'],
                        icon: Icons.calendar_today_outlined,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        secondarySurface: secondarySurface,
                        borderColor: borderColor,
                      ),

                      const SizedBox(height: 9),

                      _infoRow(
                        context: context,
                        label: 'Reason',
                        value: leave['reason'],
                        icon: Icons.notes_rounded,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        secondarySurface: secondarySurface,
                        borderColor: borderColor,
                        multiline: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // DECISION TITLE
                // =================================================

                Text(
                  'Select your decision',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Approve or reject this leave request after reviewing the information above.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // APPROVE / REJECT
                // =================================================

                Obx(
                  () {
                    return Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              controller.decision.value = 'APPROVED';
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: _optionBox(
                              isDark: isDark,
                              label: 'Approve',
                              icon: Icons.check_circle_rounded,
                              color: Colors.green,
                              active: controller.decision.value == 'APPROVED',
                              surfaceColor: surfaceColor,
                              textPrimary: textPrimary,
                              borderColor: borderColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              controller.decision.value = 'REJECTED';
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: _optionBox(
                              isDark: isDark,
                              label: 'Reject',
                              icon: Icons.cancel_rounded,
                              color: Colors.red,
                              active: controller.decision.value == 'REJECTED',
                              surfaceColor: surfaceColor,
                              textPrimary: textPrimary,
                              borderColor: borderColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // =================================================
                // REJECTION REASON
                // =================================================

                Obx(
                  () {
                    if (controller.decision.value != 'REJECTED') {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(
                        top: 18,
                      ),
                      child: TextField(
                        minLines: 3,
                        maxLines: 4,
                        onChanged: (
                          String value,
                        ) {
                          controller.reason.value = value;
                        },
                        style: TextStyle(
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Reason for rejection',
                          hintText:
                              'Enter the reason for rejecting this leave request',
                          labelStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: AppColors.primary2,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF98A2B3),
                            fontSize: 12,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 48,
                            ),
                            child: Icon(
                              Icons.edit_note_rounded,
                              color: textSecondary,
                            ),
                          ),
                          filled: true,
                          fillColor: secondarySurface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: AppColors.primary2,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // =================================================
                // SUBMIT BUTTON
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: controller.supervisorSubmitDecision,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary2,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? Colors.white.withValues(
                              alpha: 0.08,
                            )
                          : const Color(0xFFE4E7EC),
                      disabledForegroundColor:
                          isDark ? Colors.white38 : const Color(0xFF98A2B3),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Submit Decision',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // OPTION BOX
  // ============================================================

  Widget _optionBox({
    required bool isDark,
    required String label,
    required IconData icon,
    required Color color,
    required bool active,
    required Color surfaceColor,
    required Color textPrimary,
    required Color borderColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? color : borderColor,
          width: active ? 1.6 : 1,
        ),
        color: active
            ? color.withValues(
                alpha: isDark ? 0.17 : 0.09,
              )
            : surfaceColor,
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(
                    alpha: isDark ? 0.12 : 0.08,
                  ),
                  blurRadius: 10,
                  offset: const Offset(
                    0,
                    4,
                  ),
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? icon : Icons.circle_outlined,
            color: active
                ? color
                : color.withValues(
                    alpha: 0.75,
                  ),
            size: 21,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? color : textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow({
    required BuildContext context,
    required String label,
    required dynamic value,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
    required Color secondarySurface,
    required Color borderColor,
    bool multiline = false,
  }) {
    final String displayValue = value?.toString().trim().isNotEmpty == true
        ? value.toString().trim()
        : '-';

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondarySurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // ------------------------------------------------------
          // ICON
          // ------------------------------------------------------

          Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary2.withValues(
                alpha: isDark ? 0.17 : 0.08,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primary2,
            ),
          ),

          const SizedBox(width: 11),

          // ------------------------------------------------------
          // LABEL
          // ------------------------------------------------------

          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------
          // VALUE
          // ------------------------------------------------------

          Expanded(
            flex: 4,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              maxLines: multiline ? null : 2,
              overflow: multiline ? null : TextOverflow.ellipsis,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

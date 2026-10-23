// lib/modules/notifications/pages/notification_settings_page.dart

import 'package:corehris/modules/HRMS/notifications/controller/notification_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final NotificationController controller =
        Get.find<NotificationController>();

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

    final Color borderColor = isDark
        ? Colors.white.withValues(
            alpha: 0.08,
          )
        : const Color(0xFFE4E7EC);

    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // PAGE HEADER
              // =================================================

              Text(
                'Push Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Manage how you receive HRIS updates and alerts.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // ENABLE / DISABLE CARD
              // =================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.14 : 0.04,
                      ),
                      blurRadius: 18,
                      offset: const Offset(
                        0,
                        6,
                      ),
                    ),
                  ],
                ),
                child: Obx(
                  () {
                    final bool enabled = controller.isEnabled.value;

                    return Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: enabled
                                ? AppColors.primary2.withValues(
                                    alpha: isDark ? 0.20 : 0.10,
                                  )
                                : Colors.grey.withValues(
                                    alpha: isDark ? 0.16 : 0.10,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            enabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color: enabled ? AppColors.primary2 : textSecondary,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Notifications',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                enabled
                                    ? 'Push notifications are currently enabled.'
                                    : 'Push notifications are currently disabled.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Switch.adaptive(
                          value: enabled,
                          activeColor: AppColors.primary2,
                          onChanged: (
                            bool value,
                          ) {
                            controller.toggleNotifications(
                              value,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // STATUS MESSAGE
              // =================================================

              Obx(
                () {
                  final bool enabled = controller.isEnabled.value;

                  final Color statusColor =
                      enabled ? AppColors.success : AppColors.danger;

                  return AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 200,
                    ),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(
                        alpha: isDark ? 0.13 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(
                          alpha: isDark ? 0.22 : 0.15,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          enabled
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          color: statusColor,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            enabled
                                ? "Notifications are enabled. You'll receive real-time updates."
                                : "Notifications are disabled. You won't receive updates.",
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 26),

              Divider(
                height: 1,
                thickness: 1,
                color: borderColor,
              ),

              const SizedBox(height: 24),

              // =================================================
              // NOTIFICATION TYPES TITLE
              // =================================================

              Text(
                "When notifications are enabled, you'll receive updates for:",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // LEAVE NOTIFICATIONS
              // =================================================

              _notificationItem(
                isDark: isDark,
                surfaceColor: surfaceColor,
                secondarySurface: secondarySurface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                icon: Icons.beach_access_rounded,
                title: 'Leave Requests & Approvals',
                subtitle:
                    'Get updates when leave requests are submitted, approved or rejected.',
              ),

              const SizedBox(height: 12),

              // =================================================
              // ATTENDANCE NOTIFICATIONS
              // =================================================

              _notificationItem(
                isDark: isDark,
                surfaceColor: surfaceColor,
                secondarySurface: secondarySurface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                icon: Icons.access_time_rounded,
                title: 'Attendance Updates',
                subtitle:
                    'Receive attendance, check-in, check-out and adjustment updates.',
              ),

              const SizedBox(height: 12),

              // =================================================
              // PAYROLL NOTIFICATIONS
              // =================================================

              _notificationItem(
                isDark: isDark,
                surfaceColor: surfaceColor,
                secondarySurface: secondarySurface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                icon: Icons.payments_outlined,
                title: 'Salary & Payroll Notifications',
                subtitle:
                    'Receive payroll, salary and payslip-related notifications.',
              ),

              const SizedBox(height: 24),

              // =================================================
              // INFO CARD
              // =================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primary2.withValues(
                    alpha: isDark ? 0.13 : 0.07,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary2.withValues(
                      alpha: isDark ? 0.22 : 0.13,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary2,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Notification availability may also depend on your device notification permissions.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.primary2,
                          fontSize: 11.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
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

  // ============================================================
  // NOTIFICATION ITEM
  // ============================================================

  Widget _notificationItem({
    required bool isDark,
    required Color surfaceColor,
    required Color secondarySurface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.10 : 0.025,
            ),
            blurRadius: 12,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ====================================================
          // LEADING ICON
          // ====================================================

          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: secondarySurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: AppColors.primary2,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          // ====================================================
          // TITLE & SUBTITLE
          // ====================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ====================================================
          // TRAILING ICON
          // ====================================================

          Icon(
            Icons.notifications_none_rounded,
            color: textSecondary.withValues(
              alpha: 0.7,
            ),
            size: 19,
          ),
        ],
      ),
    );
  }
}

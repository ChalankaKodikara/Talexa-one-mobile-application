import 'dart:ui';
import 'package:corehris/modules/HRMS/notifications/controller/notification_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationPopupCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationPopupCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final NotificationController controller =
        Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : Get.put(NotificationController());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String message = notification['message'] ?? 'No message';
    final String type = notification['type'] ?? 'INFO';
    final DateTime time =
        DateTime.tryParse(notification['timestamp'] ?? '') ?? DateTime.now();

    final String formattedTime =
        DateFormat('MMM d, yyyy • hh:mm a').format(time.toLocal());

    final Color overlayColor = isDark
        ? Colors.black.withOpacity(0.65)
        : Colors.black.withOpacity(0.28);

    final Color cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final Color bodyColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final Color lightBorder =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEDEDED);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: overlayColor),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.28 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                  border: Border.all(
                    color: lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// TOP BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: Get.back,
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFFF7F7F7),
                              shape: BoxShape.circle,
                              border: Border.all(color: lightBorder),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    /// ICON / ILLUSTRATION AREA
                    Container(
                      width: 122,
                      height: 122,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _getIllustrationGradient(type, isDark),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getAccentColor(type).withOpacity(0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withOpacity(isDark ? 0.12 : 0.92),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            _getIcon(type),
                            size: 38,
                            color: _getAccentColor(type),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    /// TITLE
                    Text(
                      _getTitle(type),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// MESSAGE
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: bodyColor,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      formattedTime,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: bodyColor.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// PRIMARY BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: isDark
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2F3640),
                                    Color(0xFF111827),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF2D2F39),
                                    Color(0xFF111111),
                                  ],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            controller.handleNotificationTap(notification);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary2,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _getPrimaryButtonText(type),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// SECONDARY ACTION
                    TextButton(
                      onPressed: Get.back,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : const Color(0xFF4B5563),
                      ),
                      child: const Text(
                        "I'll do it later",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return 'Leave request update';
      case 'ATTENDANCE':
        return 'Attendance notification';
      case 'PAYROLL':
        return 'Payroll update';
      case 'NOTICE':
        return 'New notice received';
      case 'APPROVAL':
        return 'Application approved';
      case 'REJECTION':
        return 'Request update';
      default:
        return 'New notification';
    }
  }

  String _getPrimaryButtonText(String type) {
    switch (type.toUpperCase()) {
      case 'APPROVAL':
        return 'Start onboarding';
      case 'LEAVE':
        return 'View leave details';
      case 'ATTENDANCE':
        return 'Open attendance';
      case 'PAYROLL':
        return 'View payroll';
      case 'NOTICE':
        return 'Read notice';
      default:
        return 'View details';
    }
  }

  IconData _getIcon(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return Icons.beach_access_rounded;
      case 'ATTENDANCE':
        return Icons.access_time_filled_rounded;
      case 'PAYROLL':
        return Icons.account_balance_wallet_rounded;
      case 'NOTICE':
        return Icons.notifications_active_rounded;
      case 'APPROVAL':
        return Icons.verified_rounded;
      case 'REJECTION':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getAccentColor(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return const Color(0xFF8B5CF6);
      case 'ATTENDANCE':
        return const Color(0xFF3B82F6);
      case 'PAYROLL':
        return const Color(0xFF10B981);
      case 'NOTICE':
        return const Color(0xFFF59E0B);
      case 'APPROVAL':
        return const Color(0xFF10B981);
      case 'REJECTION':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary2;
    }
  }

  List<Color> _getIllustrationGradient(String type, bool isDark) {
    switch (type.toUpperCase()) {
      case 'APPROVAL':
        return const [Color(0xFF34D399), Color(0xFF10B981)];
      case 'REJECTION':
        return const [Color(0xFFF87171), Color(0xFFEF4444)];
      case 'PAYROLL':
        return const [Color(0xFF6EE7B7), Color(0xFF10B981)];
      case 'ATTENDANCE':
        return const [Color(0xFF60A5FA), Color(0xFF2563EB)];
      case 'NOTICE':
        return const [Color(0xFFFCD34D), Color(0xFFF59E0B)];
      case 'LEAVE':
        return const [Color(0xFFA78BFA), Color(0xFF8B5CF6)];
      default:
        return isDark
            ? [const Color(0xFF6366F1), const Color(0xFF4338CA)]
            : [const Color(0xFF818CF8), const Color(0xFF6366F1)];
    }
  }
}

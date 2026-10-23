import 'package:corehris/modules/HRMS/notifications/controller/notification_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// A clean, rounded Talexa notification popup.
/// Keeps the existing NotificationController navigation / business logic.
class NotificationPopupCard extends StatelessWidget {
  const NotificationPopupCard({super.key, required this.notification});

  final Map<String, dynamic> notification;

  static const Color _blue = Color(0xFF1769E8);
  static const Color _navy = Color(0xFF182237);
  static const Color _muted = Color(0xFF89919D);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1B2638) : Colors.white;
    final ink = isDark ? Colors.white : _navy;
    final secondary = isDark ? const Color(0xFFABB7C9) : _muted;
    final line = isDark ? Colors.white12 : const Color(0xFFECEFF3);
    final soft = isDark ? const Color(0xFF263449) : const Color(0xFFF5F6F8);

    final type = (notification['type'] ?? 'INFO').toString().toUpperCase();
    final message = (notification['message'] ?? 'No message').toString().trim();
    final timestamp = notification['timestamp']?.toString() ?? '';
    final parsedTime = DateTime.tryParse(timestamp);
    final formattedTime = parsedTime == null
        ? null
        : DateFormat('d MMM yyyy • h:mm a').format(parsedTime.toLocal());
    final accent = _accent(type);
    final screenSize = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: ColoredBox(
                color: Colors.black.withOpacity(isDark ? 0.67 : 0.42),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.96, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) => Transform.scale(
                  scale: progress,
                  child: Opacity(opacity: progress, child: child),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 390,
                    maxHeight: screenSize.height - 56,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.13),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: soft,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'NOTIFICATION',
                                  style: TextStyle(
                                    color: secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 21,
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              _icon(type),
                              color: accent,
                              size: 43,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _title(type),
                            style: TextStyle(
                              color: ink,
                              fontSize: 23,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            message.isEmpty ? 'No message' : message,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 14,
                              height: 1.55,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (formattedTime != null) ...[
                            const SizedBox(height: 17),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded,
                                    color: secondary, size: 15),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      color: secondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 25),
                          Divider(height: 1, thickness: 1, color: line),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => controller
                                  .handleNotificationTap(notification),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                _buttonText(type),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: TextButton.styleFrom(
                              foregroundColor: secondary,
                              minimumSize: const Size(double.infinity, 42),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Maybe later',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _title(String type) {
    switch (type) {
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

  static String _buttonText(String type) {
    switch (type) {
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

  static IconData _icon(String type) {
    switch (type) {
      case 'LEAVE':
        return Icons.event_available_outlined;
      case 'ATTENDANCE':
        return Icons.schedule_rounded;
      case 'PAYROLL':
        return Icons.account_balance_wallet_outlined;
      case 'NOTICE':
        return Icons.notifications_none_rounded;
      case 'APPROVAL':
        return Icons.check_circle_outline_rounded;
      case 'REJECTION':
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static Color _accent(String type) {
    switch (type) {
      case 'APPROVAL':
        return const Color(0xFF16A36A);
      case 'REJECTION':
        return const Color(0xFFD64550);
      case 'PAYROLL':
        return const Color(0xFF16A36A);
      case 'NOTICE':
        return const Color(0xFFE4A11B);
      default:
        return _blue;
    }
  }
}

// lib/modules/screens/main_screens/notifications/notification_screen.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leavemenu.dart';
import 'package:corehris/modules/HRMS/leave_info/screens/covering_approval_screen.dart';
import 'package:corehris/modules/HRMS/leave_info/screens/supervisor_approval_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();

  final RxList<Map<String, dynamic>> _notifications =
      <Map<String, dynamic>>[].obs;

  final RxBool _isLoading = true.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasMore = true.obs;
  final RxInt _tabIndex = 0.obs;

  late final TabController _tabController;
  String? _employeeId;
  int _page = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _tabIndex.value = _tabController.index;
    });
    _loadEmployeeIdAndNotifications();
  }

  Future<void> _loadEmployeeIdAndNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('employee_no');

    if (id == null || id.isEmpty) {
      AppAlert.toast(
        title: "Error",
        message: "Employee ID not found. Please log in again.",
      );
      _isLoading.value = false;
      return;
    }

    _employeeId = id;
    await _loadNotifications(reset: true);
  }

  Future<bool> _loadNotifications({bool reset = false}) async {
    if (_employeeId == null) return false;

    try {
      if (reset) {
        _page = 1;
        _hasMore.value = true;
        _isLoading.value = true;
      }

      final data = await _auth.notification.fetchNotifications(
        _employeeId!,
        page: _page,
        limit: _pageSize,
      );

      data.sort((a, b) {
        DateTime? pa = _safeParseDate(a['timestamp']);
        DateTime? pb = _safeParseDate(b['timestamp']);
        if (pa == null && pb == null) return 0;
        if (pa == null) return 1;
        if (pb == null) return -1;
        return pb.compareTo(pa);
      });

      if (reset) {
        _notifications.assignAll(data);
      } else {
        final previousCount = _notifications.length;
        _appendNotifications(data);
        if (_notifications.length == previousCount && data.isNotEmpty) {
          _hasMore.value = false;
          return true;
        }
      }

      _hasMore.value = data.length >= _pageSize;
      return true;
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: e.toString(),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_employeeId == null || _isLoadingMore.value || !_hasMore.value) return;

    try {
      _isLoadingMore.value = true;
      _page += 1;
      final loaded = await _loadNotifications();
      if (!loaded) {
        _page = _page > 1 ? _page - 1 : 1;
      }
    } finally {
      _isLoadingMore.value = false;
    }
  }

  void _appendNotifications(List<Map<String, dynamic>> data) {
    final existingIds = _notifications.map((n) => '${n['id']}').toSet();
    final newItems =
        data.where((n) => !existingIds.contains('${n['id']}')).toList();

    _notifications.addAll(newItems);
    _notifications.sort((a, b) {
      DateTime? pa = _safeParseDate(a['timestamp']);
      DateTime? pb = _safeParseDate(b['timestamp']);
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pb.compareTo(pa);
    });
  }

  DateTime? _safeParseDate(dynamic ts) {
    if (ts == null) return null;
    try {
      return DateTime.parse(ts.toString());
    } catch (_) {
      return null;
    }
  }

  IconData _getIcon(String type) {
    switch (type.toUpperCase()) {
      case "LEAVE":
        return Icons.event_available_rounded;
      case "COVERING":
      case "LEAVE_COVERING":
        return Icons.groups_rounded;
      case "SUPERVISOR":
      case "LEAVE_SUPERVISOR":
        return Icons.assignment_turned_in_rounded;
      case "ATTENDANCE":
        return Icons.access_time_rounded;
      case "ANNOUNCEMENT":
        return Icons.campaign_rounded;
      case "SYSTEM":
        return Icons.settings_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toUpperCase()) {
      case "LEAVE":
        return AppColors.primary2;
      case "COVERING":
      case "LEAVE_COVERING":
        return Colors.teal;
      case "SUPERVISOR":
      case "LEAVE_SUPERVISOR":
        return Colors.indigo;
      case "ATTENDANCE":
        return Colors.orange;
      case "ANNOUNCEMENT":
        return Colors.purple;
      case "SYSTEM":
        return Colors.blueGrey;
      default:
        return AppColors.primary2;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case "LEAVE":
        return "Leave";
      case "LEAVE_COVERING":
        return "Covering Approval";
      case "LEAVE_SUPERVISOR":
        return "Supervisor Approval";
      case "ATTENDANCE":
        return "Attendance";
      case "ANNOUNCEMENT":
        return "Announcement";
      case "SYSTEM":
        return "System";
      default:
        return "Notification";
    }
  }

  List<Map<String, dynamic>> get _unread =>
      _notifications.where((n) => (n['is_read'] == 0)).toList();

  List<Map<String, dynamic>> get _read =>
      _notifications.where((n) => (n['is_read'] != 0)).toList();

  List<Map<String, dynamic>> _filteredByTab(int tab) {
    if (tab == 0) return _unread;
    if (tab == 1) return _read;
    return _notifications;
  }

  Future<void> _onNotificationTap(Map<String, dynamic> notif) async {
    final dynamic rawId = notif['id'];
    final int? notificationId = rawId is int ? rawId : int.tryParse('$rawId');

    final idx = _notifications.indexOf(notif);
    if (idx != -1 && (_notifications[idx]['is_read'] == 0)) {
      _notifications[idx] = {..._notifications[idx], 'is_read': 1};
      _notifications.refresh();
    }

    if (notificationId != null) {
      try {
        await _auth.notification.markNotificationAsRead(notificationId);
      } catch (e) {
        debugPrint('markNotificationAsRead failed: $e');
      }
    }

    final type = (notif['type'] ?? '').toString().toUpperCase();

    final rawLeaveId = notif['related_entity_id'];
    final int? leaveId = rawLeaveId == null
        ? null
        : (rawLeaveId is int
            ? rawLeaveId
            : int.tryParse(rawLeaveId.toString()));

    if (type == 'LEAVE_SUPERVISOR') {
      if (leaveId != null) {
        Get.to(() => SupervisorApprovalPage(leaveId: leaveId));
      } else {
        AppAlert.toast(
          title: "Error",
          message: "Missing leave ID for supervisor approval",
        );
      }
    } else if (type == 'LEAVE_COVERING') {
      if (leaveId != null) {
        Get.to(() => CoveringApprovalPage(leaveId: leaveId));
      } else {
        AppAlert.toast(
          title: "Error",
          message: "Missing leave ID for covering approval",
        );
      }
    } else if (type == 'ATTENDANCE') {
      Get.to(() => const AttendancePage(username: ''));
    } else if (type == 'LEAVE') {
      Get.to(() => LeaveMenuScreen());
    } else {
      AppAlert.toast(
        title: "Notification",
        message: "No handler for type: $type",
      );
    }
  }

  Future<void> _markAllUnreadAsRead() async {
    final items = List<Map<String, dynamic>>.from(_unread);
    if (items.isEmpty) return;

    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i]['is_read'] == 0) {
        _notifications[i] = {..._notifications[i], 'is_read': 1};
      }
    }
    _notifications.refresh();

    for (final n in items) {
      final dynamic rawId = n['id'];
      final int? notificationId = rawId is int ? rawId : int.tryParse('$rawId');
      if (notificationId != null) {
        try {
          await _auth.notification.markNotificationAsRead(notificationId);
        } catch (e) {
          debugPrint('markNotificationAsRead (bulk) failed: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(() {
      final unreadCount = _unread.length;
      final readCount = _read.length;
      final allCount = _notifications.length;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary2,
                    AppColors.primary1,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary2.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Colors.white,
                      ),
                      const Expanded(
                        child: Text(
                          'Notifications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_tabIndex.value == 0 && unreadCount > 0)
                        IconButton(
                          tooltip: 'Mark all as read',
                          onPressed: _markAllUnreadAsRead,
                          icon: const Icon(Icons.done_all_rounded),
                          color: Colors.white,
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.16),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.primary2,
                      unselectedLabelColor: Colors.white,
                      indicatorSize: TabBarIndicatorSize.tab,
                      splashBorderRadius: BorderRadius.circular(12),
                      tabs: [
                        _TabWithBadge(
                          label: 'Unread',
                          count: unreadCount,
                          selected: _tabIndex.value == 0,
                        ),
                        _TabWithBadge(
                          label: 'Read',
                          count: readCount,
                          selected: _tabIndex.value == 1,
                        ),
                        _TabWithBadge(
                          label: 'All',
                          count: allCount,
                          selected: _tabIndex.value == 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final list = _filteredByTab(_tabIndex.value);

                if (list.isEmpty) {
                  final emptyText = _tabIndex.value == 0
                      ? 'No unread notifications'
                      : _tabIndex.value == 1
                          ? 'No read notifications'
                          : 'No notifications yet';

                  final emptySubText = _tabIndex.value == 0
                      ? 'You are all caught up.'
                      : _tabIndex.value == 1
                          ? 'Read notifications will appear here.'
                          : 'New notifications will show up here.';

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: AppColors.primary2.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_off_rounded,
                              size: 44,
                              color: AppColors.primary2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            emptyText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            emptySubText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: cs.onSurface.withOpacity(0.65),
                            ),
                          ),
                          if (_hasMore.value) ...[
                            const SizedBox(height: 18),
                            _loadMoreButton(),
                          ],
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.15, end: 0),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await _loadNotifications(reset: true);
                  },
                  color: AppColors.primary2,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount: list.length + 1,
                    itemBuilder: (context, index) {
                      if (index == list.length) {
                        return _paginationFooter();
                      }

                      final notif = list[index];
                      final type = (notif['type'] ?? 'GENERAL').toString();
                      final icon = _getIcon(type);
                      final iconColor = _getIconColor(type);
                      final typeLabel = _getTypeLabel(type);
                      final msg = (notif['message'] ?? '').toString();
                      final timestamp = (notif['timestamp'] ?? '').toString();
                      final dt = _safeParseDate(timestamp);

                      final dateText = dt != null
                          ? DateFormat("MMM d, yyyy • h:mm a").format(dt)
                          : '';

                      final bool isUnread = (notif['is_read'] == 0);

                      return _notificationCard(
                        context,
                        icon: icon,
                        iconColor: iconColor,
                        typeLabel: typeLabel,
                        message: msg,
                        dateText: dateText,
                        isUnread: isUnread,
                        onTap: () => _onNotificationTap(notif),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _paginationFooter() {
    if (_isLoadingMore.value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: AppColors.primary2,
            ),
          ),
        ),
      );
    }

    if (!_hasMore.value) {
      return const SizedBox(height: 12);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
      child: Center(
        child: _loadMoreButton(),
      ),
    );
  }

  Widget _loadMoreButton() {
    return OutlinedButton.icon(
      onPressed: _isLoadingMore.value ? null : _loadMoreNotifications,
      icon: const Icon(Icons.expand_more_rounded),
      label: const Text('Load more notifications'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary2,
        side: BorderSide(color: AppColors.primary2.withOpacity(0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _notificationCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String typeLabel,
    required String message,
    required String dateText,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? iconColor.withOpacity(0.24)
                : (isDark ? Colors.white10 : Colors.black12),
            width: isUnread ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14.2,
                      height: 1.45,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12.2,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withOpacity(0.58),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurface.withOpacity(0.35),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;

  const _TabWithBadge({
    required this.label,
    required this.count,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = count > 99 ? '99+' : count.toString();

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary2 : Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary2.withOpacity(0.12)
                  : Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primary2 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

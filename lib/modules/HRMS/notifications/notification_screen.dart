// lib/modules/screens/main_screens/notifications/notification_screen.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leavemenu.dart';
import 'package:corehris/modules/HRMS/leave_info/screens/covering_approval_screen.dart';
import 'package:corehris/modules/HRMS/leave_info/screens/supervisor_approval_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:corehris/theme/theme.dart';

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

    if (!mounted) return;
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
        return const Color(0xFF1769E8);
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
        return const Color(0xFF1769E8);
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case "LEAVE":
        return "Leave";
      case "COVERING":
      case "LEAVE_COVERING":
        return "Covering Approval";
      case "SUPERVISOR":
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

  bool _readFlag(dynamic value) =>
      value == 1 ||
      value == true ||
      value?.toString().toLowerCase() == 'true' ||
      value?.toString() == '1';

  List<Map<String, dynamic>> get _unread =>
      _notifications.where((n) => !_readFlag(n['is_read'])).toList();

  List<Map<String, dynamic>> get _read =>
      _notifications.where((n) => _readFlag(n['is_read'])).toList();

  List<Map<String, dynamic>> _filteredByTab(int tab) {
    if (tab == 0) return _unread;
    if (tab == 1) return _read;
    return _notifications;
  }

  Future<void> _onNotificationTap(Map<String, dynamic> notif) async {
    final dynamic rawId = notif['id'];
    final int? notificationId = rawId is int ? rawId : int.tryParse('$rawId');

    final idx = _notifications.indexOf(notif);
    if (idx != -1 && !_readFlag(_notifications[idx]['is_read'])) {
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
      if (!_readFlag(_notifications[i]['is_read'])) {
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

  static const _blue = Color(0xFF1769E8);
  static const _ink = Color(0xFF182237);
  static const _muted = Color(0xFF89919D);

  bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _surface(BuildContext context) =>
      _dark(context) ? const Color(0xFF1B2638) : Colors.white;

  Color _text(BuildContext context) =>
      _dark(context) ? const Color(0xFFF4F7FC) : _ink;

  Color _secondary(BuildContext context) =>
      _dark(context) ? const Color(0xFFABB6C7) : _muted;

  Color _line(BuildContext context) =>
      _dark(context) ? const Color(0xFF303D50) : const Color(0xFFE8EDF4);

  Widget _header(BuildContext context, int unreadCount) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(children: [
          IconButton(
            onPressed: () => Get.back(),
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
          Expanded(
            child: Text(
              'Notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (unreadCount > 0)
            IconButton(
              onPressed: _markAllUnreadAsRead,
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all_rounded, size: 22),
              color: _blue,
            )
          else
            const SizedBox(width: 48),
        ]),
      ),
    );
  }

  Widget _tabs(BuildContext context, int unread, int read, int all) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _dark(context)
              ? const Color(0xFF263246)
              : const Color(0xFFEAEEF5),
          borderRadius: BorderRadius.circular(17),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: _surface(context),
            borderRadius: BorderRadius.circular(13),
          ),
          labelColor: _blue,
          unselectedLabelColor: _secondary(context),
          dividerColor: Colors.transparent,
          splashBorderRadius: BorderRadius.circular(13),
          labelPadding: EdgeInsets.zero,
          tabs: [
            _tabLabel(context, 'Unread', unread, _tabIndex.value == 0),
            _tabLabel(context, 'Read', read, _tabIndex.value == 1),
            _tabLabel(context, 'All', all, _tabIndex.value == 2),
          ],
        ),
      ),
    );
  }

  Widget _tabLabel(
      BuildContext context, String label, int count, bool selected) {
    return Tab(
      height: 43,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            )),
        const SizedBox(width: 5),
        Text(count > 99 ? '99+' : '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? _blue : _secondary(context),
            )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadCount = _unread.length;
      final readCount = _read.length;
      final allCount = _notifications.length;
      return Scaffold(
        backgroundColor:
            _dark(context) ? const Color(0xFF101623) : const Color(0xFFF5F6F8),
        body: Column(children: [
          _header(context, unreadCount),
          _tabs(context, unreadCount, readCount, allCount),
          Expanded(child: _buildList(context)),
        ]),
      );
    });
  }

  Widget _buildList(BuildContext context) {
    return Obx(() {
      if (_isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _blue));
      }
      final list = _filteredByTab(_tabIndex.value);
      if (list.isEmpty) {
        final heading = _tabIndex.value == 0
            ? 'All caught up'
            : _tabIndex.value == 1
                ? 'No read notifications'
                : 'No notifications yet';
        final caption = _tabIndex.value == 0
            ? 'You have no unread notifications.'
            : _tabIndex.value == 1
                ? 'Notifications you have opened will appear here.'
                : 'Your latest updates will appear here.';
        return RefreshIndicator(
          onRefresh: () => _loadNotifications(reset: true),
          color: _blue,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * .21),
              Center(
                  child: Column(children: [
                Icon(Icons.notifications_none_rounded,
                    color: _blue.withOpacity(.7), size: 40),
                const SizedBox(height: 12),
                Text(heading,
                    style: TextStyle(
                        color: _text(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(caption,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: _secondary(context), fontSize: 12)),
                ),
                if (_hasMore.value) ...[
                  const SizedBox(height: 18),
                  _loadMoreButton(),
                ],
              ])),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => _loadNotifications(reset: true),
        color: _blue,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          itemCount: list.length + 1,
          itemBuilder: (context, index) {
            if (index == list.length) return _paginationFooter();
            final notif = list[index];
            final type = (notif['type'] ?? 'GENERAL').toString();
            final dt = _safeParseDate(notif['timestamp']);
            final when = dt == null
                ? ''
                : DateFormat('d MMM yyyy • h:mm a').format(dt.toLocal());
            return _notificationCard(
              context,
              icon: _getIcon(type),
              iconColor: _getIconColor(type),
              typeLabel: _getTypeLabel(type),
              message: (notif['message'] ?? '').toString(),
              dateText: when,
              isUnread: !_readFlag(notif['is_read']),
              onTap: () => _onNotificationTap(notif),
            );
          },
        ),
      );
    });
  }

  Widget _paginationFooter() {
    if (_isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
            child: SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(strokeWidth: 2.4, color: _blue))),
      );
    }
    if (!_hasMore.value) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: _loadMoreButton()),
    );
  }

  Widget _loadMoreButton() => OutlinedButton.icon(
        onPressed: _isLoadingMore.value ? null : _loadMoreNotifications,
        icon: const Icon(Icons.expand_more_rounded, size: 18),
        label: const Text('Load more'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _blue,
          shape: const StadiumBorder(),
        ),
      );

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
    final dark = _dark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _surface(context),
        borderRadius: BorderRadius.circular(19),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: _line(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 37,
                  height: 37,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(dark ? .19 : .10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(width: 11),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _text(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      )),
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _blue),
                        ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 17, color: _secondary(context)),
                    ]),
                    const SizedBox(height: 5),
                    Text(
                      message.isEmpty ? 'Notification update' : message,
                      style: TextStyle(
                        color: isUnread ? _text(context) : _secondary(context),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (dateText.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(dateText,
                          style: TextStyle(
                              color: _secondary(context), fontSize: 10.5)),
                    ],
                  ],
                )),
              ],
            ),
          ),
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

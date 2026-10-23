// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'dart:async';
import 'package:corehris/auth/authservices.dart';
import 'package:corehris/auth/notification_service.dart';
import 'package:corehris/modules/HRMS/leave_info/screens/covering_approval_screen.dart';
import 'package:corehris/modules/HRMS/leave_info/screens/supervisor_approval_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leavemenu.dart';
import 'package:corehris/modules/HRMS/notifications/notification_card.dart';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class NotificationController extends GetxController {
  final AuthService _auth = AuthService();

  RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;
  RxBool isEnabled = true.obs;

  Timer? _pollingTimer;
  bool _isFetching = false;

  String? lastSeenId;
  final Set<String> dismissedIds = {};

  // =========================================================
  // INIT
  // =========================================================
  @override
  void onInit() {
    super.onInit();
    _initializeNotificationSystem();
  }

  Future<void> _initializeNotificationSystem() async {
    await LocalNotificationService.initialize();
    await _loadPreference();
    await _loadDismissedIds();
    await _loadLastSeenId(); // ✅ persist last seen
  }

  // =========================================================
  // ENABLE / DISABLE
  // =========================================================
  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool('notification_enabled') ?? true;

    if (isEnabled.value) {
      await fetchNotifications();
      _startPolling();
    }
  }

  Future<void> toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);
    isEnabled.value = value;

    if (value) {
      await fetchNotifications();
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  // =========================================================
  // POLLING (Safe Version)
  // =========================================================
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) async {
        if (isEnabled.value) {
          await fetchNotifications();
        }
      },
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // =========================================================
  // FETCH (Safe + No Duplicate + Persisted)
  // =========================================================
  Future<void> fetchNotifications() async {
    if (!isEnabled.value || _isFetching) return;

    _isFetching = true;

    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();
      final empId = prefs.getString('employee_no');
      if (empId == null || empId.isEmpty) return;

      final data = await _auth.notification.fetchNotifications(empId);

      if (data.isEmpty) return;

      final latest = data.first;
      final latestId = latest['id'].toString();

      // ✅ Show popup only if:
      // - New ID
      // - Not dismissed
      // - Not already read
      if (latestId != lastSeenId &&
          !dismissedIds.contains(latestId) &&
          !_isRead(latest)) {
        lastSeenId = latestId;
        await _saveLastSeenId();
        _showPopupNotification(latest);
      } else if (latestId != lastSeenId && _isRead(latest)) {
        lastSeenId = latestId;
        await _saveLastSeenId();
      }

      notifications.assignAll(data);
    } catch (e) {
      debugPrint("❌ Notification fetch error: $e");
    } finally {
      isLoading.value = false;
      _isFetching = false;
    }
  }

  // =========================================================
  // POPUP DISPLAY
  // =========================================================
  void _showPopupNotification(Map<String, dynamic> notif) {
    final notifId = notif['id'].toString();

    if (dismissedIds.contains(notifId) || _isRead(notif)) return;

    final title = notif['title'] ?? 'New Notification';
    final message = notif['message'] ?? 'You have a new alert';

    LocalNotificationService.showNotification(
      id: int.tryParse(notifId) ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: message,
    );

    Get.dialog(
      NotificationPopupCard(notification: notif),
      barrierDismissible: true,
    ).then((_) async {
      dismissedIds.add(notifId);
      await _saveDismissedIds();
    });
  }

  bool _isRead(Map<String, dynamic> notif) {
    final value = notif['is_read'];

    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == '1' || text == 'true' || text == 'yes' || text == 'read';
  }

  // =========================================================
  // TAP HANDLER (Cleaner Routing)
  // =========================================================
  Future<void> handleNotificationTap(Map<String, dynamic> notif) async {
    try {
      final type = notif['type']?.toString().toUpperCase() ?? '';
      final notifId = notif['id'].toString();

      final rawLeaveId = notif['related_entity_id'];
      final int? leaveId = rawLeaveId is int
          ? rawLeaveId
          : int.tryParse(rawLeaveId?.toString() ?? '');

      await _auth.notification.markNotificationAsRead(notif['id']);

      dismissedIds.add(notifId);
      await _saveDismissedIds();

      Get.back();

      switch (type) {
        case 'LEAVE':
          Get.to(() => LeaveMenuScreen());
          break;

        case 'ATTENDANCE':
          Get.to(() => const AttendancePage(username: ''));
          break;

        case 'LEAVE_COVERING':
          if (leaveId != null) {
            Get.to(() => CoveringApprovalPage(leaveId: leaveId));
          }
          break;

        case 'LEAVE_SUPERVISOR':
          if (leaveId != null) {
            Get.to(() => SupervisorApprovalPage(leaveId: leaveId));
          }
          break;

        default:
          AppAlert.toast(
            title: "Notification",
            message: "No handler for type: $type",
          );
      }
    } catch (e) {
      debugPrint("❌ Notification tap error: $e");
    }
  }

  // =========================================================
  // STORAGE
  // =========================================================
  Future<void> _saveDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_notifications', dismissedIds.toList());
  }

  Future<void> _loadDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('dismissed_notifications') ?? [];
    dismissedIds.addAll(saved);
  }

  Future<void> _saveLastSeenId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_seen_notification', lastSeenId ?? '');
  }

  Future<void> _loadLastSeenId() async {
    final prefs = await SharedPreferences.getInstance();
    lastSeenId = prefs.getString('last_seen_notification');
  }

  @override
  void onClose() {
    _stopPolling();
    super.onClose();
  }
}

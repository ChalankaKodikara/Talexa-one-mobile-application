// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'dart:convert';

import 'package:corehris/auth/notification_service.dart';
import 'package:corehris/modules/HRMS/leave_info/screens/covering_approval_screen.dart';
import 'package:corehris/modules/HRMS/leave_info/screens/supervisor_approval_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leavemenu.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance.dart';
import 'package:corehris/utils/app_alert.dart';

class SocketNotificationService {
  static IO.Socket? _socket;
  static String? _currentEmpId;

  // ✅ Track notifications that have been shown or dismissed
  static final Set<String> _handledNotificationIds = {};

  /// 🔗 Connect to WebSocket Server
  static void connectSocket(String empId, String baseUrl) {
    _currentEmpId = empId;

    if (_socket != null && _socket!.connected) {
      print("🔵 Socket already connected");
      return;
    }

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.onConnect((_) {
      print("🟢 Socket connected to $baseUrl");
      _socket!.emit('register_user', empId);
    });

    _socket!.onDisconnect((_) => print("🔴 Socket disconnected"));

    _socket!.onReconnect((_) {
      print("🟡 Socket reconnected — re-registering user");
      if (_currentEmpId != null) {
        _socket!.emit('register_user', _currentEmpId);
      }
    });

    // 🎯 Receive notification from backend
    _socket!.on('receive_notification', (data) async {
      if (data == null) return;

      final notif = Map<String, dynamic>.from(data);
      final id = notif['id']?.toString() ?? '';
      final title = notif['title'] ?? 'CoreHRIS Alert';
      final message = notif['message'] ?? 'You have a new update';

      if (_isRead(notif)) {
        print("⚪ Skipping read notification: $id");
        if (id.isNotEmpty) {
          _handledNotificationIds.add(id);
        }
        return;
      }

      // ✅ Skip if already handled (dismissed or viewed)
      if (_handledNotificationIds.contains(id)) {
        print("⚪ Skipping already handled notification: $id");
        return;
      }

      // ✅ Mark as shown so it doesn’t repeat
      _handledNotificationIds.add(id);

      print("📨 New WebSocket Notification: $notif");

      // 🔔 Show native notification only
      await LocalNotificationService.showNotification(
        id: int.tryParse(id) ?? DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: message,
        payload: jsonEncode(notif),
      );
    });
  }

  static bool _isRead(Map<String, dynamic> notif) {
    final value = notif['is_read'];

    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == '1' || text == 'true' || text == 'yes' || text == 'read';
  }

  /// 🔌 Disconnect safely
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      print("🔴 Socket manually disconnected");
    }
  }

  /// 🎯 Handle tap on notification (tray → app navigation)
  static void handleNotificationTap(Map<String, dynamic> notif) {
    try {
      final type = notif['type']?.toString().toUpperCase() ?? '';
      final id = notif['id']?.toString();

      // 👇 Safely convert leave_id to int
      final rawLeaveId = notif['related_entity_id'];
      final int? leaveId = rawLeaveId == null
          ? null
          : (rawLeaveId is int
              ? rawLeaveId
              : int.tryParse(rawLeaveId.toString()));

      print("📲 Notification tapped: $type with leaveId=$leaveId");

      // ✅ Mark as handled
      if (id != null) _handledNotificationIds.add(id);

      // ✅ Routing Logic
      if (type == 'LEAVE') {
        if (leaveId != null) {
          Get.to(() => LeaveMenuScreen());
        } else {
          AppAlert.toast(
            title: "Error",
            message: "Missing leave ID for leave request",
          );
        }
      } else if (type == 'ATTENDANCE') {
        Get.to(() => const AttendancePage(username: ''));
      } else if (type == 'LEAVE_COVERING') {
        if (leaveId != null) {
          Get.to(() => CoveringApprovalPage(leaveId: leaveId));
        } else {
          AppAlert.toast(
            title: "Error",
            message: "Missing leave ID for covering approval",
          );
        }
      } else if (type == 'LEAVE_SUPERVISOR') {
        if (leaveId != null) {
          Get.to(() => SupervisorApprovalPage(leaveId: leaveId));
        } else {
          AppAlert.toast(
            title: "Error",
            message: "Missing leave ID for supervisor approval",
          );
        }
      } else {
        AppAlert.toast(
          title: "Notification",
          message: "No handler for type: $type",
        );
      }
    } catch (e) {
      print("❌ Error handling notification tap: $e");
      AppAlert.toast(
        title: "Error",
        message: "Something went wrong: $e",
      );
    }
  }

  /// 🚫 Mark a notification as dismissed (won’t show again)
  static void markDismissed(String id) {
    _handledNotificationIds.add(id);
    print("🗑️ Notification dismissed: $id");
  }
}

import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class NotificationApi {
  NotificationApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kNotificationsPath = '/v1/hris/notifications/get';
  static const String kMarkNotificationReadPath =
      '/v1/hris/notifications/notifications/mark-read';

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty) {
      throw Exception('Tenant baseUrl not ready');
    }
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(
    String employeeId, {
    int page = 1,
    int limit = 10,
  }) async {
    await _ready();
    final res = await tenantDio.get(
      '$kNotificationsPath/$employeeId',
      queryParameters: {
        'page': page < 1 ? 1 : page,
        'limit': limit < 1 ? 10 : limit,
      },
    );
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return List<Map<String, dynamic>>.from(res.data['data'] as List);
    }
    throw Exception('Unexpected notifications response');
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _ready();
    final res = await tenantDio.put(
      kMarkNotificationReadPath,
      data: {
        "notificationIds": [notificationId]
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${res.statusCode}');
    }
  }
}

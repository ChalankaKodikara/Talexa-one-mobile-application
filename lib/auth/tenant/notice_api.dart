import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class NoticeApi {
  NoticeApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kNoticeBoardPath = '/v1/hris/noticeboard/all';

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty)
      throw Exception('Tenant baseUrl not ready');
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<List<Map<String, dynamic>>> fetchNotices() async {
    await _ready();
    final res = await tenantDio.get(kNoticeBoardPath);
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return List<Map<String, dynamic>>.from(res.data['data'] as List);
    }
    throw Exception('Unexpected notice board response');
  }
}

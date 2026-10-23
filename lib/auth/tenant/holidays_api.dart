import 'package:dio/dio.dart';

class HolidaysApi {
  static const String kHolidaysPath =
      'https://qst-back.talentfort.live/api/v1/holidays/holidays';

  Future<List<Map<String, dynamic>>> fetchHolidays() async {
    final dioClient = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final res = await dioClient.get(kHolidaysPath);

    if (res.statusCode == 200 &&
        res.data is Map &&
        res.data['holidays'] is List) {
      return List<Map<String, dynamic>>.from(res.data['holidays'] as List);
    }
    throw Exception('Unexpected holidays response');
  }
}

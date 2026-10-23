import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/auth_session.dart';

class ProfileApi {
  ProfileApi({required this.tenantDio, required this.session});

  final Dio tenantDio;
  final AuthSession session;

  static const String kProfileUploadPath =
      "/v1/hris/employees/profile-picture/upload";
  static const String kProfileUpdatePath =
      "/v1/hris/employees/profile-picture/update";
  static const String kProfileImagePath = "/v1/hris/employees/profile-picture";

  Future<void> _ready() async {
    await session.initialize();
    if ((session.apiBaseUrl ?? '').isEmpty)
      throw Exception('Tenant baseUrl not ready');
    tenantDio.options.baseUrl = session.apiBaseUrl!;
  }

  Future<String?> fetchProfileImage(String employeeId) async {
    await _ready();
    try {
      final res = await tenantDio.get(
        "$kProfileImagePath/$employeeId",
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.statusCode == 200 && res.data != null) {
        final bytes = res.data as List<int>;
        final base64Image = base64Encode(bytes);
        return "data:image/png;base64,$base64Image";
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<bool> hasProfileImage(String employeeId) async {
    await _ready();
    try {
      final res = await tenantDio.get(
        "$kProfileImagePath/$employeeId",
        options: Options(responseType: ResponseType.bytes),
      );
      return res.statusCode == 200 && res.data != null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveProfileImage(
      String filePath, String employeeId) async {
    await _ready();

    final file =
        await MultipartFile.fromFile(filePath, filename: 'profile_picture.jpg');
    final formData =
        FormData.fromMap({'employee_no': employeeId, 'profile_picture': file});

    final exists = await hasProfileImage(employeeId);
    final path = exists ? kProfileUpdatePath : kProfileUploadPath;

    final res = await tenantDio.request(
      path,
      data: formData,
      options: Options(
          method: exists ? 'PUT' : 'POST', contentType: 'multipart/form-data'),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
    }
    throw Exception('Failed to save profile image: ${res.statusCode}');
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/auth_constants.dart';
import '../core/auth_session.dart';

class PermissionApi {
  final Dio tenantDio;
  final AuthSession session;

  PermissionApi({
    required this.tenantDio,
    required this.session,
  });

  Future<List<int>> getPermission(String email) async {
    try {
      await session.initialize();

      if ((session.apiBaseUrl ?? '').isEmpty) {
        throw Exception(
          'HRIS backend URL not initialized. User must login first.',
        );
      }

      tenantDio.options.baseUrl = session.apiBaseUrl!;

      final encodedEmail = Uri.encodeComponent(email);
      final response = await tenantDio.get(
        "${AuthConstants.kGetPermissionPath}$encodedEmail",
      );

      // ignore: avoid_print
      print(
        "🟢 Full Permission Response:\n"
        "${const JsonEncoder.withIndent("  ").convert(response.data)}",
      );

      if (response.statusCode == 200 && response.data is Map) {
        final root = Map<String, dynamic>.from(response.data);

        if (root['success'] == true && root['data'] != null) {
          final data = Map<String, dynamic>.from(root['data']);

          final userRaw = data['user'];
          final permissionsRaw = data['permissions'];

          final Map<String, dynamic> user = userRaw is Map<String, dynamic>
              ? userRaw
              : Map<String, dynamic>.from(userRaw ?? {});

          final List<int> permissions = permissionsRaw is List
              ? permissionsRaw
                  .map((e) => int.tryParse(e.toString()) ?? 0)
                  .toList()
              : <int>[];

          // Save full user object from permission response
          await session.saveUserFromPermission(user);

          // Save permissions list
          await session.savePermissions(permissions);

          return permissions;
        }
      }

      return [];
    } on DioException catch (e) {
      // ignore: avoid_print
      print('❌ Error fetching permissions: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('❌ Unexpected error fetching permissions: $e');
      return [];
    }
  }
}

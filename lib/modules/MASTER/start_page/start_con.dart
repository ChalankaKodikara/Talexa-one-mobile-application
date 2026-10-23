import 'dart:convert';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:corehris/utils/app_alert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/auth/authservices.dart';

class LandingController extends GetxController {
  final AuthService _authService = AuthService();

  // -------------------- Identity --------------------
  final username = ''.obs;
  final employeeName = ''.obs;
  final organizationName = ''.obs;
  final profileImageUrl = RxnString();

  // -------------------- UI --------------------
  final searchText = ''.obs;
  final isLoading = false.obs;

  // -------------------- Systems/Services --------------------
  final services = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadIdentityFromCache();
    loadSystemsFromCache();
  }

  // =========================================================
  // LOAD USER IDENTITY
  // =========================================================
  Future<void> loadIdentityFromCache() async {
    final prefs = await SharedPreferences.getInstance();

    username.value = prefs.getString('username') ?? '';
    employeeName.value = prefs.getString('employee_calling_name') ?? '';
    organizationName.value = prefs.getString('organization_name') ?? '';

    final cachedImg = prefs.getString('profileImageUrl');
    if (cachedImg != null && cachedImg.isNotEmpty) {
      profileImageUrl.value = cachedImg;
    }
  }

  // =========================================================
  // LOAD SYSTEMS FROM LOGIN RESPONSE
  // =========================================================
  Future<void> loadSystemsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('systems_json');

    if (raw == null || raw.isEmpty) {
      services.clear();
      return;
    }

    final List decoded = jsonDecode(raw);

    final List<Map<String, dynamic>> built = decoded.map((s) {
      final Map sys = s as Map;

      final systemName = (sys['system_name'] ?? '').toString();
      final systemCode = (sys['system_code'] ?? '').toString();
      final backendUrl = sys['backend_url']?.toString();
      final frontendUrl = sys['frontend_url']?.toString();

      final modules = (sys['modules'] is List)
          ? List<Map<String, dynamic>>.from(
              (sys['modules'] as List)
                  .map((m) => Map<String, dynamic>.from(m as Map)),
            )
          : <Map<String, dynamic>>[];

      return {
        "system_id": sys['system_id'],
        "system_code": systemCode,
        "system_name": systemName,
        "title": systemName.isNotEmpty ? systemName : systemCode,
        "backend_url": backendUrl,
        "frontend_url": frontendUrl,
        "modules": modules,
        "icon": _iconForSystem(systemName, systemCode),
        "isAvailable": (backendUrl != null && backendUrl.trim().isNotEmpty),
      };
    }).toList();

    services.assignAll(built);
  }

  static IconData _iconForSystem(String name, String code) {
    final key = (name + code).toLowerCase();
    if (key.contains('hrms')) return Icons.people_outline;
    if (key.contains('fms') || key.contains('finance')) {
      return Icons.trending_up;
    }
    return Icons.apps;
  }

  // =========================================================
  // SEARCH
  // =========================================================
  void onSearch(String value) => searchText.value = value;

  List<Map<String, dynamic>> get filteredServices {
    if (searchText.value.isEmpty) return services;

    return services
        .where((s) => (s['title'] ?? '')
            .toString()
            .toLowerCase()
            .contains(searchText.value.toLowerCase()))
        .toList();
  }

  // =========================================================
  // SYSTEM SELECTION (🔥 PROPER SWITCH)
  // =========================================================
  Future<void> onSelectService(Map<String, dynamic> selected) async {
    final systemCode = selected['system_code']?.toString() ?? '';
    final isAvailable = selected['isAvailable'] == true;

    if (!isAvailable) {
      AppAlert.toast(
        title: "System not configured",
        message: "Backend URL is not available for $systemCode",
      );
      return;
    }

    try {
      isLoading.value = true;

      // ✅ Proper system switch (updates baseUrl + session)
      await _authService.switchSystem(systemCode);

      // ✅ Navigate based on system
      final codeLower = systemCode.toLowerCase();

      if (codeLower.contains('hrms')) {
        Get.offAll(DashboardScreen());
        return;
      }

      if (codeLower.contains('fms') || codeLower.contains('finance')) {
        AppAlert.toast(
          title: "Under Development",
          message: "System: $systemCode",
        );
        return;
      }

      // fallback
      AppAlert.toast(
        title: "Selected",
        message: "System: $systemCode",
      );
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================
  Future<void> logout() async {
    final context = Get.context;

    if (context == null) {
      return;
    }

    final confirmed = await AppAlert.confirm(
      context: context,
      title: "Confirm Logout",
      message: "Are you sure you want to logout?",
      confirmText: "Logout",
      isDestructive: true,
    );

    if (confirmed == true) {
      await _authService.logout();
    }
  }

  // =========================================================
  // GREETING
  // =========================================================
  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good Morning";
    if (h < 17) return "Good Afternoon";
    return "Good Evening";
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const _prefKey = 'isDarkMode';

  final themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey) ?? false;

    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    Get.changeThemeMode(themeMode.value);
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final newMode =
        themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    themeMode.value = newMode;
    await prefs.setBool(_prefKey, newMode == ThemeMode.dark);

    Get.changeThemeMode(newMode);
  }

  bool get isDark => themeMode.value == ThemeMode.dark;
}

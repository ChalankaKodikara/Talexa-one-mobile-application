import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// 🎨 APP COLORS
/// ============================================================
class AppColors {
  // Primary
  static const Color primary1 = Color(0xFF2495FE);
  static const Color primary2 = Color(0xFF1961AD);
  static const Color primary3 = Color(0xFF3E3852);
  static const Color primary4 = Color(0xFFCCAA39);
  static const Color primary5 = Color(0xFFA5A3AE);

  // Text
  static const Color textColorPrimary = Color(0xFF111827);
  static const Color textColorSecondary = Color(0xFF6B7280);
  static const Color textColorTertiary = Color(0xFF4B5563);

  // Status
  static const Color success = Color(0xFF28C76F);
  static const Color danger = Color(0xFFEA5455);
  static const Color warning = Color(0xFFFF9F43);
  static const Color info = Color(0xFF00C1D4);

  static const Color errorColor = Color(0xFFB00020);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color hintColor = Color(0xFF9E9E9E);

  // Light
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // Dark
  static const Color darkBackground = Color(0xFF0B1020);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF151C2C);
  static const Color darkBorder = Color(0xFF263244);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);
}

/// ============================================================
/// 🌞 LIGHT THEME
/// ============================================================
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary1,
    onPrimary: Colors.white,
    secondary: AppColors.primary2,
    onSecondary: Colors.white,
    error: AppColors.errorColor,
    onError: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textColorPrimary,
  ),
  scaffoldBackgroundColor: AppColors.lightBackground,
  primaryColor: AppColors.primary1,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.textColorPrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(
      color: AppColors.textColorPrimary,
    ),
    titleTextStyle: TextStyle(
      color: AppColors.textColorPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.textColorPrimary,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      color: AppColors.textColorPrimary,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      color: AppColors.textColorPrimary,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      color: AppColors.textColorPrimary,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: AppColors.textColorPrimary,
    ),
    bodyMedium: TextStyle(
      color: AppColors.textColorSecondary,
    ),
    bodySmall: TextStyle(
      color: AppColors.textColorSecondary,
    ),
  ),
  iconTheme: const IconThemeData(
    color: AppColors.textColorSecondary,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.lightBorder,
    thickness: 1,
    space: 1,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(
        color: AppColors.lightBorder,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary1,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary1,
      side: const BorderSide(
        color: AppColors.primary1,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary1,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(
      color: AppColors.hintColor,
    ),
    labelStyle: const TextStyle(
      color: AppColors.textColorSecondary,
    ),
    prefixIconColor: AppColors.textColorSecondary,
    suffixIconColor: AppColors.textColorSecondary,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 15,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.lightBorder,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.lightBorder,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.primary1,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.danger,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.danger,
        width: 1.5,
      ),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primary1,
    unselectedItemColor: Colors.grey,
    elevation: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: AppColors.primary1.withOpacity(.12),
    surfaceTintColor: Colors.transparent,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary1,
    foregroundColor: Colors.white,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary1,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    modalBackgroundColor: Colors.white,
  ),
);

/// ============================================================
/// 🌙 DARK THEME
/// ============================================================
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4DA3FF),
    onPrimary: Colors.white,
    secondary: AppColors.primary1,
    onSecondary: Colors.white,
    error: Color(0xFFFF6B6B),
    onError: Colors.white,
    surface: AppColors.darkCard,
    onSurface: AppColors.darkTextPrimary,
  ),
  scaffoldBackgroundColor: AppColors.darkBackground,
  primaryColor: AppColors.primary1,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkTextPrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(
      color: AppColors.darkTextPrimary,
    ),
    titleTextStyle: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: AppColors.darkTextPrimary,
    ),
    bodyMedium: TextStyle(
      color: AppColors.darkTextSecondary,
    ),
    bodySmall: TextStyle(
      color: AppColors.darkTextMuted,
    ),
  ),
  iconTheme: const IconThemeData(
    color: AppColors.darkTextSecondary,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorder,
    thickness: 1,
    space: 1,
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(
        color: AppColors.darkBorder,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary1,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF60A5FA),
      side: const BorderSide(
        color: Color(0xFF3B82F6),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF60A5FA),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkCard,
    hintStyle: const TextStyle(
      color: Color(0xFF64748B),
    ),
    labelStyle: const TextStyle(
      color: AppColors.darkTextMuted,
    ),
    prefixIconColor: AppColors.darkTextMuted,
    suffixIconColor: AppColors.darkTextMuted,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 15,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.darkBorder,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.darkBorder,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.primary1,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFFF6B6B),
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFFF6B6B),
        width: 1.5,
      ),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: Color(0xFF4DA3FF),
    unselectedItemColor: Color(0xFF64748B),
    elevation: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: AppColors.primary1.withOpacity(.18),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: Color(0xFF60A5FA),
          );
        }

        return const IconThemeData(
          color: Color(0xFF64748B),
        );
      },
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: Color(0xFF60A5FA),
            fontWeight: FontWeight.w600,
          );
        }

        return const TextStyle(
          color: AppColors.darkTextMuted,
        );
      },
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary1,
    foregroundColor: Colors.white,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary1,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }

        return AppColors.darkTextMuted;
      },
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary1;
        }

        return const Color(0xFF334155);
      },
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.darkCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.darkCard,
    surfaceTintColor: Colors.transparent,
    modalBackgroundColor: AppColors.darkCard,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF1E293B),
    contentTextStyle: const TextStyle(
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);

/// ============================================================
/// 🎛 THEME CONTROLLER
/// ============================================================
class ThemeController extends GetxController {
  static const String _prefKey = 'isDarkMode';

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final bool isDark = prefs.getBool(_prefKey) ?? false;

    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;

    Get.changeThemeMode(
      themeMode.value,
    );
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final ThemeMode newMode =
        themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    themeMode.value = newMode;

    await prefs.setBool(
      _prefKey,
      newMode == ThemeMode.dark,
    );

    Get.changeThemeMode(newMode);
  }

  Future<void> setDarkMode(
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final ThemeMode mode = enabled ? ThemeMode.dark : ThemeMode.light;

    themeMode.value = mode;

    await prefs.setBool(
      _prefKey,
      enabled,
    );

    Get.changeThemeMode(mode);
  }

  bool get isDark => themeMode.value == ThemeMode.dark;
}

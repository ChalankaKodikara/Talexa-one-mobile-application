// ignore_for_file: deprecated_member_use, depend_on_referenced_packages, unused_local_variable

import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/device_info.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/security/pages/security_page.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/viewprofile.dart';
import 'package:corehris/modules/HRMS/notifications/notifiation_settings_page.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutProfileController extends GetxController {
  final username = ''.obs;
  final employeeName = ''.obs;
  final useremail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    username.value = prefs.getString('username') ?? '';
    employeeName.value = prefs.getString('employee_fullname') ?? '';

    useremail.value = prefs.getString('useremail') ??
        prefs.getString('email') ??
        prefs.getString('username') ??
        '';
  }

  Future<void> confirmLogout() async {
    final context = Get.context;

    if (context == null) {
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: colorScheme.surface,
          elevation: 12,
          shadowColor: Colors.black.withOpacity(
            isDark ? 0.45 : 0.18,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to log out from this device?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> logout() async {
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    final prefs = await SharedPreferences.getInstance();

    // Remove authentication/session values.
    await prefs.remove('token');
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    // Add your actual authentication preference keys here when required.
    //
    // Do not clear username and employee details unless you want the
    // login page to forget the previously logged-in user.

    username.value = '';
    employeeName.value = '';
    useremail.value = '';

    Get.offAll(() => const LoginScreen());
  }
}

class LogoutProfile extends StatelessWidget {
  LogoutProfile({super.key});

  final LogoutProfileController controller =
      Get.isRegistered<LogoutProfileController>()
          ? Get.find<LogoutProfileController>()
          : Get.put(LogoutProfileController());

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = colorScheme.surface;
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurface.withOpacity(0.65);
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: titleColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: titleColor,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _profileHeroCard(
                context,
                employeeName: controller.employeeName.value,
                useremail: controller.useremail.value,
                username: controller.username.value,
              ),
              const SizedBox(height: 22),
              _sectionTitle(
                context,
                'Account',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 10),
              _buildSettingsTile(
                context,
                icon: Icons.badge_outlined,
                iconBackgroundColor: AppColors.primary2.withOpacity(0.14),
                iconColor: AppColors.primary2,
                title: 'Profile',
                subtitle: 'View and manage your profile information',
                onTap: () => Get.to(() => ViewProfile()),
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
              _buildSettingsTile(
                context,
                icon: Icons.lock_outline_rounded,
                iconBackgroundColor: AppColors.success.withOpacity(0.14),
                iconColor: AppColors.success,
                title: 'Privacy & Security',
                subtitle: 'Password, login and security settings',
                onTap: () => Get.to(() => const SecurityPage()),
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
                   _buildSettingsTile(
                context,
                icon: Icons.lock_outline_rounded,
                iconBackgroundColor: AppColors.success.withOpacity(0.14),
                iconColor: AppColors.success,
                title: 'Device Information',
                subtitle: 'View and manage your device information',
                onTap: () => Get.to(() => const DeviceLogScreen()),
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 12),
              _sectionTitle(
                context,
                'Preferences',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 10),
              _buildSettingsTile(
                context,
                icon: Icons.notifications_active_outlined,
                iconBackgroundColor: AppColors.warning.withOpacity(0.14),
                iconColor: AppColors.warning,
                title: 'Push Notifications',
                subtitle: 'Manage alerts and notification preferences',
                onTap: () => Get.to(
                  () => NotificationSettingsPage(),
                ),
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
              ),
              Obx(() {
                final isDarkMode =
                    themeController.themeMode.value == ThemeMode.dark;

                return _buildSettingsTileWithSwitch(
                  context,
                  icon: isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconBackgroundColor: isDarkMode
                      ? Colors.blueGrey.withOpacity(0.22)
                      : Colors.amber.withOpacity(0.16),
                  iconColor: isDarkMode ? Colors.white : Colors.amber.shade800,
                  title: 'Dark Mode',
                  subtitle: isDarkMode ? 'Enabled' : 'Disabled',
                  value: isDarkMode,
                  onChanged: (_) {
                    themeController.toggleTheme();
                  },
                  cardColor: cardColor,
                  borderColor: borderColor,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                );
              }),
              const SizedBox(height: 12),
              _sectionTitle(
                context,
                'Session',
                icon: Icons.shield_outlined,
              ),
              const SizedBox(height: 10),
              _buildSettingsTile(
                context,
                icon: Icons.logout_rounded,
                iconBackgroundColor: AppColors.danger.withOpacity(0.14),
                iconColor: AppColors.danger,
                title: 'Logout',
                subtitle: 'Sign out from this device securely',
                onTap: controller.confirmLogout,
                isLogout: true,
                cardColor: cardColor,
                borderColor: borderColor,
                titleColor: AppColors.danger,
                subtitleColor: subtitleColor,
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Core HRIS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary2,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _profileHeroCard(
    BuildContext context, {
    required String employeeName,
    required String useremail,
    required String username,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayName =
        employeeName.trim().isNotEmpty ? employeeName.trim() : 'Employee Name';

    final displayEmail =
        useremail.trim().isNotEmpty ? useremail.trim() : 'User Email';

    final displayUsername =
        username.trim().isNotEmpty ? username.trim() : 'Active User';

    final initial = _getInitial(displayName);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF1D2538),
                  Color(0xFF111827),
                ]
              : [
                  AppColors.primary2,
                  AppColors.primary1,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary2.withOpacity(
              isDark ? 0.18 : 0.24,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(
              isDark ? 0.08 : 0.14,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      displayUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
        elevation: isDark ? 2 : 1,
        shadowColor: Colors.black.withOpacity(
          isDark ? 0.28 : 0.12,
        ),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: borderColor,
          ),
        ),
        child: ListTile(
          minLeadingWidth: 0,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: iconColor.withOpacity(0.18),
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                      height: 1.35,
                    ),
                  ),
                ),
          trailing: isLogout
              ? null
              : Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: subtitleColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: subtitleColor.withOpacity(0.9),
                  ),
                ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSettingsTileWithSwitch(
    BuildContext context, {
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
        elevation: isDark ? 2 : 1,
        shadowColor: Colors.black.withOpacity(
          isDark ? 0.28 : 0.12,
        ),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: borderColor,
          ),
        ),
        child: ListTile(
          minLeadingWidth: 0,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: iconColor.withOpacity(0.18),
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                      height: 1.35,
                    ),
                  ),
                ),
          trailing: Transform.scale(
            scale: 0.95,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary1,
              inactiveThumbColor: colorScheme.onSurface.withOpacity(0.75),
              inactiveTrackColor: colorScheme.onSurface.withOpacity(0.18),
            ),
          ),
          onTap: () {
            onChanged(!value);
          },
        ),
      ),
    );
  }

  String _getInitial(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'E';
    }

    return trimmedName.substring(0, 1).toUpperCase();
  }
}

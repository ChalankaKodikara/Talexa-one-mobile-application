import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/device_info.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/security/pages/security_page.dart';
import 'package:corehris/modules/HRMS/notifications/notifiation_settings_page.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Settings screen: same clean grouped-list styling as the Talexa drawer.
/// The profile hero and Profile menu entry have intentionally been removed.
class LogoutProfile extends StatefulWidget {
  const LogoutProfile({super.key});

  @override
  State<LogoutProfile> createState() => _LogoutProfileState();
}

class _LogoutProfileState extends State<LogoutProfile> {
  static const Color _blue = Color(0xFF1769E8);
  static const Color _ink = Color(0xFF182237);
  static const Color _muted = Color(0xFF7E8CA2);

  bool _signingOut = false;

  Future<void> _confirmLogout() async {
    if (_signingOut) return;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dark ? const Color(0xFF1C2635) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Sign out?',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : _ink,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of Talexa HRMS?',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: dark ? Colors.white70 : _muted,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: dark ? Colors.white : _ink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64550),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _signingOut) return;
    setState(() => _signingOut = true);
    try {
      // Clears tokens, cookies and session through the existing app service.
      await AuthService().logout();
      if (!mounted) return;
      Get.offAll(() => const LoginScreen());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final panel = dark ? const Color(0xFF1B2638) : Colors.white;
    final ink = dark ? Colors.white : _ink;
    final muted = dark ? const Color(0xFF9DAEC4) : _muted;
    final divider = dark ? Colors.white12 : const Color(0xFFECEFF3);
    final themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style:
              TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
          children: [
            _sectionLabel('ACCOUNT', muted),
            const SizedBox(height: 9),
            _group(panel, divider, [
              _row(
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                dark: dark,
                onTap: () => Get.to(() => const SecurityPage()),
              ),
              _line(divider),
              _row(
                icon: Icons.smartphone_outlined,
                title: 'Device Information',
                dark: dark,
                onTap: () => Get.to(() => const DeviceLogScreen()),
              ),
            ]),
            const SizedBox(height: 24),
            _sectionLabel('PREFERENCES', muted),
            const SizedBox(height: 9),
            _group(panel, divider, [
              _row(
                icon: Icons.notifications_none_rounded,
                title: 'Push Notifications',
                dark: dark,
                onTap: () => Get.to(() => NotificationSettingsPage()),
              ),
              _line(divider),
              Obx(() {
                final enabled =
                    themeController.themeMode.value == ThemeMode.dark;
                return _row(
                  icon: enabled
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  title: 'Dark Mode',
                  dark: dark,
                  trailing: Switch.adaptive(
                    value: enabled,
                    activeTrackColor: _blue,
                    onChanged: (_) => themeController.toggleTheme(),
                  ),
                  onTap: () => themeController.toggleTheme(),
                );
              }),
            ]),
            const SizedBox(height: 24),
            _sectionLabel('SESSION', muted),
            const SizedBox(height: 9),
            _group(panel, divider, [
              _row(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                dark: dark,
                danger: true,
                trailing: _signingOut
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFD64550)),
                      )
                    : null,
                onTap: _signingOut ? null : _confirmLogout,
              ),
            ]),
            const SizedBox(height: 28),
            Text(
              'Talexa HRMS  •  Smart workplace access',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: color,
          ),
        ),
      );

  Widget _group(Color background, Color divider, List<Widget> items) =>
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: items),
      );

  Widget _line(Color color) => Padding(
        padding: const EdgeInsets.only(left: 55),
        child: Divider(height: 1, thickness: 1, color: color),
      );

  Widget _row({
    required IconData icon,
    required String title,
    required bool dark,
    required VoidCallback? onTap,
    Widget? trailing,
    bool danger = false,
  }) {
    final foreground =
        danger ? const Color(0xFFD64550) : (dark ? Colors.white : _ink);
    final muted = dark ? Colors.white38 : _muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 21, color: foreground),
              const SizedBox(width: 17),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else if (!danger)
                Icon(Icons.chevron_right_rounded, size: 19, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

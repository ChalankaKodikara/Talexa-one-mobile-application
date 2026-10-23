import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/contactus/contact_us.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/controllers/dash_con.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/settings_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/viewprofile.dart';
import 'package:corehris/modules/HRMS/notifications/notification_screen.dart';
import 'package:corehris/modules/MASTER/start_page/start_con.dart';
import 'package:corehris/modules/MASTER/start_page/startpage.dart';
import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Profile-settings-style drawer: subtle canvas, grouped white rows,
/// no colored icon containers; preserves Talexa's original routes.
class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  late final LandingController landing;
  bool _signingOut = false;
  bool _modulesReady = false;
  int _accessibleModuleCount = 0;

  static const _blue = Color(0xFF1769E8);
  static const _ink = Color(0xFF182237);
  static const _muted = Color(0xFF7E8CA2);
  static const _line = Color(0xFFE8EDF5);

  @override
  void initState() {
    super.initState();
    landing = Get.isRegistered<LandingController>()
        ? Get.find<LandingController>()
        : Get.put(LandingController());
    _readModuleAccess();
  }

  Future<void> _readModuleAccess() async {
    int count = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('systems_json');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          count = decoded.where((entry) {
            if (entry is! Map) return false;
            return (entry['backend_url']?.toString().trim() ?? '').isNotEmpty;
          }).length;
        }
      } else {
        count = landing.services.where((s) => s['isAvailable'] == true).length;
      }
    } catch (error) {
      debugPrint('Drawer module access check failed: $error');
      count = landing.services.where((s) => s['isAvailable'] == true).length;
    }
    if (!mounted) return;
    setState(() {
      _accessibleModuleCount = count;
      _modulesReady = true;
    });
  }

  void _open(BuildContext context, Widget Function() page) {
    Navigator.of(context).pop();
    Get.to(page,
        transition: Transition.cupertino,
        duration: const Duration(milliseconds: 300));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    if (_signingOut) return;

    // Show the confirmation while this drawer is still mounted.
    // Closing the drawer before presenting a dialog can dispose its context.
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_signingOut,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Sign out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to sign out of Talexa HRMS?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _blue),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || _signingOut) return;
    setState(() => _signingOut = true);

    // Dismiss the drawer once, then clear the authenticated session.
    // Do not setState after this: the drawer will be disposed.
    Navigator.of(context).pop();

    try {
      await AuthService().logout();

      // Remove stale in-memory modules so another user cannot see them.
      if (Get.isRegistered<LandingController>()) {
        landing.services.clear();
        landing.searchText.value = '';
      }

      // Reset the whole navigation stack to the real login page.
      Get.offAll(() => const LoginScreen());
    } catch (error, stackTrace) {
      debugPrint('Drawer sign out failed: $error\n$stackTrace');
      Get.snackbar(
        'Sign out failed',
        'Unable to clear your session. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final canvas = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final muted = dark ? const Color(0xFFA0AABA) : _muted;
    final showSwitcher = _modulesReady && _accessibleModuleCount > 1;
    final drawerWidth =
        (MediaQuery.sizeOf(context).width * .86).clamp(0.0, 350.0);

    return Drawer(
      elevation: 0,
      width: drawerWidth,
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 18, 12),
              child: Row(
                children: [
                  Text('Profile',
                      style: TextStyle(
                        color: dark ? Colors.white : _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close menu',
                    icon: Icon(Icons.close_rounded, color: muted, size: 21),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ColoredBox(
                    color: surface, child: _ProfileHeader(dark: dark)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                children: [
                  _SectionLabel('ACCOUNT', dark: dark),
                  _MenuGroup(
                    dark: dark,
                    children: [
                      if (showSwitcher)
                        _NavItem(
                          icon: Icons.home_outlined,
                          title: 'Home',
                          onTap: () =>
                              _open(context, () => const LandingPage()),
                          dark: dark,
                        ),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Manage Profile',
                        onTap: () => _open(context, () => const ViewProfile()),
                        dark: dark,
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () => _open(context, () => LogoutProfile()),
                        dark: dark,
                      ),
                      _NavItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () => _open(context, () => NotificationScreen()),
                        dark: dark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('PREFERENCES', dark: dark),
                  _MenuGroup(
                    dark: dark,
                    children: [
                      if (showSwitcher)
                        _NavItem(
                          icon: Icons.grid_view_outlined,
                          title: 'Main Menu',
                          onTap: () =>
                              _open(context, () => const LandingPage()),
                          dark: dark,
                        ),
                      _NavItem(
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        subtitle: dark ? 'Dark' : 'Light',
                        onTap: () => _open(context, () => LogoutProfile()),
                        dark: dark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('SUPPORT', dark: dark),
                  _MenuGroup(
                    dark: dark,
                    children: [
                      _NavItem(
                        icon: Icons.headset_mic_outlined,
                        title: 'Contact Us',
                        onTap: () => _open(context, () => const ContactUs()),
                        dark: dark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('SESSION', dark: dark),
                  _MenuGroup(
                    dark: dark,
                    children: [
                      _NavItem(
                        icon: Icons.logout_rounded,
                        title: 'Sign out',
                        onTap: () {
                          _confirmLogout(context);
                        },
                        dark: dark,
                        danger: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 20),
              child: Text('Talexa HRMS  •  Smart workplace access',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.dark});
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
        child: Text(text,
            style: TextStyle(
              letterSpacing: 0.6,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white54 : const Color(0xFF8B9099),
            )),
      );
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children, required this.dark});
  final List<Widget> children;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B2638) : Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i != 0)
              Divider(
                height: 1,
                thickness: 0.65,
                indent: 47,
                color: dark ? Colors.white10 : _MyDrawerState._line,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.dark,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool dark;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? const Color(0xFFD64550)
        : dark
            ? Colors.white
            : _MyDrawerState._ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              if (subtitle != null) ...[
                Text(subtitle!,
                    style: TextStyle(
                      color: dark ? Colors.white54 : _MyDrawerState._muted,
                      fontSize: 11,
                    )),
                const SizedBox(width: 7),
              ],
              if (!danger)
                Icon(Icons.chevron_right_rounded,
                    size: 17,
                    color: dark ? Colors.white38 : _MyDrawerState._muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.dark});
  final bool dark;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  late final DashboardController controller;
  String? cachedValue;
  ImageProvider? cachedImage;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());
  }

  ImageProvider? _image(String value) {
    if (value == cachedValue) return cachedImage;
    cachedValue = value;
    try {
      if (value.isEmpty) return cachedImage = null;
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return cachedImage = NetworkImage(value);
      }
      return cachedImage = MemoryImage(
          base64Decode(value.contains(',') ? value.split(',').last : value));
    } catch (_) {
      return cachedImage = null;
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final name = controller.employeeName.value.trim();
        final username = controller.username.value.trim();
        final image = _image(controller.profileImageUrl.value ?? '');
        final dark = widget.dark;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const ViewProfile(),
                  transition: Transition.cupertino);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: dark
                    ? const LinearGradient(
                        colors: [Color(0xFF17253B), Color(0xFF101623)])
                    : const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFD8E9FF),
                    backgroundImage: image,
                    child: image == null
                        ? const Icon(Icons.person_outline_rounded,
                            size: 28, color: _MyDrawerState._blue)
                        : null,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isEmpty ? 'Welcome back' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color:
                                    dark ? Colors.white : _MyDrawerState._ink)),
                        const SizedBox(height: 4),
                        Text(username.isEmpty ? 'Your workspace' : username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: dark
                                    ? Colors.white60
                                    : _MyDrawerState._muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_outward_rounded,
                      size: 19,
                      color: dark ? Colors.white70 : _MyDrawerState._blue),
                ],
              ),
            ),
          ),
        );
      });
}

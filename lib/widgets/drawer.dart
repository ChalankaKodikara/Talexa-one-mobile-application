import 'dart:convert';
import 'package:corehris/modules/HRMS/contactus/contact_us.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/settings_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/viewprofile.dart';
import 'package:corehris/modules/HRMS/notifications/notification_screen.dart';
import 'package:corehris/modules/MASTER/start_page/startpage.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/controllers/dash_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      elevation: 0,
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            _ModernDrawerHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                child: Column(
                  children: [
                    _DrawerSection(
                      title: "Main",
                      children: [
                        _DrawerTile(
                          icon: Icons.home_rounded,
                          title: "Home",
                          subtitle: "Go to dashboard home",
                          onTap: () {
                            Navigator.pop(context);
                            try {
                              Get.to(() => const LandingPage());
                            } catch (_) {}
                          },
                        ),
                        _DrawerTile(
                          icon: Icons.person_rounded,
                          title: "Profile",
                          subtitle: "View your profile details",
                          onTap: () {
                            Navigator.pop(context);
                            try {
                              Get.to(() => const ViewProfile());
                            } catch (_) {}
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DrawerSection(
                      title: "Preferences",
                      children: [
                        _DrawerTile(
                          icon: Icons.settings_rounded,
                          title: "Settings",
                          subtitle: "Manage app preferences",
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => LogoutProfile());
                          },
                        ),
                        _DrawerTile(
                          icon: Icons.grid_view_rounded,
                          title: "Main Menu",
                          subtitle: "Back to system menu",
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => const LandingPage());
                          },
                        ),
                        _DrawerTile(
                          icon: Icons.notification_add,
                          title: "Notifications",
                          subtitle: "Manage your notifications",
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => NotificationScreen());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DrawerSection(
                      title: "Support",
                      children: [
                        _DrawerTile(
                          icon: Icons.support_agent_rounded,
                          title: "Contact Us",
                          subtitle: "Reach our support team",
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => const ContactUs());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFooterCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ]
              : const [
                  Color(0xFFEFF6FF),
                  Color(0xFFF8FAFC),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary2.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primary2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Talexa HRMS • Smart workplace access",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDrawerHeader extends StatefulWidget {
  @override
  State<_ModernDrawerHeader> createState() => _ModernDrawerHeaderState();
}

class _ModernDrawerHeaderState extends State<_ModernDrawerHeader> {
  late final DashboardController _controller;
  String? _cachedImageValue;
  ImageProvider? _cachedImageProvider;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());
  }

  ImageProvider? _profileImageProvider(String value) {
    if (_cachedImageValue == value) {
      return _cachedImageProvider;
    }

    _cachedImageValue = value;

    if (value.isEmpty) {
      _cachedImageProvider = null;
      return null;
    }

    try {
      if (value.startsWith('http')) {
        _cachedImageProvider = NetworkImage(value);
      } else if (value.startsWith('data:image')) {
        _cachedImageProvider = MemoryImage(base64Decode(value.split(',').last));
      } else {
        _cachedImageProvider = MemoryImage(base64Decode(value));
      }
    } catch (_) {
      _cachedImageProvider = null;
    }

    return _cachedImageProvider;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(
      () {
        final ctrl = _controller;
        final name = ctrl.employeeName.value.isNotEmpty
            ? ctrl.employeeName.value
            : 'User';
        final username =
            ctrl.username.value.isNotEmpty ? ctrl.username.value : 'Employee';
        final url = ctrl.profileImageUrl.value ?? '';
        final image = _profileImageProvider(url);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2563EB),
                Color(0xFF3B82F6),
                Color(0xFF4F46E5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary2.withOpacity(0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.pop(context);
              try {
                Get.to(() => const ViewProfile());
              } catch (_) {}
            },
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withOpacity(0.16),
                        backgroundImage: image,
                        child: image == null
                            ? const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 32,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.88),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white.withOpacity(0.95),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Tap to view your profile",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      },
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE5EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary2.withOpacity(isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary2,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

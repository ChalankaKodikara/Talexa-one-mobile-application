// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:io';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance_adjustment_home.dart';
import 'package:corehris/modules/HRMS/main_screens/facilities/claim_status_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/overtime/screens/overtime_assign_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/teamscreen/screens/team_page.dart';
import 'package:corehris/modules/HRMS/main_screens/timesheet/screens/timesheet_screen.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/controllers/dash_con.dart';
import 'package:corehris/modules/HRMS/main_screens/attendance/pages/attendance.dart';
import 'package:corehris/modules/HRMS/main_screens/leaves/leavemenu.dart';
import 'package:corehris/modules/HRMS/salary/screens/salary.dart';
import 'package:corehris/modules/HRMS/main_screens/reports/report_screen.dart';
import 'package:corehris/modules/HRMS/main_screens/noticeboard/screen/notice.dart';
import 'package:corehris/modules/HRMS/notifications/controller/notification_con.dart';
import 'package:corehris/modules/HRMS/notifications/notification_screen.dart';
import 'package:corehris/widgets/drawer.dart';
import 'dart:convert';
import 'package:corehris/widgets/live_mini_clock.dart';
import 'package:flutter/services.dart';
import 'package:corehris/utils/app_alert.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());
  final NotificationController notifController =
      Get.put(NotificationController());

  final PageController _pageController = PageController(viewportFraction: 1);
  int currentQuickPage = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _cachedProfileImageValue;
  ImageProvider? _cachedProfileImageProvider;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getAllItems() {
    final items = [
      {
        'icon': LucideIcons.umbrella,
        'label': 'Leaves',
        'color': const Color(0xFF22C55E),
        'bg': const Color(0xFFEAF8EF),
        'page': () => LeaveMenuScreen(),
      },
      {
        'icon': LucideIcons.fileText,
        'label': 'Claims',
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFEAF8EF),
        'page': () => ClaimListScreen(),
      },
      // {
      //   'icon': LucideIcons.dollarSign,
      //   'label': 'Loans',
      //   'color': const Color(0xFFEF4444),
      //   'bg': const Color(0xFFFDECEC),
      //   'page': () => LoanStatusPage(),
      // },
      {
        'icon': LucideIcons.wallet,
        'label': 'Payslip',
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF2EBFF),
        'page': () => const SalaryScreen(),
      },
      {
        'icon': LucideIcons.chartBar,
        'label': 'Reports',
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFF4DE),
        'page': () => ReportScreen(),
      },
      {
        'icon': LucideIcons.sheet,
        'label': 'Notices',
        'color': const Color(0xFFEAB308),
        'bg': const Color(0xFFFFF8D8),
        'page': () => const NoticeScreen(),
      },
      {
        'icon': LucideIcons.timer,
        'label': 'Time Sheet',
        'color': const Color(0xFF4F46E5),
        'bg': const Color(0xFFECEBFF),
        'page': () => TimesheetScreen(employeeNo: controller.username.value),
      },
      {
        'icon': LucideIcons.clock,
        'label': 'Overtime',
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFFEEE5),
        'page': () => OvertimeAssignScreen(),
      },
      {
        'icon': LucideIcons.edit3,
        'label': 'Attendance Adjustment',
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEAF4FF),
        'page': () => const AttendanceAdjustmentHome(),
      }
    ];

    if (_searchQuery.trim().isEmpty) return items;

    return items.where((item) {
      final label = (item['label'] ?? '').toString().toLowerCase();
      return label.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _refreshAll(BuildContext context) async {
    try {
      await Future.wait([
        controller.fetchTodayAttendance(),
        controller.fetchUpcomingBirthdays(),
        controller.fetchProfileImage(),
        controller.loadTeamPresence(),
        notifController.fetchNotifications(),
      ]);
    } catch (_) {
      AppAlert.toast(
        title: "Refresh failed",
        message: "Couldn’t refresh dashboard data. Please try again.",
      );
    }
  }

  TextStyle _headlineStyle(BuildContext context, {double size = 28}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.1,
      letterSpacing: -0.8,
      color: isDark ? Colors.white : const Color(0xFF191919),
    );
  }

  TextStyle _sectionTitleStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: isDark ? Colors.white : const Color(0xFF202228),
    );
  }

  TextStyle _titleStyle(BuildContext context, {double size = 15}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: isDark ? Colors.white : const Color(0xFF202228),
    );
  }

  TextStyle _bodyStyle(BuildContext context, {double size = 13}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF8A8F98),
    );
  }

  ImageProvider? _profileImageProvider(String imageValue) {
    if (_cachedProfileImageValue == imageValue) {
      return _cachedProfileImageProvider;
    }

    _cachedProfileImageValue = imageValue;

    if (imageValue.isEmpty) {
      _cachedProfileImageProvider = null;
      return null;
    }

    try {
      if (imageValue.startsWith('http')) {
        _cachedProfileImageProvider = NetworkImage(imageValue);
      } else if (imageValue.contains(',')) {
        _cachedProfileImageProvider = MemoryImage(
          base64Decode(imageValue.split(',').last),
        );
      } else {
        _cachedProfileImageProvider = MemoryImage(base64Decode(imageValue));
      }
    } catch (_) {
      _cachedProfileImageProvider = null;
    }

    return _cachedProfileImageProvider;
  }

  TextStyle _labelStyle(BuildContext context, {double size = 11.5}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: isDark ? Colors.white : const Color(0xFF202228),
    );
  }

  BoxDecoration _softCardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? const Color(0xFF151821) : const Color(0xFFFDFDFD),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color:
            isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFEDEEF2),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.18 : 0.045),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (Platform.isAndroid) {
          await SystemNavigator.pop();
          return false;
        }

        return true;
      },
      child: Scaffold(
        drawer: const MyDrawer(),
        backgroundColor:
            isDark ? const Color(0xFF0F1117) : const Color(0xFFF5F6F8),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary2,
            onRefresh: () => _refreshAll(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopAppleHeader(context),
                  const SizedBox(height: 18),
                  if (_isSearching) ...[
                    _buildSearchResults(context),
                  ] else ...[
                    const SizedBox(height: 22),
                    _buildQuickAccessCard(context),
                    const SizedBox(height: 5),
                    _buildSectionHeader(context, ""),
                    const SizedBox(height: 5),
                    _buildTodayOverview(context),
                    const SizedBox(height: 5),
                    _buildSectionHeader(
                      context,
                      "",
                      onSeeMore: () => Get.to(() => TeamPage()),
                    ),
                    const SizedBox(height: 5),
                    _buildTeamPresence(context),
                    const SizedBox(height: 5),
                    _buildSectionHeader(context, ""),
                    const SizedBox(height: 5),
                    _buildUpcomingBirthdays(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(BuildContext context) {
    final allItems = getAllItems();
    const itemsPerPage = 6;

    final pages = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < allItems.length; i += itemsPerPage) {
      pages.add(allItems.skip(i).take(itemsPerPage).toList());
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: _softCardDecoration(context),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() {
                  currentQuickPage = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                final pageItems = pages[pageIndex];
                final bool showTitle = pageIndex == 0;

                Widget tileAt(int index) {
                  if (index >= pageItems.length) {
                    return const SizedBox.shrink();
                  }

                  final item = pageItems[index];
                  return _QuickAccessTile(
                    icon: item['icon'],
                    label: item['label'],
                    color: item['color'],
                    bg: item['bg'],
                    onTap: () async {
                      try {
                        await Get.to(item['page']);
                      } catch (_) {
                        AppAlert.toast(
                          title: "Navigation failed",
                          message: "Couldn’t open this page.",
                        );
                      }
                    },
                  );
                }

                if (showTitle) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 95,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 118,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 12, left: 2),
                                  child: Text(
                                    "Quick\nAccess",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      height: 0.92,
                                      letterSpacing: -1.4,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111111),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            MediaQuery(
                                data: MediaQuery.of(context),
                                child: const SizedBox(width: 35)),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 0),
                                        child: tileAt(0),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 0),
                                        child: tileAt(1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: tileAt(2),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: tileAt(3),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: tileAt(4),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: tileAt(5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    runAlignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing: 18,
                    runSpacing: 18,
                    children: List.generate(pageItems.length, (index) {
                      final item = pageItems[index];
                      return _QuickAccessTile(
                        icon: item['icon'],
                        label: item['label'],
                        color: item['color'],
                        bg: item['bg'],
                        onTap: () async {
                          try {
                            await Get.to(item['page']);
                          } catch (_) {
                            AppAlert.toast(
                              title: "Navigation failed",
                              message: "Couldn’t open this page.",
                            );
                          }
                        },
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          if (pages.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentQuickPage == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: currentQuickPage == index
                        ? AppColors.primary2
                        : theme.dividerColor.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = getAllItems();

    if (_searchQuery.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          "Search for modules, services, or actions.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE8ECF3),
          ),
        ),
        child: Text(
          "No matching dashboard items found.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];

        return Container(
          margin: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121C2E) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFE8ECF3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () async {
                FocusScope.of(context).unfocus();
                try {
                  await Get.to(item['page']);
                } catch (_) {
                  AppAlert.toast(
                    title: "Navigation failed",
                    message: "Couldn’t open this page.",
                  );
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? (item['color'] as Color).withOpacity(0.16)
                            : item['bg'] as Color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isDark
                            ? (item['color'] as Color).withOpacity(0.95)
                            : item['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
          ),
        );
      }),
    );
  }

  Widget _buildTopAppleHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final String formattedDate =
        "${_monthShort(now.month)} ${now.day.toString().padLeft(2, '0')}";

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _isSearching
          ? Container(
              key: const ValueKey('searchMode'),
              height: 54,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF171A22) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFEAECEF),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? Colors.white.withOpacity(0.55)
                        : const Color(0xFF8B9098),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          currentQuickPage = 0;
                        });
                      },
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white : const Color(0xFF1B1D22),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search dashboard',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.white.withOpacity(0.35)
                              : const Color(0xFFB0B5BE),
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.to(() => const NotificationScreen());
                    },
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      size: 21,
                      color: isDark
                          ? Colors.white.withOpacity(0.75)
                          : const Color(0xFF5F6670),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                        currentQuickPage = 0;
                      });
                      FocusScope.of(context).unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppColors.primary2,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Row(
              key: const ValueKey('normalMode'),
              children: [
                Builder(
                  builder: (ctx) => _iosCircleIconButton(
                    ctx,
                    icon: Icons.menu_rounded,
                    onTap: () {
                      Scaffold.of(ctx).openDrawer();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() {
                  final imageValue = controller.profileImageUrl.value ?? '';
                  final imageProvider = _profileImageProvider(imageValue);

                  return Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.transparent,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? Icon(
                              Icons.person,
                              color:
                                  isDark ? Colors.white70 : AppColors.primary2,
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, ${controller.employeeName.value.isEmpty ? controller.username.value : controller.employeeName.value}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            letterSpacing: -0.5,
                            color:
                                isDark ? Colors.white : const Color(0xFF202228),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Today $formattedDate.",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white.withOpacity(0.58)
                                : const Color(0xFF8A8F98),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _iosCircleIconButton(
                  context,
                  icon: Icons.notifications_none_rounded,
                  onTap: () {
                    Get.to(() => const NotificationScreen());
                  },
                ),
                const SizedBox(width: 10),
                _iosCircleIconButton(
                  context,
                  icon: Icons.search_rounded,
                  onTap: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ],
            ),
    );
  }

  Widget _iosCircleIconButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF171B22) : const Color(0xFFF8F8FA),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : const Color(0xFFE8E8ED),
            ),
          ),
          child: Icon(
            icon,
            size: 21,
            color: isDark ? Colors.white70 : const Color(0xFF3A3A3C),
          ),
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildProfileFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF22252D) : const Color(0xFFF3F4F6),
      child: Icon(
        Icons.person_rounded,
        size: 26,
        color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Builder(
          builder: (ctx) => _appleTopButton(
            context,
            icon: Icons.menu_rounded,
            onTap: () {
              try {
                Scaffold.of(ctx).openDrawer();
              } catch (_) {}
            },
          ),
        ),
        const Spacer(),
        Obx(() {
          final unreadCount = notifController.notifications
              .where((n) => n['is_read'] == 0)
              .length;

          return Row(
            children: [
              _appleTopButton(
                context,
                icon: Icons.notifications_none_rounded,
                badge: unreadCount,
                onTap: () async {
                  try {
                    await Get.to(() => const NotificationScreen());
                    await notifController.fetchNotifications();
                  } catch (_) {
                    AppAlert.toast(
                      title: "Error",
                      message: "Failed to open notifications",
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              _appleTopButton(
                context,
                icon: Icons.logout_rounded,
                onTap: controller.confirmLogout,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _appleTopButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
    int badge = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF171B22) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF0F1F5),
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF453A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark ? const Color(0xFF171B22) : Colors.white,
                  width: 1.4,
                ),
              ),
              child: Text(
                badge > 99 ? "99+" : badge.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _topIconButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
    int badge = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121C2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFE9ECF3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Icon(
                icon,
                size: 22,
                color: theme.iconTheme.color,
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Text(
                badge > 99 ? "99+" : badge.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF0F1F5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, ${controller.username.value.isEmpty ? "User" : controller.username.value}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.greeting(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withOpacity(0.55)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF243042)
                          : const Color(0xFFE9EEFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "Talexa HRMS Dashboard",
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFAFC4FF)
                            : const Color(0xFF4F7CFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232834) : const Color(0xFFF2F4F8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'lib/images/talexa.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFEDEDF2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark
                ? Colors.white.withOpacity(0.42)
                : const Color(0xFFB3B3BA),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Search",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withOpacity(0.42)
                    : const Color(0xFFB3B3BA),
              ),
            ),
          ),
          Icon(
            Icons.mic_none_rounded,
            size: 20,
            color: isDark
                ? Colors.white.withOpacity(0.42)
                : const Color(0xFFB3B3BA),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessPager(BuildContext context) {
    final itemsPerPage = 8;
    final pages = <List<Map<String, dynamic>>>[];

    final allItems = getAllItems();

    for (int i = 0; i < allItems.length; i += itemsPerPage) {
      pages.add(
        allItems.skip(i).take(itemsPerPage).toList(),
      );
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121C2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8ECF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() {
                  currentQuickPage = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                final pageItems = pages[pageIndex];

                return GridView.builder(
                  itemCount: pageItems.length,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final item = pageItems[index];
                    return _QuickAccessTile(
                      icon: item['icon'],
                      label: item['label'],
                      color: item['color'],
                      bg: item['bg'],
                      onTap: () async {
                        try {
                          await Get.to(item['page']);
                        } catch (_) {
                          AppAlert.toast(
                            title: "Navigation failed",
                            message: "Couldn’t open this page.",
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (pages.length > 1) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentQuickPage == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: currentQuickPage == index
                        ? AppColors.primary2
                        : theme.dividerColor.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayOverview(BuildContext context) {
    return Obx(() {
      if (controller.isOnLeaveToday.value &&
          controller.todayApprovedLeave.value != null) {
        final leave = controller.todayApprovedLeave.value!;
        return _leaveWidget(
          context,
          leave['leave_type'] ?? 'Leave',
          leave['from_date'],
          leave['to_date'],
        );
      }

      if (controller.isLoadingAttendance.value) {
        return _loadingState(context, "Loading attendance...");
      }

      if (controller.attendanceError.value.isNotEmpty) {
        return _errorState(context, controller.attendanceError.value);
      }

      return _buildDailyAttendanceCard(context);
    });
  }

  Widget _buildDailyAttendanceCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final checkIn = controller.checkINTime.value.trim().isEmpty ||
            controller.checkINTime.value == "--"
        ? "--:--"
        : controller.checkINTime.value;

    final checkOut = controller.checkOutTime.value.trim().isEmpty ||
            controller.checkOutTime.value == "--"
        ? "--:--"
        : controller.checkOutTime.value;

    final checkInStatus = controller.checkINType.value.trim().isEmpty
        ? "Not Yet"
        : controller.checkINType.value;

    final checkOutStatus = controller.checkOutType.value.trim().isEmpty
        ? "Not Yet"
        : controller.checkOutType.value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () async {
          try {
            await Get.to(
              () => AttendancePage(username: controller.username.value),
            );
          } catch (_) {
            AppAlert.toast(
              title: "Navigation failed",
              message: "Couldn’t open attendance page.",
            );
          }
        },
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF1D4ED8),
                      Color(0xFF2563EB),
                      Color(0xFF3B82F6),
                    ]
                  : const [
                      Color(0xFF60A5FA),
                      Color(0xFF3B82F6),
                      Color(0xFF2563EB),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.28),
                        width: 1.4,
                      ),
                    ),
                    child: const Center(
                      child: LiveMiniClock(size: 64),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 65,
                    height: 65,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A1020),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.north_east_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                "Daily\nAttendance",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  height: 0.95,
                  letterSpacing: -1.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _attendanceMiniInfo(
                      title: "Check In",
                      value: checkIn,
                      subtitle: checkInStatus,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _attendanceMiniInfo(
                      title: "Check Out",
                      value: checkOut,
                      subtitle: checkOutStatus,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tap to mark attendance now",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendanceMiniInfo({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.8,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceInfoCard(
    BuildContext context, {
    required String title,
    required String time,
    required String status,
    required IconData icon,
    required Color iconColor,
    required Color badgeBg,
    required Color badgeText,
  }) {
    final theme = Theme.of(context);

    final displayTime =
        time.trim().isEmpty || time == "--:--" || time == "--" ? "--:--" : time;

    final displayStatus =
        status.trim().isEmpty || status.toLowerCase() == "not yet"
            ? "Not Yet"
            : status;

    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? iconColor.withOpacity(0.14)
                : badgeBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.65)
                : const Color(0xFF8B9098),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayTime,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF202228),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? badgeBg.withOpacity(0.14)
                : badgeBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            displayStatus,
            style: TextStyle(
              color: badgeText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkAttendanceButton(
    BuildContext context, {
    String biometricType = "fingerprint",
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isFace = biometricType.toLowerCase() == "face";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          try {
            await Get.to(
              () => AttendancePage(username: controller.username.value),
            );
          } catch (_) {
            AppAlert.toast(
              title: "Navigation failed",
              message: "Couldn’t open attendance page.",
            );
          }
        },
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isDark ? const Color(0xFF101826) : const Color(0xFFF7F9FC),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFE1E7F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 38 : 48,
                height: compact ? 38 : 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFace
                      ? Icons.face_retouching_natural_rounded
                      : Icons.fingerprint_rounded,
                  color: AppColors.primary2,
                  size: compact ? 18 : 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: compact
                    ? Text(
                        "Mark Attendance",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color:
                              isDark ? Colors.white : const Color(0xFF202228),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFace ? "Face ID Attendance" : "Mark Attendance",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF202228),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFace
                                ? "Check in or check out using face recognition"
                                : "Check in or check out instantly",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white.withOpacity(0.58)
                                  : const Color(0xFF8A8F98),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: compact ? 13 : 15,
                color: isDark
                    ? Colors.white.withOpacity(0.45)
                    : const Color(0xFF9AA0A8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamPresence(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final teamList = controller.teamPresence;

      if (teamList.isEmpty) {
        return _emptyState(context, "No team presence data found.");
      }

      int presentCount = 0;
      int leaveCount = 0;
      int absentCount = 0;
      int lateCount = 0;

      final List<dynamic> presentMembers = [];

      for (final raw in teamList) {
        if (raw is! Map) continue;

        final emp = Map<String, dynamic>.from(raw);
        final presenceStatus = _resolveTeamPresenceStatus(emp);

        switch (presenceStatus) {
          case "leave":
            leaveCount++;
            break;

          case "late":
            // Late employees are still present.
            lateCount++;
            presentCount++;
            presentMembers.add(emp);
            break;

          case "present":
            presentCount++;
            presentMembers.add(emp);
            break;

          default:
            absentCount++;
            break;
        }
      }

      final totalCount = teamList.length;

      return _teamPresenceSummaryCard(
        context,
        teamList: teamList,
        presentMembers: presentMembers,
        totalCount: totalCount,
        presentCount: presentCount,
        leaveCount: leaveCount,
        absentCount: absentCount,
        lateCount: lateCount,
        isDark: isDark,
      );
    });
  }

  /// Returns one primary state only:
  /// leave -> late -> present -> absent.
  ///
  /// Late is treated as a present employee for the Present total,
  /// but is also shown separately as useful attendance information.
  String _resolveTeamPresenceStatus(Map<String, dynamic> emp) {
    final status = (emp["status"] ?? "").toString().trim().toLowerCase();

    final approvalStatus =
        (emp["approved_status_1"] ?? "").toString().trim().toLowerCase();

    final isOnLeave = status == "leave" ||
        status == "on leave" ||
        status.contains("approved leave") ||
        (approvalStatus == "approved" &&
            _hasMeaningfulValue(emp["leave_type"]));

    if (isOnLeave) {
      return "leave";
    }

    final checkInType =
        (emp["checkIN_type"] ?? "").toString().trim().toLowerCase();

    final hasCheckIn = _hasAttendanceTime(emp["checkIN_time"]);
    final hasCheckOut = _hasAttendanceTime(emp["checkOUT_time"]);

    if (checkInType.contains("late") && (hasCheckIn || hasCheckOut)) {
      return "late";
    }

    if (hasCheckIn || hasCheckOut) {
      return "present";
    }

    return "absent";
  }

  bool _hasAttendanceTime(dynamic value) {
    if (value == null) return false;

    final text = value.toString().trim().toLowerCase();

    return text.isNotEmpty &&
        text != "--" &&
        text != "--:--" &&
        text != "null" &&
        text != "00:00:00";
  }

  bool _hasMeaningfulValue(dynamic value) {
    if (value == null) return false;

    final text = value.toString().trim().toLowerCase();

    return text.isNotEmpty && text != "null" && text != "--";
  }

  Widget _teamPresenceSummaryCard(
    BuildContext context, {
    required List<dynamic> teamList,
    required List<dynamic> presentMembers,
    required int totalCount,
    required int presentCount,
    required int leaveCount,
    required int absentCount,
    required int lateCount,
    required bool isDark,
  }) {
    final cardText = isDark ? Colors.white : const Color(0xFF111827);
    final subText =
        isDark ? Colors.white.withOpacity(0.62) : const Color(0xFF667085);

    final cardColor =
        isDark ? const Color(0xFF151821) : const Color(0xFFFFFFFF);

    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE9EDF2);

    final visibleMembers = presentMembers.take(4).toList();
    final extraPresentCount = presentMembers.length - visibleMembers.length;

    final double presenceRate =
        totalCount > 0 ? presentCount / totalCount : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Get.to(() => TeamPage()),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.045),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF202632)
                          : const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color:
                          isDark ? const Color(0xFF8AB4FF) : AppColors.primary2,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Team Presence",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.25,
                            color: cardText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "$totalCount team member${totalCount == 1 ? "" : "s"} today",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF4F6F8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: isDark
                          ? Colors.white.withOpacity(0.75)
                          : const Color(0xFF344054),
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Main presence number
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$presentCount",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 0.95,
                      letterSpacing: -1.2,
                      color: cardText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      "present now",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subText,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(
                        isDark ? 0.14 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "${(presenceRate * 100).round()}%",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// Presence progress
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: presenceRate.clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.07)
                      : const Color(0xFFF0F2F5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF22C55E),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              /// Clear status summary
              Row(
                children: [
                  Expanded(
                    child: _teamPresenceStat(
                      context,
                      label: "Present",
                      count: presentCount,
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _teamPresenceStat(
                      context,
                      label: "Absent",
                      count: absentCount,
                      icon: Icons.person_off_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _teamPresenceStat(
                      context,
                      label: "On Leave",
                      count: leaveCount,
                      icon: Icons.beach_access_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),

              /// Late is a subset of Present, so show it separately instead
              /// of making it look like another primary attendance state.
              if (lateCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(
                      isDark ? 0.12 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 17,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "$lateCount of the present employee${lateCount == 1 ? "" : "s"} arrived late",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFFBCB72)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              /// Present-member preview + action hint
              Row(
                children: [
                  Expanded(
                    child: visibleMembers.isEmpty
                        ? Text(
                            "No team members have marked attendance yet.",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subText,
                            ),
                          )
                        : SizedBox(
                            height: 36,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (int i = 0; i < visibleMembers.length; i++)
                                  Positioned(
                                    left: i * 23,
                                    child: _buildPresenceAvatar(
                                      name: (visibleMembers[i]
                                                  ["employee_fullname"] ??
                                              visibleMembers[i]
                                                  ["employee_name"] ??
                                              "--")
                                          .toString(),
                                      bgColor: cardColor,
                                      isDark: isDark,
                                    ),
                                  ),
                                if (extraPresentCount > 0)
                                  Positioned(
                                    left: visibleMembers.length * 23.0,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF242934)
                                            : const Color(0xFFF1F4F8),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "+$extraPresentCount",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: cardText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "View team",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? const Color(0xFF8AB4FF) : AppColors.primary2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color:
                        isDark ? const Color(0xFF8AB4FF) : AppColors.primary2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamPresenceStat(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.11 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.18 : 0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
              color: isDark ? Colors.white : const Color(0xFF202228),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withOpacity(0.60)
                  : const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceAvatar({
    required String name,
    required Color bgColor,
    required bool isDark,
  }) {
    final initials = _getInitials(name);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF2A303B) : const Color(0xFFF7F9FC),
        border: Border.all(
          color: bgColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF344054),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return "${parts[0][0]}${parts[1][0]}".toUpperCase();
  }

  Widget _buildUpcomingBirthdays(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final birthdaysError = controller.birthdaysError.value;

      if (birthdaysError.isNotEmpty) {
        return _errorState(context, birthdaysError);
      }

      final birthdays = controller.upcomingBirthdays;

      if (birthdays.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151821) : const Color(0xFFF9F9FA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : const Color(0xFFE9E9EE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.045),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "No birthdays coming up.",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withOpacity(0.55)
                    : const Color(0xFFA1A1AA),
              ),
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151821) : const Color(0xFFF9F9FA),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFE9E9EE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.045),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: birthdays.take(4).map((b) {
            final String name = (b['name'] ?? 'Unknown').toString();
            final String subtitle = (b['birthday'] ?? '').toString();
            final String label = (b['label'] ?? '').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [
                                Color(0xFF2A2F3A),
                                Color(0xFF1D212A),
                              ]
                            : const [
                                Color(0xFFFFD7E2),
                                Color(0xFFFFC2D4),
                              ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(name),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF5B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF2D2D32),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle.isEmpty ? "Upcoming birthday" : subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withOpacity(0.55)
                                : const Color(0xFF9A9AA3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF1E2C24)
                          : const Color(0xFFE7FAF1),
                    ),
                    child: Center(
                      child: Text(
                        label.isEmpty ? "+" : label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF34C38F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeMore,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: isDark ? Colors.white : const Color(0xFF202228),
          ),
        ),
        const Spacer(),
        if (onSeeMore != null)
          GestureDetector(
            onTap: onSeeMore,
            child: Text(
              "",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFF9BA1AA),
              ),
            ),
          ),
      ],
    );
  }

  Widget _teamPresenceCard(
    BuildContext context, {
    required String name,
    required String topLabel,
    required String status,
    required Color bgColor,
    required Color textColor,
    required Color subColor,
    required Color chipColor,
  }) {
    final initials = _getInitials(name);
    final firstInitial = initials.isNotEmpty ? initials[0] : "?";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Get.to(() => TeamPage()),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A1020),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.north_east_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 0.95,
                  letterSpacing: -1.0,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 66,
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.55),
                              border: Border.all(color: bgColor, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                firstInitial,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.40),
                              border: Border.all(color: bgColor, width: 2),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 36,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.25),
                              border: Border.all(color: bgColor, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: chipColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Live",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leaveWidget(
    BuildContext context,
    String type,
    String from,
    String to,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121C2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8ECF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.error.withOpacity(0.14)
                  : const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              color: theme.colorScheme.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You are on $type",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "From $from to $to",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121C2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8ECF3),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _loadingState(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121C2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8ECF3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(
          theme.brightness == Brightness.dark ? 0.16 : 0.08,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _refreshAll(context),
            child: Text(
              "Retry",
              style: TextStyle(
                color: AppColors.primary2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.14) : bg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: isDark ? color.withOpacity(0.95) : color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: isDark ? Colors.white : const Color(0xFF23262F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/modules/MASTER/start_page/start_page.dart

import 'dart:convert';

import 'package:corehris/modules/HRMS/lock_screen/screens/login_page.dart';

import 'package:corehris/modules/HRMS/main_screens/subpages/security/pages/security_page.dart';

import 'package:corehris/modules/MASTER/start_page/start_con.dart';

import 'package:corehris/theme/theme.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final LandingController controller;

  // Kept for internal compatibility, although search/filter UI is removed.
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedFilter = 'All';
  final List<String> _filters = const ['All'];

  static const _quickAccessKey = 'talexa_quick_access_titles_v1';
  List<String> _quickTitles = [];
  bool _quickLoaded = false;

  Future<void> _loadQuickAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_quickAccessKey) ?? <String>[];
      if (mounted)
        setState(() {
          _quickTitles = stored;
          _quickLoaded = true;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _quickLoaded = true;
        });
    }
  }

  Future<void> _saveQuickAccess(List<String> titles) async {
    setState(() => _quickTitles = titles);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_quickAccessKey, titles);
    } catch (e) {
      debugPrint('Unable to save quick access: $e');
    }
  }

  // ============================================================

  // INIT

  // ============================================================

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<LandingController>()
        ? Get.find<LandingController>()
        : Get.put(LandingController());

    _loadQuickAccess();
  }

  @override
  void dispose() {
    _searchController.dispose();

    _searchFocusNode.dispose();

    super.dispose();
  }

  // ============================================================

  // PAGE

  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFF8F9FB);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              // ==================================================

              // MAIN PAGE

              // ==================================================

              Column(
                children: [
                  // ================================================

                  // TOP USER HEADER

                  // ================================================

                  _buildTopHeader(
                    isDark: isDark,
                  ),

                  // ================================================

                  // PAGE CONTENT

                  // ================================================

                  Expanded(
                    child: Obx(
                      () {
                        final services = controller.filteredServices;

                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildQuickAccess(services, isDark),
                            ),

                            // =======================================
                            // SYSTEM TITLE

                            // =======================================

                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                15,
                                16,
                                11,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _buildSystemsHeader(
                                  isDark: isDark,
                                  count: services.length,
                                ),
                              ),
                            ),

                            // =======================================

                            // EMPTY / SYSTEM GRID

                            // =======================================

                            if (services.isEmpty)
                              SliverToBoxAdapter(
                                child: _buildEmptyState(
                                  isDark: isDark,
                                ),
                              )
                            else
                              _buildSystemGrid(
                                services: services,
                                isDark: isDark,
                              ),

                            // =======================================

                            // SMALL SAFE BOTTOM SPACE

                            // =======================================

                            const SliverToBoxAdapter(
                              child: SizedBox(
                                height: 24,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              // ==================================================

              // LOADING OVERLAY

              // ==================================================

              Obx(
                () {
                  if (!controller.isLoading.value) {
                    return const SizedBox.shrink();
                  }

                  return Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.18),
                      alignment: Alignment.center,
                      child: Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1B2230) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================

  // TOP HEADER

  // ============================================================

  Widget _buildTopHeader({
    required bool isDark,
  }) {
    final Color titleColor = isDark ? Colors.white : const Color(0xFF161B22);

    final Color secondaryColor =
        isDark ? Colors.white60 : const Color(0xFF667085);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        13,
        12,
        7,
      ),
      child: Row(
        children: [
          // ======================================================

          // PROFILE

          // ======================================================

          _buildProfileAvatar(),

          const SizedBox(width: 11),

          // ======================================================

          // USER DETAILS

          // ======================================================

          Expanded(
            child: Obx(
              () {
                final String employeeName =
                    controller.employeeName.value.trim();

                final String organization =
                    controller.organizationName.value.trim();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName.isEmpty ? 'Hi!' : 'Hi, $employeeName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 12,
                          color: secondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            organization.isEmpty
                                ? 'Your Organization'
                                : organization,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================

          // SECURITY

          // ======================================================

          _RoundHeaderButton(
            icon: Icons.shield_outlined,
            isDark: isDark,
            tooltip: 'Security',
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();

              Get.to(
                () => SecurityPage(),
              );
            },
          ),

          const SizedBox(width: 7),

          // ======================================================

          // LOGOUT

          // ======================================================

          _RoundHeaderButton(
            icon: Icons.logout_rounded,
            isDark: isDark,
            tooltip: 'Logout',
            onTap: () {
              Get.offAll(
                () => const LoginScreen(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================

  // PROFILE IMAGE

  // ============================================================

  Widget _buildProfileAvatar() {
    return Obx(
      () {
        final dynamic value = controller.profileImageUrl.value;

        final String imageValue = value?.toString().trim() ?? '';

        ImageProvider? imageProvider;

        if (imageValue.isNotEmpty) {
          try {
            if (imageValue.startsWith('http://') ||
                imageValue.startsWith(
                  'https://',
                )) {
              imageProvider = NetworkImage(imageValue);
            } else {
              final String encoded = imageValue.contains(',')
                  ? imageValue.split(',').last
                  : imageValue;

              imageProvider = MemoryImage(
                base64Decode(encoded),
              );
            }
          } catch (_) {
            imageProvider = null;
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Get.to(
              () => SecurityPage(),
            );
          },
          child: Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary2.withOpacity(0.15),
              ),
            ),
            child: CircleAvatar(
              backgroundColor: AppColors.primary2.withOpacity(0.08),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary2,
                      size: 23,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  // ============================================================

  // SYSTEM SECTION HEADER

  // ============================================================

  String _quickTitle(dynamic service) =>
      service['title']?.toString().trim() ?? 'System';

  void _openQuickService(dynamic service) {
    final title = _quickTitle(service);
    if (service['isAvailable'] == true) {
      controller.onSelectService(service);
    } else {
      _showUnavailable(title);
    }
  }

  void _showQuickAccessEditor(List<dynamic> services, bool isDark) {
    final eligible = services.where((e) => e['isAvailable'] == true).toList();
    final chosen = _quickTitles.toSet();
    Get.bottomSheet(
      StatefulBuilder(builder: (context, modalSetState) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .76,
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF192337) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                    child: Text('Customize Quick Access',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF10223B)))),
                IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 4),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose up to 6 shortcuts for your workspace.',
                      style:
                          TextStyle(color: Color(0xFF718096), fontSize: 12))),
              const SizedBox(height: 12),
              Flexible(
                  child: ListView.builder(
                shrinkWrap: true,
                itemCount: eligible.length,
                itemBuilder: (context, index) {
                  final service = eligible[index];
                  final title = _quickTitle(service);
                  final checked = chosen.contains(title);
                  return CheckboxListTile(
                    value: checked,
                    activeColor: const Color(0xFF1769E8),
                    title: Text(title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    secondary: Icon(_fallbackIcon(title),
                        color: const Color(0xFF1769E8)),
                    onChanged: (value) {
                      modalSetState(() {
                        if (value == true) {
                          if (chosen.length < 6) chosen.add(title);
                        } else {
                          chosen.remove(title);
                        }
                      });
                    },
                  );
                },
              )),
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1769E8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: () {
                      _saveQuickAccess(chosen.toList());
                      Get.back();
                    },
                    child: const Text('Save Shortcuts',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  )),
            ]),
          ),
        );
      }),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildQuickAccess(List<dynamic> services, bool isDark) {
    final eligible = services.where((e) => e['isAvailable'] == true).toList();
    if (!_quickLoaded || eligible.isEmpty) return const SizedBox.shrink();
    final items = _quickTitles.isEmpty
        ? eligible.take(4).toList()
        : eligible.where((s) => _quickTitles.contains(_quickTitle(s))).toList();
    final shortcuts = items.isEmpty ? eligible.take(4).toList() : items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Quick Access',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.white : const Color(0xFF14263F))),
                const SizedBox(height: 2),
                const Text('Open your everyday tools in one tap',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8290A4))),
              ])),
          TextButton.icon(
            onPressed: () => _showQuickAccessEditor(services, isDark),
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Edit'),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF1769E8)),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shortcuts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final service = shortcuts[index];
              final title = _quickTitle(service);
              final palette = _cardPalette(title);
              return SizedBox(
                  width: 124,
                  child: Material(
                    color: isDark ? const Color(0xFF1B273B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openQuickService(service),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE7EDF5)),
                            borderRadius: BorderRadius.circular(18)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      color: palette.headerColor,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(_fallbackIcon(title),
                                      size: 19, color: palette.darkText)),
                              const Spacer(),
                              Text(title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF192B43))),
                            ]),
                      ),
                    ),
                  ));
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildSystemsHeader({
    required bool isDark,
    required int count,
  }) {
    final Color titleColor = isDark ? Colors.white : const Color(0xFF20242C);
    final Color secondaryColor =
        isDark ? Colors.white54 : const Color(0xFF8A94A3);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Digital Workspace',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a system to continue.',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171D27) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE7EBF1),
              ),
            ),
            child: Text(
              '$count ${count == 1 ? 'system' : 'systems'}',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF344054),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stacked, collapsing cards: each card stays visible as a compact header
  // when users scroll past it. No additional dependencies are required.
  Widget _buildSystemGrid({
    required List<dynamic> services,
    required bool isDark,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverMainAxisGroup(
        slivers: [
          for (int index = 0; index < services.length; index++)
            SliverPersistentHeader(
              pinned: true,
              delegate: _CollapsingSystemCardDelegate(
                title: services[index]['title']?.toString() ?? 'System',
                subtitle: _serviceSubtitle(services[index]),
                available: services[index]['isAvailable'] == true,
                compactColor: _cardPalette(
                        services[index]['title']?.toString() ?? 'System')
                    .headerColor,
                onOpen: () {
                  final service = services[index];
                  if (service['isAvailable'] == true) {
                    controller.onSelectService(service);
                  } else {
                    _showUnavailable(service['title']?.toString() ?? 'System');
                  }
                },
                fullCard: _buildSystemCard(
                  service: services[index],
                  index: index,
                  isDark: isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _systemArtwork(String title) {
    final name = title.toLowerCase();
    if (name.contains('petty cash')) {
      return 'lib/images/system_cards/petty_cash.jpg';
    }
    if (name.contains('finance') ||
        name.contains('account') ||
        name.contains('ledger') ||
        name.contains('expense') ||
        name.contains('budget')) {
      return 'lib/images/system_cards/finance.jpg';
    }
    if (name.contains('vehicle') ||
        name.contains('vehical') ||
        name.contains('fleet') ||
        name.contains('tracking') ||
        name.contains('track') ||
        name.contains('gps') ||
        name.contains('transport')) {
      return 'lib/images/system_cards/vehicle_tracking.jpg';
    }
    if (name.contains('attendance') || name.contains('time')) {
      return 'lib/images/system_cards/attendance.jpg';
    }
    if (name.contains('payroll') || name.contains('salary')) {
      return 'lib/images/system_cards/payroll.jpg';
    }
    if (name.contains('leave') || name.contains('holiday')) {
      return 'lib/images/system_cards/leave.jpg';
    }
    if (name.contains('report') || name.contains('analytic')) {
      return 'lib/images/system_cards/reports.jpg';
    }
    if (name.contains('hrms') ||
        name.contains('employee') ||
        name.contains('human')) {
      return 'lib/images/system_cards/hrms.jpg';
    }
    return 'lib/images/system_cards/other.jpg';
  }

  // ============================================================
  // IMMERSIVE SERVICE CARD — DESIGN INSPIRED BY REFERENCE
  // ============================================================

  String _cardHeadline(String title) {
    final value = title.toLowerCase();
    if (value.contains('finance')) return 'Make Every Number Clear.';
    if (value.contains('petty cash') || value.contains('cash')) {
      return 'Track Every Spend Smart.';
    }
    if (value.contains('vehicle') ||
        value.contains('vehical') ||
        value.contains('tracking') ||
        value.contains('fleet')) {
      return 'Watch Every Route Live.';
    }
    if (value.contains('attendance') || value.contains('time')) {
      return 'Make Every Punch Count.';
    }
    if (value.contains('payroll') || value.contains('salary')) {
      return 'Pay Every Team Right.';
    }
    if (value.contains('leave') || value.contains('holiday')) {
      return 'Plan Every Day Off.';
    }
    if (value.contains('report') || value.contains('analytic')) {
      return 'Turn Every Insight Clear.';
    }
    if (value.contains('hrms') ||
        value.contains('employee') ||
        value.contains('human')) {
      return 'Power Every Workday Better.';
    }
    return 'Access Everything Faster.';
  }

  _SystemCardPalette _cardPalette(String title) {
    final value = title.toLowerCase();
    if (value.contains('finance')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFFD9F75B),
        headerAccent: Color(0xFFBDE13E),
        darkText: Color(0xFF101828),
      );
    }
    if (value.contains('petty cash') || value.contains('cash')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFFFFC98B),
        headerAccent: Color(0xFFF4A95F),
        darkText: Color(0xFF1D2939),
      );
    }
    if (value.contains('vehicle') ||
        value.contains('vehical') ||
        value.contains('tracking') ||
        value.contains('fleet')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFFC7B7FF),
        headerAccent: Color(0xFFA58DFF),
        darkText: Color(0xFF111827),
      );
    }
    if (value.contains('attendance') || value.contains('time')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFF7AE7DA),
        headerAccent: Color(0xFF42D1C0),
        darkText: Color(0xFF0F172A),
      );
    }
    if (value.contains('payroll') || value.contains('salary')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFFFFA6BD),
        headerAccent: Color(0xFFFF8AAA),
        darkText: Color(0xFF111827),
      );
    }
    if (value.contains('leave') || value.contains('holiday')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFF8ED8FF),
        headerAccent: Color(0xFF5CC2FF),
        darkText: Color(0xFF0F172A),
      );
    }
    if (value.contains('report') || value.contains('analytic')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFFFFE28A),
        headerAccent: Color(0xFFFFD255),
        darkText: Color(0xFF101828),
      );
    }
    if (value.contains('hrms') ||
        value.contains('employee') ||
        value.contains('human')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFF9CC9FF),
        headerAccent: Color(0xFF72AEFF),
        darkText: Color(0xFF0F172A),
      );
    }
    return const _SystemCardPalette(
      headerColor: Color(0xFFD8DCEF),
      headerAccent: Color(0xFFBBC4E3),
      darkText: Color(0xFF111827),
    );
  }

  Widget _buildSystemCard({
    required dynamic service,
    required int index,
    required bool isDark,
  }) {
    final String title = service['title']?.toString().trim() ?? 'System';
    final String subtitle = _serviceSubtitle(service);
    final bool available = service['isAvailable'] == true;
    final dynamic rawIcon = service['icon'];
    final IconData icon = rawIcon is IconData ? rawIcon : _fallbackIcon(title);
    final palette = _cardPalette(title);
    final String headline = _cardHeadline(title);

    void openService() {
      FocusManager.instance.primaryFocus?.unfocus();
      if (available) {
        controller.onSelectService(service);
      } else {
        _showUnavailable(title);
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final bool compact = constraints.maxWidth < 270;
      final double inset = compact ? 16 : 20;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: openService,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? .14 : .07),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(children: [
                // Short colored banner, separate for each system.
                Expanded(
                  flex: 43,
                  child: Container(
                    width: double.infinity,
                    color: palette.headerColor,
                    child: Stack(children: [
                      Positioned(
                        top: -35,
                        right: -30,
                        child: Container(
                          width: 125,
                          height: 125,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(.16),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 17,
                        top: 17,
                        child: Icon(icon,
                            size: compact ? 26 : 30,
                            color: palette.darkText.withOpacity(.80)),
                      ),
                      Positioned(
                        left: inset,
                        right: 65,
                        bottom: 16,
                        child: Text(
                          headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.darkText,
                            fontSize: compact ? 19 : 22,
                            height: 1.06,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.6,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                Expanded(
                  flex: 57,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.fromLTRB(inset, 34, inset, 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF101828),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              )),
                              const SizedBox(width: 9),
                              SizedBox(
                                height: 33,
                                child: ElevatedButton(
                                  onPressed: openService,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF071746),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    available ? 'Open' : 'Locked',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                height: 1.3,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Row(children: [
                              Icon(
                                  available
                                      ? Icons.check_circle_outline
                                      : Icons.lock_outline,
                                  color: const Color(0xFF667085),
                                  size: 13),
                              const SizedBox(width: 5),
                              Text(
                                available ? 'Available' : 'Unavailable',
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    // White overlapping logo circle.
                    Positioned(
                      left: inset,
                      top: -27,
                      child: Container(
                        width: 55,
                        height: 55,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.10),
                              blurRadius: 13,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Image.asset('lib/images/talexa.png',
                            fit: BoxFit.contain),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCardMeta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF667085)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================

  // SERVICE DESCRIPTION

  // ============================================================

  String _serviceSubtitle(
    dynamic service,
  ) {
    final String description = service['description']?.toString().trim() ?? '';

    if (description.isNotEmpty) {
      return description;
    }

    final String title = service['title']?.toString().toLowerCase() ?? '';

    if (title.contains('hr') || title.contains('employee')) {
      return 'Employee Management';
    }

    if (title.contains('attendance')) {
      return 'Time & Attendance';
    }

    if (title.contains('petty cash')) {
      return 'Petty Cash Control';
    }

    if (title.contains('finance') ||
        title.contains('account') ||
        title.contains('ledger') ||
        title.contains('expense') ||
        title.contains('budget')) {
      return 'Finance Management';
    }

    if (title.contains('vehicle') ||
        title.contains('vehical') ||
        title.contains('tracking') ||
        title.contains('fleet') ||
        title.contains('gps') ||
        title.contains('transport')) {
      return 'Vehicle Tracking';
    }

    if (title.contains('payroll') || title.contains('salary')) {
      return 'Payroll Management';
    }

    if (title.contains('pms') || title.contains('performance')) {
      return 'Performance Management';
    }

    if (title.contains('leave')) {
      return 'Leave Management';
    }

    if (title.contains('report')) {
      return 'Reports & Analytics';
    }

    return 'Open System';
  }

  // ============================================================

  // FALLBACK ICON

  // ============================================================

  IconData _fallbackIcon(
    String title,
  ) {
    final String value = title.toLowerCase();

    if (value.contains('hr') || value.contains('employee')) {
      return Icons.groups_2_outlined;
    }

    if (value.contains('attendance') || value.contains('time')) {
      return Icons.schedule_rounded;
    }

    if (value.contains('petty cash')) {
      return Icons.payments_outlined;
    }

    if (value.contains('finance') ||
        value.contains('account') ||
        value.contains('ledger') ||
        value.contains('budget') ||
        value.contains('expense')) {
      return Icons.account_balance_outlined;
    }

    if (value.contains('vehicle') ||
        value.contains('vehical') ||
        value.contains('tracking') ||
        value.contains('fleet') ||
        value.contains('gps') ||
        value.contains('transport')) {
      return Icons.local_shipping_outlined;
    }

    if (value.contains('payroll') || value.contains('salary')) {
      return Icons.account_balance_wallet_outlined;
    }

    if (value.contains('leave')) {
      return Icons.calendar_month_outlined;
    }

    if (value.contains('performance') || value.contains('pms')) {
      return Icons.insights_outlined;
    }

    if (value.contains('report')) {
      return Icons.bar_chart_rounded;
    }

    if (value.contains('device')) {
      return Icons.devices_outlined;
    }

    if (value.contains('security')) {
      return Icons.shield_outlined;
    }

    return Icons.apps_rounded;
  }

  // ============================================================

  // EMPTY STATE

  // ============================================================

  Widget _buildEmptyState({
    required bool isDark,
  }) {
    const bool searching = false;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 45,
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary2.withOpacity(
                isDark ? 0.14 : 0.07,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching ? Icons.search_off_rounded : Icons.apps_rounded,
              color: AppColors.primary2,
              size: 28,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'No systems available',
            style: TextStyle(
              color: isDark
                  ? Colors.white
                  : const Color(
                      0xFF20242A,
                    ),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            searching
                ? 'Try searching with another system name.'
                : 'There are currently no systems available for your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? Colors.white38
                  : const Color(
                      0xFF8A94A3,
                    ),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          if (searching) ...[
            const SizedBox(height: 13),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();

                controller.onSearch('');

                setState(() {});
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: const Text(
                'Clear search',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================

  // UNAVAILABLE SYSTEM

  // ============================================================

  void _showUnavailable(
    String title,
  ) {
    Get.snackbar(
      'System unavailable',
      '$title is currently unavailable for your account.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
      colorText: Colors.white,
      backgroundColor: const Color(0xFF252B35),
      icon: const Icon(
        Icons.info_outline_rounded,
        color: Colors.white,
      ),
    );
  }

  // ============================================================

  // LOGOUT SHEET

  // ============================================================

  void _showLogoutSheet({
    required bool isDark,
  }) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171D27) : Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================

              // HANDLE

              // ==================================================

              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white24
                      : const Color(
                          0xFFD8DCE2,
                        ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================

              // ICON

              // ==================================================

              Container(
                width: 57,
                height: 57,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 26,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Sign out?',
                style: TextStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(
                          0xFF20242A,
                        ),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Are you sure you want to sign out of Talexa HRMS?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.white54
                      : const Color(
                          0xFF7A8494,
                        ),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  // ==============================================

                  // CANCEL

                  // ==============================================

                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : const Color(
                                    0xFFE0E3E8,
                                  ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(
                                    0xFF344054,
                                  ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ==============================================

                  // SIGN OUT

                  // ==============================================

                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();

                          controller.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Sign out',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _SystemCardPalette {
  final Color headerColor;
  final Color headerAccent;
  final Color darkText;

  const _SystemCardPalette({
    required this.headerColor,
    required this.headerAccent,
    required this.darkText,
  });
}

// ============================================================================

// WORKSPACE METRIC

// ============================================================================

class _WorkspaceMetric extends StatelessWidget {
  final String value;

  final String label;

  final bool showStatus;

  const _WorkspaceMetric({
    required this.value,
    required this.label,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showStatus) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF8DFF8B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.67),
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================

// ROUND HEADER BUTTON

// ============================================================================

class _RoundHeaderButton extends StatelessWidget {
  final IconData icon;

  final bool isDark;

  final String tooltip;

  final VoidCallback onTap;

  const _RoundHeaderButton({
    required this.icon,
    required this.isDark,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171D27) : const Color(0xFFF1F3F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark
                  ? Colors.white70
                  : const Color(
                      0xFF303640,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Each header collapses from a full card to a readable 78dp shortcut.
// The next card scrolls over it; tap a compact card to open its system.
class _CollapsingSystemCardDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String subtitle;
  final bool available;
  final Color compactColor;
  final VoidCallback onOpen;
  final Widget fullCard;

  const _CollapsingSystemCardDelegate({
    required this.title,
    required this.subtitle,
    required this.available,
    required this.compactColor,
    required this.onOpen,
    required this.fullCard,
  });

  @override
  double get minExtent => 78;

  @override
  double get maxExtent => 282;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23 - 8 * t),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Keep full card at its intended size and clip it as it collapses.
            if (t < 0.98)
              Opacity(
                opacity: (1.0 - (t * 1.25)).clamp(0.0, 1.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(height: maxExtent - 7, child: fullCard),
                ),
              ),
            if (t > 0.48)
              Opacity(
                opacity: ((t - 0.48) / 0.52).clamp(0.0, 1.0),
                child: Material(
                  color: compactColor,
                  child: InkWell(
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(7),
                            child: Image.asset('lib/images/talexa.png',
                                fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF13233D))),
                                Text(available ? 'Tap to open' : 'Unavailable',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF344054))),
                              ],
                            ),
                          ),
                          Icon(
                              available
                                  ? Icons.arrow_outward_rounded
                                  : Icons.lock_outline_rounded,
                              color: const Color(0xFF13233D)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingSystemCardDelegate oldDelegate) =>
      oldDelegate.title != title ||
      oldDelegate.subtitle != subtitle ||
      oldDelegate.available != available ||
      oldDelegate.compactColor != compactColor ||
      oldDelegate.fullCard != fullCard;
}

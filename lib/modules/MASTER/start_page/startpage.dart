// lib/modules/MASTER/start_page/start_page.dart
import 'dart:convert';

import 'package:corehris/modules/HRMS/main_screens/subpages/security/pages/security_page.dart';

import 'package:corehris/modules/MASTER/start_page/start_con.dart';

import 'package:corehris/theme/theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const Color _blue = Color(0xFF1769E8);
  static const Color _navy = Color(0xFF182237);
  static const Color _muted = Color(0xFF7E8CA2);
  static const Color _pale = Color(0xFFE8F2FF);
  static const Color _border = Color(0xFFDDE8F8);

  late final LandingController controller;

  // Open the only accessible module once per Start Page instance.
  // The guard prevents a navigation loop when returning from that module.
  bool _singleModuleNavigationScheduled = false;
  bool _singleModuleAutoOpened = false;

  void _openSingleModuleIfNeeded(List<dynamic> services, bool loading) {
    if (_singleModuleAutoOpened ||
        _singleModuleNavigationScheduled ||
        loading ||
        services.length != 1 ||
        services.first['isAvailable'] != true) {
      return;
    }

    _singleModuleNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _singleModuleNavigationScheduled = false;
      if (!mounted || _singleModuleAutoOpened || controller.isLoading.value) {
        return;
      }

      // Recheck because permissions/modules can change during the frame.
      final latest = controller.filteredServices;
      if (latest.length != 1 || latest.first['isAvailable'] != true) {
        return;
      }

      _singleModuleAutoOpened = true;
      controller.onSelectService(latest.first);
    });
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101623) : Colors.white;
    final surface = isDark ? const Color(0xFF1B2638) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: surface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: surface,
      ),
      // Typography inherits the global theme (SF Pro on iOS).
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme,
          primaryTextTheme: Theme.of(context).primaryTextTheme,
          primaryColor: _blue,
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _blue),
          scaffoldBackgroundColor: bg,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            backgroundColor: bg,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildTopHeader(isDark: isDark),
                      Expanded(
                        child: Obx(() {
                          final services = controller.filteredServices;
                          final isLoading = controller.isLoading.value;
                          _openSingleModuleIfNeeded(services, isLoading);
                          return CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            slivers: [
                              SliverToBoxAdapter(
                                child: _buildQuickAccess(services, isDark),
                              ),
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 28, 18, 17),
                                sliver: SliverToBoxAdapter(
                                  child: _buildSystemsHeader(
                                    isDark: isDark,
                                    count: services.length,
                                  ),
                                ),
                              ),
                              if (services.isEmpty)
                                SliverToBoxAdapter(
                                  child: _buildEmptyState(isDark: isDark),
                                )
                              else
                                _buildSystemGrid(
                                  services: services,
                                  isDark: isDark,
                                ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 28),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                  Obx(() {
                    if (!controller.isLoading.value) {
                      return const SizedBox.shrink();
                    }
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(.17),
                        alignment: Alignment.center,
                        child: Container(
                          height: 62,
                          width: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _blue,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================

  // TOP HEADER

  // ============================================================

  Widget _buildTopHeader({required bool isDark}) {
    final titleColor = isDark ? Colors.white : _navy;
    final secondaryColor = isDark ? Colors.white60 : _muted;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF17253B), Color(0xFF101623)])
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE5F1FF), Color(0xFFF7FAFF)]),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 18, 20),
      child: Row(
        children: [
          _buildProfileAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final name = controller.employeeName.value.trim();
              final organization = controller.organizationName.value.trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isEmpty ? 'Welcome back.' : 'Hi, $name!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.5,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    organization.isEmpty ? 'Your workspace' : organization,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryColor,
                    ),
                  ),
                ],
              );
            }),
          ),
          _RoundHeaderButton(
            icon: Icons.shield_outlined,
            isDark: isDark,
            tooltip: 'Security',
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Get.to(() => SecurityPage());
            },
          ),
          const SizedBox(width: 9),
          _RoundHeaderButton(
            icon: Icons.logout_rounded,
            isDark: isDark,
            tooltip: 'Sign out',
            onTap: () => _showLogoutSheet(isDark: isDark),
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
                        backgroundColor: _blue,
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
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 4),
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
          height: 106,
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
                  width: 132,
                  child: Material(
                    color: isDark ? const Color(0xFF1B273B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _openQuickService(service),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: isDark ? Colors.white12 : _border),
                            borderRadius: BorderRadius.circular(22)),
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
                                      color: isDark ? Colors.white : _navy)),
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
    final Color titleColor = isDark ? Colors.white : _navy;
    final Color secondaryColor = isDark ? Colors.white54 : _muted;

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
                  'Explore your workspace',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here are some things you can do',
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

  // Responsive 2-column dashboard cards, based on the supplied reference.
  Widget _buildSystemGrid({
    required List<dynamic> services,
    required bool isDark,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = width < 320 ? 1 : 2;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: columns == 1 ? 172 : (width < 375 ? 184 : 202),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSystemCard(
                service: services[index],
                index: index,
                isDark: isDark,
              ),
              childCount: services.length,
            ),
          );
        },
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
    if (value.contains('finance') || value.contains('cash')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFFDCEBFF),
        headerAccent: Color(0xFFC1DDFF),
        darkText: _navy,
      );
    }
    if (value.contains('vehicle') || value.contains('tracking')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFFE1F0FF),
        headerAccent: Color(0xFFCCE3FF),
        darkText: _navy,
      );
    }
    if (value.contains('hrms') || value.contains('employee')) {
      return const _SystemCardPalette(
        headerColor: Color(0xFFD4E7FF),
        headerAccent: Color(0xFFB8D8FF),
        darkText: _navy,
      );
    }
    return const _SystemCardPalette(
      headerColor: Color(0xFFE8F2FF),
      headerAccent: Color(0xFFD6E8FF),
      darkText: _navy,
    );
  }

  // Minimal two-column service card: simple icon, strong title, short description.
  Widget _buildSystemCard({
    required dynamic service,
    required int index,
    required bool isDark,
  }) {
    final title = service['title']?.toString().trim() ?? 'System';
    final subtitle = _serviceSubtitle(service);
    final available = service['isAvailable'] == true;
    final rawIcon = service['icon'];
    final icon = rawIcon is IconData ? rawIcon : _fallbackIcon(title);

    final lightPastels = <Color>[
      const Color(0xFFEAF1FF),
      const Color(0xFFE3F1F7),
      const Color(0xFFF0F4FF),
      const Color(0xFFE9F5F3),
    ];
    final darkPastels = <Color>[
      const Color(0xFF1B304D),
      const Color(0xFF193B4B),
      const Color(0xFF252C4A),
      const Color(0xFF1D3D3D),
    ];
    final cardColor = (isDark ? darkPastels : lightPastels)[index % 4];
    final primaryText = isDark ? Colors.white : _navy;
    final secondaryText = isDark ? const Color(0xFFB7C5D8) : _muted;

    void open() {
      FocusManager.instance.primaryFocus?.unfocus();
      if (available) {
        controller.onSelectService(service);
      } else {
        _showUnavailable(title);
      }
    }

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(23),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(23),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 17, 14, 14),
          child: LayoutBuilder(builder: (context, constraints) {
            final tight = constraints.maxWidth < 155;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon,
                    size: tight ? 26 : 31,
                    color: isDark ? const Color(0xFFA7CDFF) : _blue),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: tight ? 13 : 14.5,
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  available ? subtitle : 'Currently unavailable',
                  maxLines: tight ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: tight ? 10 : 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    available
                        ? Icons.arrow_outward_rounded
                        : Icons.lock_outline_rounded,
                    color: isDark ? Colors.white60 : _blue,
                    size: 17,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCardMeta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _muted),
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
              color: isDark ? const Color(0xFF171D27) : const Color(0xFFE8F2FF),
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

// lib/modules/HRMS/main_screens/subpages/viewprofile.dart
// Minimalist Talexa profile screen, styled to match the redesigned drawer.
import 'dart:convert';

import 'package:corehris/model/employee.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/controllers/view_profile_con.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ViewProfile extends StatefulWidget {
  const ViewProfile({super.key});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _blue = Color(0xFF1769E8);
  static const Color _ink = Color(0xFF182237);
  static const Color _muted = Color(0xFF7E8CA2);
  static const Color _line = Color(0xFFE8EDF5);

  late final ViewProfileController controller;
  late final TabController _tabController;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.isRegistered<ViewProfileController>()
        ? Get.find<ViewProfileController>()
        : Get.put(ViewProfileController());
    _tabController = TabController(length: 2, vsync: this);
    controller.fetchEmployeeDetails();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.fetchEmployeeDetails();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    // The GetX controller is owned by GetX dependency management.
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploading) return;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      setState(() => _uploading = true);
      await controller.updateProfilePicture(picked.path);
    } catch (e) {
      if (mounted) {
        Get.snackbar('Unable to update photo', 'Please try again.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  ImageProvider? _getImage(String? raw) {
    final image = raw?.trim() ?? '';
    if (image.isEmpty) return null;
    try {
      if (image.startsWith('https://') || image.startsWith('http://')) {
        return NetworkImage(image);
      }
      final payload = image.contains(',') ? image.split(',').last : image;
      return MemoryImage(base64Decode(payload));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
    final surface = dark ? const Color(0xFF1B2638) : Colors.white;
    final titleColor = dark ? Colors.white : _ink;
    final secondary = dark ? const Color(0xFF9EAFC4) : _muted;
    final separator = dark ? Colors.white12 : _line;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: WillPopScope(
        onWillPop: () async {
          // Retain the original Profile screen's back-navigation behavior.
          Get.offAll(() => DashboardScreen());
          return false;
        },
        child: Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            centerTitle: true,
            title: Text('Profile',
                style: TextStyle(
                    color: titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            leading: IconButton(
              tooltip: 'Back',
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 19, color: titleColor),
              onPressed: () => Get.offAll(() => DashboardScreen()),
            ),
          ),
          body: Obx(() {
            final employee = controller.employee.value;
            if (controller.isLoading.value && employee == null) {
              return const Center(
                  child: CircularProgressIndicator(color: _blue));
            }
            if (employee == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off_outlined, size: 40, color: secondary),
                    const SizedBox(height: 12),
                    Text('No employee data available',
                        style: TextStyle(color: secondary)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.fetchEmployeeDetails,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: _blue,
                    onRefresh: controller.fetchEmployeeDetails,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
                      children: [
                        _profileCard(
                            employee, surface, titleColor, secondary, dark),
                        const SizedBox(height: 23),
                        _sectionTitle('INFORMATION', secondary),
                        const SizedBox(height: 10),
                        _tabSelector(surface, dark),
                        const SizedBox(height: 15),
                        // Use an AnimatedBuilder so changing tabs rebuilds the
                        // visible grouped details without nested scrolling.
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (_, __) => _tabController.index == 0
                              ? _personalSection(employee, surface, titleColor,
                                  secondary, separator)
                              : _employmentSection(employee, surface,
                                  titleColor, secondary, separator),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text('Talexa HRMS  •  Employee profile',
                              style: TextStyle(fontSize: 11, color: secondary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _profileCard(
      Employee employee, Color surface, Color ink, Color muted, bool dark) {
    final image = _getImage(controller.profileImageUrl.value);
    final designation = employee.employmentHistory.isNotEmpty
        ? employee.employmentHistory.last.designationName
        : '';
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: dark
                        ? const Color(0xFF294467)
                        : const Color(0xFFE8F2FF),
                    backgroundImage: image,
                    child: image == null
                        ? const Icon(Icons.person_outline_rounded,
                            size: 30, color: _blue)
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -3,
                    child: Material(
                      color: _blue,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _uploading ? null : _pickAndUploadImage,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: _uploading
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_outlined,
                                  color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.employeeCallingName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 4),
                    Text(employee.employeeNo,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _blue)),
                    if (designation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(designation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (employee.employeeEmail.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: dark ? Colors.white12 : _line),
            const SizedBox(height: 13),
            Row(
              children: [
                Icon(Icons.mail_outline_rounded, size: 16, color: muted),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(employee.employeeEmail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, Color muted) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: muted)),
      );

  Widget _tabSelector(Color surface, bool dark) {
    return Container(
      decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _tabButton('Personal', Icons.person_outline_rounded, 0, dark),
          _tabButton('Employment', Icons.work_outline_rounded, 1, dark),
        ],
      ),
    );
  }

  Widget _tabButton(String label, IconData icon, int index, bool dark) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          final selected = _tabController.index == index;
          return Material(
            color: selected
                ? (dark ? const Color(0xFF28466B) : const Color(0xFFE8F2FF))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => setState(() => _tabController.animateTo(index)),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 17,
                        color: selected
                            ? (dark ? const Color(0xFF8CBDFF) : _blue)
                            : (dark ? Colors.white54 : _muted)),
                    const SizedBox(width: 7),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? (dark ? Colors.white : _blue)
                                : (dark ? Colors.white60 : _muted))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _personalSection(Employee employee, Color surface, Color ink,
      Color muted, Color separator) {
    final rows = <_DetailRow>[
      _DetailRow(
          Icons.phone_outlined, 'Contact Number', employee.employeeContactNo),
      _DetailRow(Icons.email_outlined, 'Email', employee.employeeEmail),
      _DetailRow(Icons.cake_outlined, 'Date of Birth', employee.employeeDob),
      _DetailRow(Icons.home_outlined, 'Permanent Address',
          employee.employeePermanentAddress ?? ''),
      _DetailRow(Icons.location_on_outlined, 'Temporary Address',
          employee.employeeTemporaryAddress ?? ''),
      _DetailRow(
          Icons.flag_outlined, 'Nationality', employee.nationality ?? ''),
      _DetailRow(Icons.favorite_border_rounded, 'Marital Status',
          employee.employeeMaritalStatus ?? ''),
      _DetailRow(
          Icons.auto_awesome_outlined, 'Religion', employee.religion ?? ''),
    ];
    return _groupedRows(rows, surface, ink, muted, separator);
  }

  Widget _employmentSection(Employee employee, Color surface, Color ink,
      Color muted, Color separator) {
    final history = employee.employmentHistory;
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          Icon(Icons.work_history_outlined, size: 30, color: muted),
          const SizedBox(height: 10),
          Text('No employment history available',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13)),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = history.length - 1; i >= 0; i--) ...[
          if (i != history.length - 1) const SizedBox(height: 16),
          if (history.length > 1) ...[
            _sectionTitle(
                i == history.length - 1
                    ? 'CURRENT EMPLOYMENT'
                    : 'PREVIOUS EMPLOYMENT',
                muted),
            const SizedBox(height: 8),
          ],
          _employmentEntry(history[i], surface, ink, muted, separator),
        ],
      ],
    );
  }

  Widget _employmentEntry(EmploymentHistory history, Color surface, Color ink,
      Color muted, Color separator) {
    final rows = <_DetailRow>[
      _DetailRow(Icons.badge_outlined, 'Designation', history.designationName),
      _DetailRow(
          Icons.apartment_outlined, 'Department', history.departmentName),
      _DetailRow(Icons.work_outline_rounded, 'Employment Type',
          history.employmentTypeName),
      _DetailRow(Icons.event_outlined, 'Start Date', history.startDate),
      _DetailRow(Icons.event_available_outlined, 'End Date', history.endDate),
    ];
    return _groupedRows(rows, surface, ink, muted, separator);
  }

  Widget _groupedRows(List<_DetailRow> rows, Color surface, Color ink,
      Color muted, Color separator) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Divider(height: 1, color: separator),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 16, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(rows[i].icon,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : _ink,
                      size: 20),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].label,
                            style: TextStyle(
                                color: muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(_displayValue(rows[i].value),
                            style: TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _displayValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? 'Not provided' : text;
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final Object? value;
  const _DetailRow(this.icon, this.label, this.value);
}

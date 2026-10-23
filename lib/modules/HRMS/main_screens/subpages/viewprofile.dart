// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:corehris/model/employee.dart';
import 'package:corehris/modules/HRMS/main_screens/dashboard/dashboard.dart';
import 'package:corehris/modules/HRMS/main_screens/subpages/controllers/view_profile_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corehris/theme/theme.dart';
import 'package:image_picker/image_picker.dart';

class ViewProfile extends StatefulWidget {
  const ViewProfile({super.key});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ViewProfileController controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller = Get.put(ViewProfileController());
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
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await controller.updateProfilePicture(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final card = cs.surface;
    final onCard = cs.onSurface;
    final subText = cs.onSurface.withOpacity(0.70);
    final border = isDark ? Colors.white12 : Colors.black12;

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => DashboardScreen());
        return false;
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: card,
          foregroundColor: onCard,
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final employee = controller.employee.value;
          if (employee == null) {
            return Center(
              child: Text(
                'No employee data available',
                style: TextStyle(color: subText),
              ),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 16),

              // ================= HEADER CARD =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Obx(() {
                            final profileImage =
                                controller.profileImageUrl.value;
                            ImageProvider? imageProvider;

                            if (profileImage != null &&
                                profileImage.isNotEmpty) {
                              if (profileImage.startsWith("http")) {
                                imageProvider = NetworkImage(profileImage);
                              } else if (profileImage
                                  .startsWith("data:image")) {
                                imageProvider = MemoryImage(
                                  base64Decode(profileImage.split(',').last),
                                );
                              }
                            }

                            return CircleAvatar(
                              radius: 54,
                              backgroundColor:
                                  AppColors.primary2.withOpacity(0.12),
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? Icon(Icons.person,
                                      size: 44,
                                      color: cs.onSurface.withOpacity(0.55))
                                  : null,
                            );
                          }),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: card,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(isDark ? 0.35 : 0.18),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppColors.primary2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        employee.employeeCallingName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: onCard,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.employmentHistory.isNotEmpty
                            ? employee.employmentHistory.last.designationName
                            : '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subText,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // small chips (nice in both themes)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _chip(
                            context,
                            icon: Icons.badge_outlined,
                            label: employee.employeeNo,
                          ),
                          _chip(
                            context,
                            icon: Icons.email_outlined,
                            label: (employee.employeeEmail.isNotEmpty == true)
                                ? employee.employeeEmail
                                : "-",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ================= TAB BAR =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary2,
                    unselectedLabelColor: cs.onSurface.withOpacity(0.55),
                    labelStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          AppColors.primary2.withOpacity(isDark ? 0.22 : 0.12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(icon: Icon(Icons.person_outline), text: "Personal"),
                      Tab(icon: Icon(Icons.work_outline), text: "Employment"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ================= TAB CONTENT =================
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalTab(employee),
                    _buildEmploymentTab(employee),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ------------------------------------------------------------
  // PERSONAL TAB
  // ------------------------------------------------------------
  Widget _buildPersonalTab(Employee employee) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? Colors.white12 : Colors.black12;

    final details = [
      {
        "icon": Icons.phone,
        "label": "Contact Number",
        "value": employee.employeeContactNo
      },
      {"icon": Icons.email, "label": "Email", "value": employee.employeeEmail},
      {
        "icon": Icons.cake,
        "label": "Date of Birth",
        "value": employee.employeeDob
      },
      {
        "icon": Icons.home,
        "label": "Permanent Address",
        "value": employee.employeePermanentAddress ?? 'N/A'
      },
      {
        "icon": Icons.location_on,
        "label": "Temporary Address",
        "value": employee.employeeTemporaryAddress ?? 'N/A'
      },
      {
        "icon": Icons.flag,
        "label": "Nationality",
        "value": employee.nationality ?? 'N/A'
      },
      {
        "icon": Icons.favorite,
        "label": "Marital Status",
        "value": employee.employeeMaritalStatus ?? 'N/A'
      },
      {
        "icon": Icons.auto_awesome,
        "label": "Religion",
        "value": employee.religion ?? 'N/A'
      },
    ];

    return RefreshIndicator(
      onRefresh: controller.fetchEmployeeDetails,
      color: AppColors.primary2,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: details.length,
        itemBuilder: (_, i) {
          final item = details[i];
          return _infoCard(
            icon: item["icon"] as IconData,
            label: item["label"] as String,
            value: (item["value"] as String),
            cardColor: cs.surface,
            borderColor: border,
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPLOYMENT TAB
  // ------------------------------------------------------------
  Widget _buildEmploymentTab(Employee employee) {
    final history = employee.employmentHistory;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? Colors.white12 : Colors.black12;

    return RefreshIndicator(
      onRefresh: controller.fetchEmployeeDetails,
      color: AppColors.primary2,
      child: history.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    "No employment history available.",
                    style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: history.length,
              itemBuilder: (_, i) => _employmentCard(
                history[i],
                cardColor: cs.surface,
                borderColor: border,
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // CHIP
  // ------------------------------------------------------------
  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary2),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Get.width * 0.55),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO CARD
  // ------------------------------------------------------------
  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color cardColor,
    required Color borderColor,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary2.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary2.withOpacity(0.20)),
          ),
          child: Icon(icon, color: AppColors.primary2),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withOpacity(0.60),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPLOYMENT CARD
  // ------------------------------------------------------------
  Widget _employmentCard(
    EmploymentHistory history, {
    required Color cardColor,
    required Color borderColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            history.designationName,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            history.departmentName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 10),
          _miniRow(
            icon: Icons.work_outline,
            text: "Type: ${history.employmentTypeName}",
          ),
          const SizedBox(height: 6),
          _miniRow(
            icon: Icons.calendar_month_outlined,
            text: "Duration: ${history.startDate} → ${history.endDate}",
          ),
        ],
      ),
    );
  }

  Widget _miniRow({required IconData icon, required String text}) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.55)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.80),
            ),
          ),
        ),
      ],
    );
  }
}

// ignore_for_file: depend_on_referenced_packages, avoid_print, deprecated_member_use

import 'dart:ui';
import 'package:corehris/modules/HRMS/main_screens/leaves/controller_/encash_con.dart';
import 'package:corehris/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveEncashScreen extends StatelessWidget {
  LeaveEncashScreen({super.key});

  final LeaveEncashController controller = Get.put(LeaveEncashController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth >= 720 ? 640.0 : screenWidth;
    final horizontalPadding = screenWidth < 360 ? 14.0 : 16.0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FB),
      bottomNavigationBar: Obx(() {
        final disabled = controller.isLoading.value;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.92)
                : Colors.white.withOpacity(0.92),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE8EDF5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.30 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: disabled ? null : controller.submitEncashRequest,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: cs.primary,
                      disabledBackgroundColor: cs.primary.withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: disabled
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: cs.onPrimary,
                            ),
                          )
                        : Text(
                            "Submit Encash Request",
                            style: TextStyle(
                              fontSize: 15.5,
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [
                          Color(0xFF09111F),
                          Color(0xFF0F172A),
                          Color(0xFF111827),
                        ]
                      : const [
                          Color(0xFFF8FAFF),
                          Color(0xFFF3F6FB),
                          Color(0xFFEEF3FA),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: _blurBubble(
              size: 180,
              color: AppColors.primary2.withOpacity(isDark ? 0.16 : 0.12),
            ),
          ),
          Positioned(
            top: 180,
            left: -30,
            child: _blurBubble(
              size: 120,
              color: AppColors.primary1.withOpacity(isDark ? 0.14 : 0.10),
            ),
          ),
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.encashableLeaves.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: cs.primary),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                physics: const BouncingScrollPhysics(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 18),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: _glassCard(
                            context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "New Encash Request",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Choose an eligible leave category and submit your encash request.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurface.withOpacity(0.68),
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                /// Leave Category
                                _sectionLabel(context, "Leave Category"),
                                const SizedBox(height: 8),
                                _modernDropdown(context),

                                const SizedBox(height: 16),

                                /// Requested Days
                                _sectionLabel(context, "Requested Days"),
                                const SizedBox(height: 8),
                                _modernDaysField(context),

                                const SizedBox(height: 16),

                                /// Remarks
                                _sectionLabel(context, "Remarks"),
                                const SizedBox(height: 8),
                                _modernRemarksField(context),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Encash History",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: controller.encashHistory.isEmpty
                              ? _glassCard(
                                  context,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Center(
                                      child: Text(
                                        "No encash records found",
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: cs.onSurface.withOpacity(0.65),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: controller.encashHistory.length,
                                  itemBuilder: (_, index) {
                                    final item =
                                        controller.encashHistory[index];
                                    return _historyCard(context, item);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF1E3A8A),
                  Color(0xFF1D4ED8),
                  Color(0xFF2563EB),
                ]
              : const [
                  Color(0xFF2563EB),
                  Color(0xFF2F6BFF),
                  Color(0xFF4F46E5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary2.withOpacity(isDark ? 0.24 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Get.back(),
              ),
              const Spacer(),
              Text(
                "Leave Encash",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Convert leave into value",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Submit eligible leave encash requests and track previous submissions in one place.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.90),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7ECF3),
        ),
      ),
      child: Obx(
        () => DropdownButtonFormField<int>(
          value: controller.selectedLeaveCategoryId.value == 0
              ? null
              : controller.selectedLeaveCategoryId.value,
          decoration: InputDecoration(
            hintText: "Select leave category",
            hintStyle: TextStyle(
              color: cs.onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: theme.cardColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurface),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: controller.encashableLeaves.map((leave) {
            return DropdownMenuItem<int>(
              value: leave.leaveCategoryId,
              child: Text(
                "${leave.categoryName} (Available: ${leave.availableDays})",
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            final selected = controller.encashableLeaves
                .firstWhere((e) => e.leaveCategoryId == value);
            controller.selectLeave(selected);
          },
        ),
      ),
    );
  }

  Widget _modernDaysField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      String? helper;
      if (controller.selectedLeaveCategoryId.value != 0) {
        final selected = controller.encashableLeaves.firstWhere(
          (e) => e.leaveCategoryId == controller.selectedLeaveCategoryId.value,
        );
        helper = "Maximum eligible days: ${selected.availableDays}";
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE7ECF3),
              ),
            ),
            child: TextFormField(
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: "Enter requested days",
                hintStyle: TextStyle(
                  color: cs.onSurface.withOpacity(0.45),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (val) {
                final days = int.tryParse(val) ?? 1;
                controller.requestedDays.value = days;
              },
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                helper,
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.60),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _modernRemarksField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7ECF3),
        ),
      ),
      child: TextFormField(
        controller: controller.remarksCtrl,
        maxLines: 3,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Add optional remarks",
          hintStyle: TextStyle(
            color: cs.onSurface.withOpacity(0.45),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _historyCard(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = controller.statusColor(item["status"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.90),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["category_name"] ?? "-",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Days: ${item["requested_days"] ?? 0}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.72),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Amount: LKR ${item["total_amount"] ?? 0}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (item["status"] ?? "-").toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurface.withOpacity(0.85),
      ),
    );
  }

  Widget _glassCard(
    BuildContext context, {
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  static Widget _blurBubble({
    required double size,
    required Color color,
  }) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
